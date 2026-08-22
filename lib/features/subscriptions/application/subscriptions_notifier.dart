import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../core/runtime/subscription_gateway.dart';
import '../../../data/models/subscription.dart';
import '../../proxies/application/proxy_catalog.dart';

@immutable
class SubscriptionsState {
  const SubscriptionsState({
    this.subscriptions = const [],
    this.busy = false,
    this.lastError,
  });

  final List<Subscription> subscriptions;
  final bool busy;
  final String? lastError;

  Subscription? get activeSubscription {
    for (final subscription in subscriptions) {
      if (subscription.enabled) return subscription;
    }
    return null;
  }

  SubscriptionsState copyWith({
    List<Subscription>? subscriptions,
    bool? busy,
    String? lastError,
    bool clearError = false,
  }) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      busy: busy ?? this.busy,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class SubscriptionsNotifier extends Notifier<SubscriptionsState> {
  SubscriptionGateway? _gateway;
  StreamSubscription<void>? _changes;
  Future<void> _operationTail = Future<void>.value();

  Future<void> get ready => _operationTail;

  @override
  SubscriptionsState build() {
    final coreGateway = ref.read(coreGatewayProvider);
    if (coreGateway is SubscriptionGateway) {
      final gateway = coreGateway as SubscriptionGateway;
      _gateway = gateway;
      _changes = gateway.subscriptionChanges.listen((_) {
        unawaited(_loadSubscriptions());
      });
      ref.onDispose(() => unawaited(_changes?.cancel()));
    }
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
        final remote = await gateway.listSubscriptions();
        final previous = {
          for (final item in state.subscriptions) item.id: item,
        };
        final subscriptions = [
          for (final item in remote)
            _subscriptionFromRuntime(item, previous[item.id]),
        ];
        state = state.copyWith(
          subscriptions: subscriptions,
          busy: subscriptions.any(
            (item) => item.updateStatus == SubscriptionUpdateStatus.updating,
          ),
          clearError: true,
        );
        await _restoreActive(remote);
      } on Object catch (error) {
        state = state.copyWith(
          busy: false,
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
      );
      state = state.copyWith(
        subscriptions: [
          ...state.subscriptions,
          _subscriptionFromRuntime(created, subscription),
        ],
        clearError: true,
      );
      await setActive(created.id);
      await updateSubscription(created.id);
      return true;
    } on Object catch (error) {
      state = state.copyWith(lastError: 'Failed to add subscription: $error');
      return false;
    }
  }

  Future<void> removeSubscription(String id) async {
    final gateway = _gateway;
    if (gateway == null) {
      _failUnavailable();
      return;
    }
    try {
      await gateway.removeSubscription(id);
      state = state.copyWith(
        subscriptions: [
          for (final item in state.subscriptions)
            if (item.id != id) item,
        ],
        clearError: true,
      );
      await _restoreActive(const []);
    } on Object catch (error) {
      state = state.copyWith(
        lastError: 'Failed to remove subscription: $error',
      );
    }
  }

  Future<void> renameSubscription(String id, String newName) async {
    final index = state.subscriptions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final gateway = _gateway;
    if (gateway == null) {
      _failUnavailable();
      return;
    }
    try {
      final renamed = await gateway.renameSubscription(id, newName);
      state = state.copyWith(
        subscriptions: [
          for (var i = 0; i < state.subscriptions.length; i++)
            i == index
                ? _subscriptionFromRuntime(renamed, state.subscriptions[index])
                : state.subscriptions[i],
        ],
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        lastError: 'Failed to rename subscription: $error',
      );
    }
  }

  Future<void> setActive(String id) async {
    final gateway = _gateway;
    if (gateway == null) {
      _failUnavailable();
      return;
    }
    try {
      final updated = <Subscription>[];
      final views = <RuntimeSubscription>[];
      for (final item in state.subscriptions) {
        final view = await gateway.setSubscriptionEnabled(
          item.id,
          item.id == id,
        );
        views.add(view);
        updated.add(_subscriptionFromRuntime(view, item));
      }
      state = state.copyWith(subscriptions: updated, clearError: true);
      await gateway.activateSubscription(id);
      await _restoreActive(views);
    } on Object catch (error) {
      state = state.copyWith(
        lastError: 'Failed to activate subscription: $error',
      );
    }
  }

  Future<void> updateSubscription(String id) async {
    final index = state.subscriptions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final gateway = _gateway;
    if (gateway == null) {
      _failUnavailable();
      return;
    }
    state = state.copyWith(
      busy: true,
      subscriptions: [
        for (var i = 0; i < state.subscriptions.length; i++)
          i == index
              ? state.subscriptions[i].copyWith(
                  updateStatus: SubscriptionUpdateStatus.updating,
                  lastError: '',
                )
              : state.subscriptions[i],
      ],
    );
    try {
      final result = await gateway.updateSubscription(id);
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
        busy: false,
        clearError: true,
      );
      if (subscription.enabled) {
        ref
            .read(proxyCatalogProvider.notifier)
            .replaceNodes(result.subscription.nodes);
        await gateway.activateSubscription(id);
      }
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
        busy: false,
        lastError: 'Failed to update subscription: $error',
      );
    }
  }

  Future<bool> importFromClipboard(String text) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    return addSubscription(value);
  }

  String exportSubscriptions() {
    final data = state.subscriptions.map((item) => item.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importFromJson(String json) async {
    try {
      final list = jsonDecode(json) as List;
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        final url = map['url'] as String?;
        if (url != null) {
          await addSubscription(url, name: map['name'] as String?);
        }
      }
    } on Object catch (error) {
      state = state.copyWith(
        lastError: 'Failed to import subscriptions: $error',
      );
    }
  }

  Future<void> _restoreActive(List<RuntimeSubscription> subscriptions) async {
    final gateway = _gateway;
    if (gateway == null) return;
    var views = subscriptions;
    if (views.isEmpty && state.subscriptions.isNotEmpty) {
      views = await gateway.listSubscriptions();
    }
    // The active subscription is persisted by the backend; read it back.
    RuntimeSubscription? active;
    final activeId = await gateway.activeSubscriptionId();
    if (activeId != null) {
      for (final item in views) {
        if (item.id == activeId) {
          active = item;
          break;
        }
      }
    }
    if (active == null) {
      // No persisted active subscription yet: fall back to the first enabled
      // one and persist that choice in the backend.
      for (final item in views) {
        if (item.enabled) {
          active = item;
          break;
        }
      }
      if (active != null) await gateway.activateSubscription(active.id);
    }
    final catalog = ref.read(proxyCatalogProvider.notifier);
    if (active == null) {
      catalog.clear();
      return;
    }
    catalog.replaceNodes(active.nodes);
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
      formatHint: SubscriptionFormat.singBoxJson,
      updateStatus: status,
      autoUpdate: runtime.autoUpdate,
      updateIntervalSeconds: runtime.updateIntervalSeconds,
      headers: previous?.headers ?? const {},
      userAgent: previous?.userAgent ?? SubscriptionRequestDefaults.userAgent,
      lastUpdatedAt: runtime.updatedAt,
      expiresAt: runtime.expiresAt,
      activeProfileId: runtime.status == RuntimeSubscriptionStatus.ready
          ? runtime.id
          : previous?.activeProfileId,
      profileTitle: runtime.title,
      webPageUrl: runtime.webPageUrl,
      supportUrl: runtime.supportUrl,
      movedPermanentlyTo: runtime.movedPermanentlyTo,
      lastError: runtime.errorMessage,
      uploadBytes: runtime.uploadBytes,
      downloadBytes: runtime.downloadBytes,
      totalBytes: runtime.totalBytes,
      nodeCount: runtime.nodes.length,
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
