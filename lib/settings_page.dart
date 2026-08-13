import 'package:flutter/material.dart';

import 'api.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  final AwtrixDevice device;
  const SettingsPage({super.key, required this.device});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  Map<String, dynamic>? _settings;
  final Map<String, dynamic> _edited = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _gen = 0;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await api.getSettings();
      if (s.isEmpty) throw Exception('leer');
      _settings = s;
      _edited.clear();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Einstellungen nicht erreichbar.\n'
              'Uhr im WLAN erreichbar? (${widget.device.host})';
        });
      }
    }
  }

  dynamic _val(String k) => _edited.containsKey(k) ? _edited[k] : _settings![k];

  Future<void> _save() async {
    if (_edited.isEmpty) return;
    setState(() => _saving = true);
    try {
      final r = await api.patchSettings(Map<String, dynamic>.of(_edited));
      if (r.statusCode >= 200 && r.statusCode < 300) {
        snack(context, 'Gespeichert');
        _gen++;
        await _load();
      } else {
        snack(context, 'Uhr lehnte ab (${r.statusCode})');
      }
    } catch (_) {
      snack(context, 'Nicht erreichbar');
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _row(String k) {
    final v = _val(k);
    if (v is bool) {
      return SwitchListTile(
        title: Text(k),
        value: v,
        onChanged: (nv) => setState(() => _edited[k] = nv),
      );
    }
    if (v is num) {
      return ListTile(
        title: Text(k),
        trailing: SizedBox(
          width: 120,
          child: TextFormField(
            key: ValueKey('$k-$_gen'),
            initialValue: v.toString(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            textAlign: TextAlign.end,
            decoration: const InputDecoration(isDense: true),
            onChanged: (t) {
              final p = v is int ? int.tryParse(t) : double.tryParse(t);
              if (p != null) setState(() => _edited[k] = p);
            },
          ),
        ),
      );
    }
    if (v is String) {
      return ListTile(
        title: Text(k),
        subtitle: TextFormField(
          key: ValueKey('$k-$_gen'),
          initialValue: v,
          decoration: const InputDecoration(isDense: true),
          onChanged: (t) => setState(() => _edited[k] = t),
        ),
      );
    }
    // Listen/Objekte: nur anzeigen (nicht editierbar, um nichts zu zerstören).
    return ListTile(
      title: Text(k),
      subtitle: Text('$v',
          style: TextStyle(color: Theme.of(context).disabledColor)),
      trailing: const Icon(Icons.lock_outline, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    final keys = _settings!.keys
        .where((k) => k.toLowerCase().contains(_filter.toLowerCase()))
        .toList()
      ..sort();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Einstellung suchen…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (t) => setState(() => _filter = t),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  for (final k in keys) _row(k),
                  if (keys.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Nichts gefunden.')),
                    ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'saveSettings',
            onPressed: (_edited.isEmpty || _saving) ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(_edited.isEmpty
                ? 'Keine Änderung'
                : 'Speichern (${_edited.length})'),
          ),
        ),
      ],
    );
  }
}
