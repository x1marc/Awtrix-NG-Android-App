import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'l10n.dart';
import 'widgets.dart';

/// Exportiert Einstellungen + System als JSON (Zwischenablage).
Future<void> backupExport(BuildContext context, AwtrixApi api) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(children: [
        const CircularProgressIndicator(),
        const SizedBox(width: 16),
        Expanded(child: Text(tr('loading_config'))),
      ]),
    ),
  );
  Map<String, dynamic> settings = {}, system = {};
  try {
    settings = await api.getSettings();
  } catch (_) {}
  try {
    system = await api.getSystem();
  } catch (_) {}
  if (context.mounted) Navigator.pop(context);

  final txt = const JsonEncoder.withIndent('  ')
      .convert({'app': 'awtrix-ng-remote', 'settings': settings, 'system': system});
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(tr('backup_export')),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('backup_export_hint'),
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              height: 260,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(txt,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('close'))),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: txt));
            if (context.mounted) {
              Navigator.pop(context);
              snack(context, tr('copied'));
            }
          },
          icon: const Icon(Icons.copy),
          label: Text(tr('copy')),
        ),
      ],
    ),
  );
}

/// Importiert Einstellungen + System aus eingefügtem JSON.
Future<void> backupImport(
    BuildContext context, AwtrixApi api, VoidCallback onDone) async {
  final c = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(tr('backup_restore')),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('paste_json'), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: c,
              maxLines: 10,
              decoration: const InputDecoration(
                filled: false,
                border: OutlineInputBorder(),
                hintText: '{ "settings": …, "system": … }',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('continue_'))),
      ],
    ),
  );
  if (ok != true) return;

  Map<String, dynamic>? data;
  try {
    final d = jsonDecode(c.text);
    if (d is Map) data = d.cast<String, dynamic>();
  } catch (_) {}
  if (data == null) {
    if (context.mounted) snack(context, tr('invalid_json'));
    return;
  }

  if (!context.mounted) return;
  final go = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(tr('overwrite_q')),
      content: Text(tr('overwrite_warn')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel'))),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('restore'))),
      ],
    ),
  );
  if (go != true) return;

  try {
    if (data['settings'] is Map) {
      await api.patchSettings((data['settings'] as Map).cast<String, dynamic>());
    }
    if (data['system'] is Map) {
      await api.patchSystem((data['system'] as Map).cast<String, dynamic>());
    }
    if (context.mounted) {
      snack(context, tr('restored'));
      onDone();
    }
  } catch (_) {
    if (context.mounted) snack(context, tr('restore_error'));
  }
}
