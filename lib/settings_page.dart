import 'package:flutter/material.dart';

import 'api.dart';
import 'color_picker.dart';
import 'settings_catalog.dart';
import 'widgets.dart';

/// Nutzt das globale inputDecorationTheme (umrandet, transparent gefüllt),
/// nur die Einheit ergänzen.
InputDecoration denseDeco({String? suffix}) =>
    InputDecoration(suffixText: suffix);

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
              'Ist die Uhr im WLAN? (${widget.device.host})';
        });
      }
    }
  }

  // Zugriff auf (auch verschachtelte) Werte.
  dynamic _raw(String key) {
    if (!key.contains('.')) return _settings![key];
    final p = key.split('.');
    final parent = _settings![p[0]];
    return parent is Map ? parent[p[1]] : null;
  }

  bool _present(String key) {
    if (!key.contains('.')) return _settings!.containsKey(key);
    final p = key.split('.');
    final parent = _settings![p[0]];
    return parent is Map && parent.containsKey(p[1]);
  }

  dynamic _val(String key) => _edited.containsKey(key) ? _edited[key] : _raw(key);
  void _set(String key, dynamic v) => setState(() => _edited[key] = v);

  Future<void> _save() async {
    if (_edited.isEmpty) return;
    setState(() => _saving = true);
    // Verschachtelte Werte als komplettes Eltern-Objekt schicken (nichts verlieren).
    final patch = <String, dynamic>{};
    _edited.forEach((key, value) {
      if (!key.contains('.')) {
        patch[key] = value;
        return;
      }
      final parts = key.split('.');
      final pk = parts[0];
      final ck = parts[1];
      Map<String, dynamic> parent;
      if (patch[pk] is Map<String, dynamic>) {
        parent = patch[pk] as Map<String, dynamic>;
      } else {
        parent = <String, dynamic>{};
        final src = _settings![pk];
        if (src is Map) parent.addAll(src.cast<String, dynamic>());
        patch[pk] = parent;
      }
      parent[ck] = value;
    });
    try {
      final r = await api.patchSettings(patch);
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

  // ---- Zeilen-Aufbau ----
  Widget _row(String key) {
    final meta = kSettingsByKey[key];
    final v = _val(key);
    if (meta == null) return _generic(key, v);
    switch (meta.kind) {
      case SKind.toggle:
        return SwitchListTile(
          title: Text(meta.label),
          subtitle: meta.help == null ? null : Text(meta.help!),
          value: v == true,
          onChanged: (nv) => _set(key, nv),
        );
      case SKind.slider:
        final cur = (v is num ? v : meta.min).toDouble();
        return ListTile(
          title: Row(children: [
            Expanded(child: Text(meta.label)),
            Text('${cur.round()}${meta.unit ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: cur
                    .clamp(meta.min.toDouble(), meta.max.toDouble())
                    .toDouble(),
                min: meta.min.toDouble(),
                max: meta.max.toDouble(),
                divisions: meta.divisions,
                label: '${cur.round()}',
                onChanged: (nv) => _set(key, nv.round()),
              ),
              if (meta.help != null)
                Text(meta.help!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      case SKind.dropdown:
        final opts = meta.options!;
        final value = opts.containsKey(v) ? v as String : null;
        return ListTile(
          title: Text(meta.label),
          subtitle: meta.help == null ? null : Text(meta.help!),
          trailing: DropdownButton<String>(
            value: value,
            hint: const Text('—'),
            items: [
              for (final e in opts.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (nv) => _set(key, nv),
          ),
        );
      case SKind.number:
        return ListTile(
          title: Text(meta.label),
          subtitle: meta.help == null ? null : Text(meta.help!),
          trailing: SizedBox(
            width: 108,
            height: 46,
            child: TextFormField(
              key: ValueKey('$key-$_gen'),
              initialValue: '${v ?? ''}',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              textAlign: TextAlign.end,
              decoration: denseDeco(suffix: meta.unit),
              onChanged: (t) {
                final isInt = _raw(key) is int;
                final p = isInt ? int.tryParse(t) : num.tryParse(t);
                if (p != null) _set(key, p);
              },
            ),
          ),
        );
      case SKind.color:
        return _colorRow(key, meta, nullable: false);
      case SKind.colorNullable:
        return _colorRow(key, meta, nullable: true);
      case SKind.text:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.label, style: const TextStyle(fontSize: 16)),
              if (meta.help != null) ...[
                const SizedBox(height: 2),
                Text(meta.help!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 46,
                child: TextFormField(
                  key: ValueKey('$key-$_gen'),
                  initialValue: '${v ?? ''}',
                  decoration: denseDeco(),
                  onChanged: (t) => _set(key, t),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _colorRow(String key, SMeta meta, {required bool nullable}) {
    final v = _val(key);
    final isSet = v is String && v.isNotEmpty;
    return ListTile(
      title: Text(meta.label),
      subtitle: meta.help == null ? null : Text(meta.help!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () async {
              final hex = await pickColor(context,
                  initialHex: isSet ? v : '#FFFFFF');
              if (hex != null) _set(key, hex);
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSet ? hexToColor(v) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: isSet
                  ? null
                  : const Icon(Icons.block, size: 18, color: Colors.grey),
            ),
          ),
          if (nullable)
            IconButton(
              tooltip: 'Auf Standard (leer)',
              icon: const Icon(Icons.backspace_outlined, size: 18),
              onPressed: () => _set(key, null),
            ),
        ],
      ),
    );
  }

  Widget _generic(String key, dynamic v) {
    if (v is bool) {
      return SwitchListTile(
        title: Text(prettifyKey(key)),
        subtitle: Text(key, style: Theme.of(context).textTheme.bodySmall),
        value: v,
        onChanged: (nv) => _set(key, nv),
      );
    }
    if (v is num) {
      return ListTile(
        title: Text(prettifyKey(key)),
        trailing: SizedBox(
          width: 108,
          height: 46,
          child: TextFormField(
            key: ValueKey('$key-$_gen'),
            initialValue: v.toString(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            textAlign: TextAlign.end,
            decoration: denseDeco(),
            onChanged: (t) {
              final p = v is int ? int.tryParse(t) : num.tryParse(t);
              if (p != null) _set(key, p);
            },
          ),
        ),
      );
    }
    if (v is String) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prettifyKey(key), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: TextFormField(
                key: ValueKey('$key-$_gen'),
                initialValue: v,
                decoration: denseDeco(),
                onChanged: (t) => _set(key, t),
              ),
            ),
          ],
        ),
      );
    }
    return ListTile(
      title: Text(prettifyKey(key)),
      subtitle: Text('$v', style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.lock_outline, size: 16),
    );
  }

  bool _matches(String key) {
    if (_filter.isEmpty) return true;
    final f = _filter.toLowerCase();
    final label = (kSettingsByKey[key]?.label ?? prettifyKey(key)).toLowerCase();
    return label.contains(f) || key.toLowerCase().contains(f);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    // Bekannte Keys pro Gruppe + "Weitere" für alles Unbekannte.
    final coveredParents = <String>{};
    for (final m in kSettingsCatalog) {
      if (m.key.contains('.')) coveredParents.add(m.key.split('.')[0]);
    }
    final grouped = <String, List<String>>{};
    for (final m in kSettingsCatalog) {
      if (_present(m.key) && _matches(m.key)) {
        grouped.putIfAbsent(m.group, () => []).add(m.key);
      }
    }
    final knownTop = kSettingsByKey.keys
        .where((k) => !k.contains('.'))
        .toSet();
    for (final k in _settings!.keys) {
      if (knownTop.contains(k) || coveredParents.contains(k)) continue;
      if (_matches(k)) grouped.putIfAbsent('Weitere', () => []).add(k);
    }

    final groupsInOrder =
        kGroupOrder.where((g) => grouped.containsKey(g)).toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
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
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                children: [
                  for (var gi = 0; gi < groupsInOrder.length; gi++)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: ExpansionTile(
                        key: PageStorageKey(
                            'grp-${groupsInOrder[gi]}-${_filter.isEmpty}'),
                        initiallyExpanded: gi == 0 || _filter.isNotEmpty,
                        title: Text(groupsInOrder[gi],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        childrenPadding:
                            const EdgeInsets.only(left: 4, right: 4, bottom: 6),
                        children: [
                          for (final k in grouped[groupsInOrder[gi]]!) _row(k),
                        ],
                      ),
                    ),
                  if (groupsInOrder.isEmpty)
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
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
