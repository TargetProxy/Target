import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/runtime/core_gateway.dart';
import '../../../core/runtime/core_notifier.dart';
import '../../../core/runtime/subscription_gateway.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/proxy_group.dart';
import '../../../data/models/proxy_node.dart';
import '../../proxies/application/proxy_catalog.dart';

@immutable
class SubscriptionsState {
  const SubscriptionsState({this.subscriptions = const [], this.lastError});

  final List<Subscription> subscriptions;
  final String? lastError;

  SubscriptionsState copyWith({
    List<Subscription>? subscriptions,
    String? lastError,
    bool clearError = false,
  }) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class SubscriptionsNotifier extends Notifier<SubscriptionsState> {
  CoreGateway? _gateway;
  StreamSubscription<void>? _changes;
  Future<void> _operationTail = Future<void>.value();
  final _subscriptionTasks = <String, Future<void>>{};

  Future<void> get ready => _operationTail;

  @override
  SubscriptionsState build() {
    final gateway = ref.read(coreGatewayProvider);
    _gateway = gateway;
    _changes = gateway.subscriptionChanges.listen((_) {
      unawaited(_loadSubscriptions());
    });
    ref.onDispose(() => unawaited(_changes?.cancel()));
    ref.read(coreProvider.notifier).setStartupBarrier(() => ready);
    return const SubscriptionsState();
  }

  Future<void> load() => _loadSubscriptions();

  Future<void> _loadSubscriptions() {
    _operationTail = _operationTail.then<void>((_) async {
      final gateway = _gateway;
      if (gateway == null) {
        state = state.copyWith(lastError: _unavailableMessage);
        return;
      }
      try {
        final snapshot = await gateway.listSubscriptions();
        final remote = snapshot.subscriptions;
        final previous = {
          for (final item in state.subscriptions) item.id: item,
        };
        final subscriptions = [
          for (final item in remote)
            _subscriptionFromRuntime(item, previous[item.id]),
        ];
        state = state.copyWith(subscriptions: subscriptions, clearError: true);
        final catalog = ref.read(proxyCatalogProvider.notifier);
        // NodePool is assembled by TargetLib from all enabled subscriptions.
        // Use it as the single source of truth for the unified node list.
        final pool = await ref.read(coreGatewayProvider).getNodePool();
        final nodes = [
          for (final node in pool)
            ProxyNode(
              id: node.id,
              name: node.name.isEmpty ? node.id : node.name,
              type: node.type,
              subscriptionId: node.subscriptionId,
              countryCode: node.countryCode,
              server: node.server,
              port: node.port,
              isAvailable: node.isAvailable,
            ),
        ];
        if (nodes.isEmpty) {
          catalog.clear();
        } else {
          catalog.replaceGroups([
            ProxyGroup(
              id: ProxyGroup.runtimeSelectorGroupId,
              name: ProxyGroup.runtimeSelectorGroupId,
              type: 'selector',
              nodes: nodes,
            ),
          ]);
        }
      } on Object catch (error) {
        state = state.copyWith(
          lastError: 'Failed to load TargetLib subscriptions: $error',
        );
      }
    });
    return _operationTail;
  }

  Future<bool> addSubscription(String url, {String? name}) async {
    final gateway = _gateway;
    if (gateway == null) return _failUnavailable();
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      state = state.copyWith(lastError: 'Subscription link is empty.');
      return false;
    }
    // URL normalization (nested links, percent-encoding, decorations) is
    // handled by the TargetLib backend inside AddSubscription.
    final normalizedName = name?.trim();
    final subscription = Subscription(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName == null || normalizedName.isEmpty
          ? 'Subscription ${state.subscriptions.length + 1}'
          : normalizedName,
      url: trimmedUrl,
    );
    state = state.copyWith(clearError: true);
    try {
      final created = await gateway.addSubscription(
        id: subscription.id,
        name: subscription.name,
        url: subscription.url,
        enabled: true,
        autoUpdate: subscription.autoUpdate,
        updateIntervalSeconds: subscription.updateIntervalSeconds,
        headers: {
          ...subscription.headers,
          'User-Agent': subscription.userAgent,
        },
        updateNow: true,
      );
      final added = _subscriptionFromRuntime(created, subscription);
      state = state.copyWith(
        subscriptions: [
          for (final item in state.subscriptions)
            if (item.id != added.id) item,
          added,
        ],
        clearError: true,
      );
      await _loadSubscriptions();
      return true;
    } on Object catch (error) {
      state = state.copyWith(lastError: 'Failed to add subscription: $error');
      return false;
    }
  }

  Future<void> toggleSubscription(String id) => _setEnabled(id, null);

  Future<void> setEnabled(String id, bool enabled) => _setEnabled(id, enabled);

  Future<void> _setEnabled(String id, bool? enabled) =>
      _changeSubscription(id, () async {
        final gateway = _gateway;
        if (gateway == null) {
          _failUnavailable();
          return;
        }
        final current = state.subscriptions
            .where((item) => item.id == id)
            .firstOrNull;
        if (current == null || current.enabled == enabled) return;
        try {
          final updated = await gateway.setSubscriptionEnabled(
            id,
            enabled ?? !current.enabled,
          );
          state = state.copyWith(
            subscriptions: [
              for (final item in state.subscriptions)
                item.id == id ? item.copyWith(enabled: updated.enabled) : item,
            ],
            clearError: true,
          );
          await _loadSubscriptions();
        } on Object catch (error) {
          state = state.copyWith(
            lastError: 'Failed to change subscription: $error',
          );
        }
      });

  Future<void> updateSubscription(String id) =>
      _changeSubscription(id, () async {
        if (!state.subscriptions.any((item) => item.id == id)) return;
        final gateway = _gateway;
        if (gateway == null) {
          _failUnavailable();
          return;
        }
        try {
          final result = await gateway.updateSubscription(id);
          _logConfigComparison(result);
          Subscription? current;
          for (final item in state.subscriptions) {
            if (item.id == id) {
              current = item;
              break;
            }
          }
          final subscription = _subscriptionFromRuntime(
            result.subscription,
            current,
            notModified: result.notModified,
          );
          state = state.copyWith(
            subscriptions: [
              for (final item in state.subscriptions)
                if (item.id == id) subscription else item,
            ],
            clearError: true,
          );
          await _loadSubscriptions();
        } on Object catch (error) {
          state = state.copyWith(
            subscriptions: [
              for (final item in state.subscriptions)
                if (item.id == id)
                  item.copyWith(
                    updateStatus: SubscriptionUpdateStatus.failed,
                    lastError: error.toString(),
                  )
                else
                  item,
            ],
            lastError: 'Failed to update subscription: $error',
          );
        }
      });

  Future<void> _changeSubscription(
    String id,
    Future<void> Function() change,
  ) async {
    // Refresh writes a full subscription, including its enabled flag.
    final previous = _subscriptionTasks[id] ?? Future<void>.value();
    final task = _subscriptionTasks[id] = previous.then((_) => change());
    try {
      await task;
    } finally {
      if (identical(_subscriptionTasks[id], task)) {
        _subscriptionTasks.remove(id);
      }
    }
  }

  void _logConfigComparison(RuntimeSubscriptionUpdate result) {
    if (result.originalConfig.isEmpty) return;
    AppLogger.info(
      '===== ORIGINAL SUBSCRIPTION CONFIG =====\n'
      '${result.originalConfig}\n'
      '===== END ORIGINAL SUBSCRIPTION CONFIG =====',
      source: 'CONFIG',
    );
  }

  Subscription _subscriptionFromRuntime(
    RuntimeSubscription runtime,
    Subscription? previous, {
    bool notModified = false,
  }) {
    final status = notModified
        ? SubscriptionUpdateStatus.noChange
        : switch (runtime.status) {
            RuntimeSubscriptionStatus.updating =>
              SubscriptionUpdateStatus.updating,
            RuntimeSubscriptionStatus.ready => SubscriptionUpdateStatus.updated,
            RuntimeSubscriptionStatus.failed => SubscriptionUpdateStatus.failed,
            RuntimeSubscriptionStatus.idle => SubscriptionUpdateStatus.idle,
          };
    return Subscription(
      id: runtime.id,
      name: runtime.name,
      url: previous?.url ?? _sourceUrl(runtime.source),
      formatHint: previous?.formatHint ?? SubscriptionFormat.auto,
      updateStatus: status,
      autoUpdate: runtime.autoUpdate,
      updateIntervalSeconds: runtime.updateIntervalSeconds,
      headers: previous?.headers ?? const {},
      userAgent: previous?.userAgent ?? SubscriptionRequestDefaults.userAgent,
      lastUpdatedAt: runtime.updatedAt,
      expiresAt: runtime.expiresAt,
      profileTitle: runtime.title,
      webPageUrl: runtime.webPageUrl,
      supportUrl: runtime.supportUrl,
      movedPermanentlyTo: runtime.movedPermanentlyTo,
      lastError: runtime.errorMessage,
      uploadBytes: runtime.uploadBytes,
      downloadBytes: runtime.downloadBytes,
      totalBytes: runtime.totalBytes,
      nodeCount: runtime.nodeCount,
      enabled: runtime.enabled,
    );
  }

  String _sourceUrl(String source) {
    final value = source.trim();
    if (value.isEmpty) return '';
    return value.contains('://') ? value : 'https://$value';
  }

  bool _failUnavailable() {
    state = state.copyWith(lastError: _unavailableMessage);
    return false;
  }

  static const _unavailableMessage =
      'TargetLib subscription service is unavailable.';
}

final subscriptionsProvider =
    NotifierProvider<SubscriptionsNotifier, SubscriptionsState>(
      SubscriptionsNotifier.new,
    );
