import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../core/ui/app_glyphs.dart';
import '../../../../core/ui/scaffold/scaffold.dart' as ui;
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ui.Scaffold(
      title: l10n.addSubscriptionTitle,
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.add,
        tooltip: l10n.add,
        onPressed: _submit,
      ),
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.paste,
          tooltip: l10n.paste,
          onPressed: _pasteFromClipboard,
        ),
      ],
      body: Builder(
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24, context.contentTopPadding + 16, 24, context.bottomInset + 24,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.nameOptional, style: AppTextStyle.footnote.of(context).toLighter),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                Text(l10n.subscriptionUrl, style: AppTextStyle.footnote.of(context).toLighter),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(hintText: 'https://example.com/sub'),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.urlRequired : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _urlController.text = text;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // The backend normalizes raw input (nested links, encoding, decorations);
    // the client only validates non-empty input.
    Navigator.of(context).pop({
      'url': _urlController.text.trim(),
      if (_nameController.text.trim().isNotEmpty)
        'name': _nameController.text.trim(),
    });
  }
}
