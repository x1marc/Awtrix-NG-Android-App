import 'package:flutter/material.dart';

import 'api.dart';
import 'settings_catalog.dart' show prettifyKey;
import 'widgets.dart';

// Deutsche Namen für die System-Gruppen (Top-Level-Objekte von /system).
const Map<String, String> _groupLabels = {
  'wifi': 'WLAN',
  'network': 'WLAN / Netzwerk',
  'webserver': 'Webserver',
  'auth': 'Webserver-Login',
  'mqtt': 'MQTT',
  'ntp': 'Zeit (NTP)',
  'time': 'Zeit',
  'matrix': 'Panel',
  'panel': 'Panel',
  'display': 'Panel',
  'sensors': 'Helligkeit & Sensoren',
  'sensor': 'Helligkeit & Sensoren',
  'gpio': 'GPIO',
  'pins': 'GPIO',
  'buttons': 'Tasten',
  'audio': 'Audio',
  'scripts': 'Skripte',
  'maintenance': 'Wartung',
  'misc': 'Sonstiges',
};

const List<String> _groupOrder = [
  'wifi', 'network', 'webserver', 'auth', 'mqtt', 'ntp', 'time', 'matrix',
  'panel', 'display', 'sensors', 'sensor', 'gpio', 'pins', 'buttons', 'audio',
  'scripts', 'maintenance', 'misc',
];

const Map<String, String> _fieldLabels = {
  'ssid': 'WLAN-Name',
  'pass': 'WLAN-Passwort',
  'password': 'Passwort',
  'hostname': 'Hostname',
  'staticIp': 'Feste IP verwenden',
  'ip': 'IP-Adresse',
  'gateway': 'Gateway',
  'subnet': 'Subnetzmaske',
  'dns': 'DNS',
  'dns1': 'DNS 1',
  'dns2': 'DNS 2',
  'port': 'Port',
  'user': 'Benutzername',
  'username': 'Benutzername',
  'enabled': 'Aktiv',
  'host': 'Broker-Host',
  'brokerHost': 'Broker-Host',
  'brokerPort': 'Broker-Port',
  'topicPrefix': 'Topic-Präfix',
  'prefix': 'Präfix',
  'haDiscovery': 'Home-Assistant-Discovery',
  'haPrefix': 'HA-Präfix',
  'server': 'Server',
  'ntpServer': 'NTP-Server',
  'timezone': 'Zeitzone',
  'tz': 'Zeitzone',
  'width': 'Breite',
  'height': 'Höhe',
  'panels': 'Anzahl Panels',
  'brightness': 'Helligkeit',
  'minBrightness': 'Min. Helligkeit',
  'maxBrightness': 'Max. Helligkeit',
  'debug': 'Debug-Modus',
};

String _groupLabel(String k) => _groupLabels[k.toLowerCase()] ?? prettifyKey(k);
String _fieldLabel(String k) => _fieldLabels[k] ?? prettifyKey(k);
bool _isPassword(String k) => k.toLowerCase().contains('pass');
bool _isRiskyGroup(String k) {
  final l = k.toLowerCase();
  return l.contains('wifi') || l.contains('gpio') || l.contains('pin') ||
      l.contains('network');
}

InputDecoration _deco({String? hint}) => InputDecoration(
      isDense: true,
      filled: false,
      hintText: hint,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );

class SystemPage extends StatefulWidget {
  final AwtrixDevice device;
  const SystemPage({super.key, required this.device});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  Map<String, dynamic> _system = {};
  Map<String, dynamic> _device = {};
  final Map<String, dynamic> _edited = {}; // "gruppe.feld" oder "feld"
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _gen = 0;

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
      final d = await api.getDevice();
      Map<String, dynamic> s = {};
      try {
        s = await api.getSystem();
      } catch (_) {}
      _device = d;
      _system = s;
      _edited.clear();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Uhr nicht erreichbar (${widget.device.host}).';
        });
      }
    }
  }

  dynamic _raw(String key) {
    if (!key.contains('.')) return _system[key];
    final p = key.split('.');
    final parent = _system[p[0]];
    return parent is Map ? parent[p[1]] : null;
  }

  dynamic _val(String key) => _edited.containsKey(key) ? _edited[key] : _raw(key);
  void _set(String key, dynamic v) => setState(() => _edited[key] = v);

  Future<void> _save() async {
    if (_edited.isEmpty) return;
    final risky = _edited.keys.any((k) => _isRiskyGroup(k.split('.').first));
    if (risky) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('WLAN/GPIO ändern?'),
          content: const Text(
              'Achtung: Falsche WLAN- oder GPIO-Werte können die Uhr '
              'unerreichbar machen (dann hilft nur ein physischer Reset). '
              'Wirklich speichern?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Trotzdem speichern')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _saving = true);
    final patch = <String, dynamic>{};
    _edited.forEach((key, value) {
      // Leeres Passwortfeld = unverändert -> nicht senden.
      final childKey = key.contains('.') ? key.split('.')[1] : key;
      if (_isPassword(childKey) && (value == null || value == '')) return;

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
        final src = _system[pk];
        if (src is Map) parent.addAll(src.cast<String, dynamic>());
        patch[pk] = parent;
      }
      parent[ck] = value;
    });

    try {
      final r = await api.patchSystem(patch);
      if (r.statusCode >= 200 && r.statusCode < 300) {
        snack(context, 'Gespeichert');
        _gen++;
        await _load();
      } else {
        snack(context, 'Uhr lehnte ab (${r.statusCode})');
      }
    } catch (_) {
      snack(context, 'Nicht erreichbar (evtl. WLAN geändert)');
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _fieldRow(String key) {
    final child = key.contains('.') ? key.split('.')[1] : key;
    final v = _val(key);
    if (v is bool) {
      return SwitchListTile(
        title: Text(_fieldLabel(child)),
        value: v,
        onChanged: (nv) => _set(key, nv),
      );
    }
    if (v is num) {
      return ListTile(
        title: Text(_fieldLabel(child)),
        trailing: SizedBox(
          width: 120,
          height: 46,
          child: TextFormField(
            key: ValueKey('$key-$_gen'),
            initialValue: '$v',
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            textAlign: TextAlign.end,
            decoration: _deco(),
            onChanged: (t) {
              final p = v is int ? int.tryParse(t) : num.tryParse(t);
              if (p != null) _set(key, p);
            },
          ),
        ),
      );
    }
    if (v is String || v == null) {
      final pw = _isPassword(child);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fieldLabel(child), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            SizedBox(
              height: 46,
              child: TextFormField(
                key: ValueKey('$key-$_gen'),
                initialValue: pw ? '' : '${v ?? ''}',
                obscureText: pw,
                decoration: _deco(hint: pw ? 'leer = unverändert' : null),
                onChanged: (t) => _set(key, t),
              ),
            ),
          ],
        ),
      );
    }
    // Listen/verschachtelte Objekte: nur anzeigen.
    return ListTile(
      title: Text(_fieldLabel(child)),
      subtitle:
          Text('$v', style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.lock_outline, size: 16),
    );
  }

  List<Widget> _kv(Map<String, dynamic> m) {
    final keys = m.keys.toList()..sort();
    return [
      for (final k in keys)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 150,
                  child: Text(_fieldLabel(k),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Expanded(child: Text('${m[k]}')),
            ],
          ),
        ),
      if (m.isEmpty) const Text('—'),
    ];
  }

  Future<void> _confirmed(
      String title, String action, Future Function() run) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await run();
        snack(context, 'Ausgeführt');
      } catch (_) {
        snack(context, 'Nicht erreichbar');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    // Gruppen aus /system bilden.
    final grouped = <String, List<String>>{};
    final scalars = <String>[];
    for (final k in _system.keys) {
      final v = _system[k];
      if (v is Map) {
        grouped[k] = v.keys.map((c) => '$k.$c').toList();
      } else {
        scalars.add(k);
      }
    }
    final orderedGroups = [
      ..._groupOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_groupOrder.contains(k)),
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 96),
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.warning_amber,
                      color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'System-/Hardware-Konfiguration. Falsche WLAN- oder '
                      'GPIO-Werte können die Uhr unerreichbar machen.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ]),
              ),
            ),
            SectionCard(
              title: 'Gerät & Statistik',
              icon: Icons.info_outline,
              children: _kv(_device),
            ),
            for (final g in orderedGroups)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: ExpansionTile(
                  key: PageStorageKey('sys-$g'),
                  leading: _isRiskyGroup(g)
                      ? const Icon(Icons.warning_amber, color: Colors.orange)
                      : null,
                  title: Text(_groupLabel(g),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: _isRiskyGroup(g)
                      ? const Text('Vorsicht – kann die Uhr trennen')
                      : null,
                  childrenPadding: const EdgeInsets.only(bottom: 6),
                  children: [for (final fk in grouped[g]!) _fieldRow(fk)],
                ),
              ),
            if (scalars.isNotEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: ExpansionTile(
                  key: const PageStorageKey('sys-misc'),
                  title: const Text('Sonstiges',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  childrenPadding: const EdgeInsets.only(bottom: 6),
                  children: [for (final k in scalars..sort()) _fieldRow(k)],
                ),
              ),
            SectionCard(
              title: 'Wartung',
              icon: Icons.build,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmed(
                          'Uhr neu starten?', 'Neu starten', api.reboot),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Neu starten'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error),
                      onPressed: () => _confirmed(
                          'Werksreset? Alle Einstellungen gehen verloren!',
                          'Zurücksetzen',
                          api.factoryReset),
                      icon: const Icon(Icons.settings_backup_restore),
                      label: const Text('Werksreset'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Neu laden'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'saveSystem',
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
