import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Subscription',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.itemGap),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.itemGap),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription URL',
                    hintText: 'https://example.com/sub',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'URL is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.paste),
                        label: const Text('Paste'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.itemGap),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Add'),
                        ),
                      ),
                    ),
                  ],
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
