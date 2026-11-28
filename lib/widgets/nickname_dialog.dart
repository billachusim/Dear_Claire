import 'package:flutter/material.dart';

import '../utils/strings.dart';

/// Asks a new Google/Apple user to type a nickname. Dear Claire is
/// anonymous, so we never take the name from their Google/Apple account.
/// Returns the trimmed nickname, or null if they cancel.
Future<String?> askForNickname(BuildContext context, {String? avatarUrl}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Choose your Ego name'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.transparent,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
              ),
            const Text(
              'Dear Claire is anonymous. Pick a nickname others will see. '
              'Here is your Claire avatar. You can change your name and avatar '
              'anytime in your profile.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: AppString.egoName_hint_text,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please choose a name for your Ego'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(controller.text.trim());
            }
          },
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}
