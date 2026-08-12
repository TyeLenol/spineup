import 'package:flutter/material.dart';

import '../models/care_subject.dart';
import '../services/portable_archive_service.dart';

Future<String?> showArchivePassphraseDialog(
  BuildContext context, {
  required bool confirm,
}) {
  final passphraseController = TextEditingController();
  final confirmationController = TextEditingController();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(confirm ? 'Protect your export' : 'Unlock your archive'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                confirm
                    ? 'Choose a passphrase with at least 12 characters. You will need it to import this archive on another device. SpineUp cannot recover a forgotten passphrase.'
                    : 'Enter the passphrase used when this archive was created. SpineUp will not import anything until the archive is authenticated.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passphraseController,
                autofocus: true,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Passphrase',
                  border: OutlineInputBorder(),
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmationController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Repeat passphrase',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final passphrase = passphraseController.text;
              if (passphrase.trim().length < 12) {
                _showDialogError(dialogContext, 'Use at least 12 characters.');
                return;
              }
              if (confirm && passphrase != confirmationController.text) {
                _showDialogError(
                  dialogContext,
                  'The passphrases do not match.',
                );
                return;
              }
              Navigator.of(dialogContext).pop(passphrase);
            },
            child: Text(confirm ? 'Protect export' : 'Unlock'),
          ),
        ],
      );
    },
  );
}

Future<ArchiveImportMode?> showArchiveImportPreviewDialog(
  BuildContext context,
  ArchivePreview preview,
) {
  final canReplace = preview.subjects.length == 1;

  return showDialog<ArchiveImportMode>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Review before importing'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Created ${_formatDate(preview.exportedAt)} · schema ${preview.schemaVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  '${preview.subjects.length} profile(s), ${preview.eventCount} events, ${preview.appointmentCount} appointments',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...preview.subjects.map(
                  (subject) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      subject.type == CareSubjectType.self
                          ? Icons.person_outline_rounded
                          : Icons.family_restroom_rounded,
                    ),
                    title: Text(subject.displayName),
                    subtitle: Text(
                      '${subject.typeLabel} · ${subject.eventCount} events · ${subject.appointmentCount} appointments',
                    ),
                  ),
                ),
                if (preview.omittedAttachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Not included in this archive',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview.omittedAttachments.join(', '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Nothing will be merged silently. Import as separate profiles to preserve the existing local data, or replace the selected profile only after explicit confirmation.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (canReplace)
            OutlinedButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(ArchiveImportMode.replaceSelectedSubject),
              child: const Text('Replace selected profile'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(ArchiveImportMode.separateSubjects),
            child: const Text('Import as separate profiles'),
          ),
        ],
      );
    },
  );
}

void _showDialogError(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
