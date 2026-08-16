import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'widgets.dart';

/// Exportiert Einstellungen + System als JSON (Zwischenablage).
Future<void> backupExport(BuildContext context, AwtrixApi api) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Expanded(child: Text('Lade Konfiguration…')),
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
      title: const Text('Backup exportieren'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enthält alle Einstellungen + System (inkl. Passwörter). '
                'Kopieren und sicher aufbewahren.',
                style: TextStyle(fontSize: 12)),
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
            child: const Text('Schließen')),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: txt));
            if (context.mounted) {
              Navigator.pop(context);
              snack(context, 'In Zwischenablage kopiert');
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Kopieren'),
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
      title: const Text('Backup wiederherstellen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup-JSON hier einfügen:',
                style: TextStyle(fontSize: 12)),
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
            child: const Text('Abbrechen')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Weiter')),
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
    if (context.mounted) snack(context, 'Ungültiges JSON-Format');
    return;
  }

  if (!context.mounted) return;
  final go = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Wirklich überschreiben?'),
      content: const Text(
          'Achtung: Auch WLAN-/Netzwerkwerte werden übernommen – die Uhr '
          'kann sich kurz trennen. Fortfahren?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wiederherstellen')),
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
      snack(context, 'Wiederhergestellt');
      onDone();
    }
  } catch (_) {
    if (context.mounted) snack(context, 'Fehler beim Wiederherstellen');
  }
}
