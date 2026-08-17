import 'package:flutter/material.dart';

import 'api.dart';
import 'backup.dart';
import 'l10n.dart';
import 'settings_catalog.dart' show prettifyKey;
import 'widgets.dart';

/// Übersetzter Anzeigename einer System-Gruppe.
String _gName(String g) {
  const m = {
    'WLAN / Netzwerk': 'grp_wlan',
    'Webserver': 'grp_web',
    'MQTT': 'grp_mqtt',
    'Zeit': 'grp_time',
    'Panel': 'grp_panel',
    'Helligkeit & Sensoren': 'grp_brightness',
    'GPIO': 'grp_gpio',
    'Tasten': 'grp_buttons',
    'Audio': 'grp_audio',
    'Skripte': 'grp_scripts',
    'Sonstiges': 'grp_other',
  };
  final k = m[g];
  return k == null ? g : tr(k);
}

// Ordnet einen (flachen) System-Schlüssel einer deutschen Gruppe zu.
const List<String> _germanGroupOrder = [
  'WLAN / Netzwerk',
  'Webserver',
  'MQTT',
  'Zeit',
  'Panel',
  'Helligkeit & Sensoren',
  'GPIO',
  'Tasten',
  'Audio',
  'Skripte',
  'Sonstiges',
];

String _groupOf(String key) {
  final k = key.toLowerCase();
  if (k.startsWith('wifi') ||
      k.startsWith('ssid') ||
      k == 'hostname' ||
      k.startsWith('net') ||
      k.startsWith('dns') ||
      k == 'gateway' ||
      k == 'ip' ||
      k == 'subnet' ||
      k.startsWith('static')) {
    return 'WLAN / Netzwerk';
  }
  if (k.startsWith('auth') || k.startsWith('web') || k == 'port') {
    return 'Webserver';
  }
  if (k.startsWith('mqtt') || k.startsWith('ha')) return 'MQTT';
  if (k.startsWith('ntp') ||
      k.startsWith('tz') ||
      k.contains('timezone') ||
      k.startsWith('time')) {
    return 'Zeit';
  }
  if (k.startsWith('panel') ||
      k.startsWith('matrix') ||
      k.startsWith('led') ||
      k.contains('rotate') ||
      k.contains('mirror') ||
      k.contains('flip')) {
    return 'Panel';
  }
  if (k.contains('brightness') ||
      k.startsWith('ldr') ||
      k.startsWith('battery') ||
      k.contains('temp') ||
      k.contains('humid') ||
      k.startsWith('lux') ||
      k.contains('sensor')) {
    return 'Helligkeit & Sensoren';
  }
  if (k.startsWith('gpio') ||
      k.contains('pin') ||
      k.contains('sda') ||
      k.contains('scl')) {
    return 'GPIO';
  }
  if (k.startsWith('button') || k.startsWith('key')) return 'Tasten';
  if (k.startsWith('df') ||
      k.startsWith('audio') ||
      k.startsWith('buzzer') ||
      k.startsWith('speaker') ||
      k.startsWith('sound')) {
    return 'Audio';
  }
  if (k.startsWith('script')) return 'Skripte';
  return 'Sonstiges';
}

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
  'authUser': 'Webserver-Benutzer',
  'authPass': 'Webserver-Passwort',
  'batteryDividerRatio': 'Batterie-Teiler',
  'brightnessSmoothing': 'Helligkeits-Glättung',
  'buttonCallback': 'Tasten-Callback (URL)',
  'dfplayer': 'DFPlayer',
  'mqttHost': 'Broker-Host',
  'mqttPort': 'Broker-Port',
  'mqttPrefix': 'Topic-Präfix',
  'mqttUser': 'Broker-Benutzer',
  'mqttPass': 'Broker-Passwort',
  'netStatic': 'Feste IP verwenden',
  'panelChainReverse': 'Kette umdrehen',
  'panelChainSerpentine': 'Kette Serpentine',
  'panelSerpentine': 'Serpentine',
  'panelStart': 'Erste LED',
  'panelWidth': 'Panel-Breite',
  'wifiSsid': 'WLAN-Name',
  'wifiPass': 'WLAN-Passwort',
  'statsInterval': 'Stats-Intervall',
  'ldrFactor': 'LDR-Faktor',
  'ldrGamma': 'LDR-Gamma',
  'ldrGpio': 'LDR an GPIO',
  'temperatureOffset': 'Temperatur-Offset',
  'humidityOffset': 'Luftfeuchte-Offset',
  'scriptsEnabled': 'Skripte aktiv',
};

const Map<String, String> _fieldLabelsEn = {
  'ssid': 'Wi-Fi name',
  'pass': 'Wi-Fi password',
  'password': 'Password',
  'hostname': 'Hostname',
  'staticIp': 'Use static IP',
  'ip': 'IP address',
  'gateway': 'Gateway',
  'subnet': 'Subnet mask',
  'dns': 'DNS',
  'dns1': 'DNS 1',
  'dns2': 'DNS 2',
  'port': 'Port',
  'user': 'Username',
  'username': 'Username',
  'enabled': 'Enabled',
  'host': 'Broker host',
  'brokerHost': 'Broker host',
  'brokerPort': 'Broker port',
  'topicPrefix': 'Topic prefix',
  'prefix': 'Prefix',
  'haDiscovery': 'Home Assistant discovery',
  'haPrefix': 'HA prefix',
  'server': 'Server',
  'ntpServer': 'NTP server',
  'timezone': 'Time zone',
  'tz': 'Time zone',
  'width': 'Width',
  'height': 'Height',
  'panels': 'Number of panels',
  'brightness': 'Brightness',
  'minBrightness': 'Min. brightness',
  'maxBrightness': 'Max. brightness',
  'debug': 'Debug mode',
  'authUser': 'Web server user',
  'authPass': 'Web server password',
  'batteryDividerRatio': 'Battery divider',
  'brightnessSmoothing': 'Brightness smoothing',
  'buttonCallback': 'Button callback (URL)',
  'dfplayer': 'DFPlayer',
  'mqttHost': 'Broker host',
  'mqttPort': 'Broker port',
  'mqttPrefix': 'Topic prefix',
  'mqttUser': 'Broker user',
  'mqttPass': 'Broker password',
  'netStatic': 'Use static IP',
  'panelChainReverse': 'Reverse chain',
  'panelChainSerpentine': 'Chain serpentine',
  'panelSerpentine': 'Serpentine',
  'panelStart': 'First LED',
  'panelWidth': 'Panel width',
  'wifiSsid': 'Wi-Fi name',
  'wifiPass': 'Wi-Fi password',
  'statsInterval': 'Stats interval',
  'ldrFactor': 'LDR factor',
  'ldrGamma': 'LDR gamma',
  'ldrGpio': 'LDR on GPIO',
  'temperatureOffset': 'Temperature offset',
  'humidityOffset': 'Humidity offset',
  'scriptsEnabled': 'Scripts enabled',
};

String _fieldLabel(String k) =>
    (effLang() == 'en' ? _fieldLabelsEn[k] : _fieldLabels[k]) ??
    _fieldLabels[k] ??
    prettifyKey(k);
bool _isPassword(String k) {
  final lk = k.toLowerCase();
  return lk.contains('pass') ||
      lk.contains('psk') ||
      lk.contains('secret') ||
      lk.contains('token');
}
bool _isRiskyGroup(String germanGroup) =>
    germanGroup == 'WLAN / Netzwerk' || germanGroup == 'GPIO';

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
          _error = trp('sys_unreachable', {'host': widget.device.host});
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
          title: Text(tr('wlan_gpio_q')),
          content: Text(tr('wlan_gpio_warn')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr('save_anyway'))),
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
        snack(context, tr('saved'));
        _gen++;
        await _load();
      } else {
        snack(context, trp('rejected', {'code': '${r.statusCode}'}));
      }
    } catch (_) {
      snack(context, tr('sys_rejected_wlan'));
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
          width: 140,
          child: PlainField(
            fieldKey: ValueKey('$key-$_gen'),
            initialValue: '$v',
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            textAlign: TextAlign.end,
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
            PlainField(
              fieldKey: ValueKey('$key-$_gen'),
              initialValue: pw ? '' : '${v ?? ''}',
              obscureText: pw,
              hint: pw ? tr('empty_unchanged') : null,
              onChanged: (t) => _set(key, t),
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
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action)),
        ],
      ),
    );
    if (ok == true) {
      try {
        await run();
        snack(context, tr('executed'));
      } catch (_) {
        snack(context, tr('notReachableShort'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    // Flache /system nach Präfix in deutsche Gruppen einsortieren.
    final grouped = <String, List<String>>{};
    for (final k in _system.keys) {
      final v = _system[k];
      if (v is Map) {
        for (final c in v.keys) {
          grouped.putIfAbsent(_groupOf(k), () => []).add('$k.$c');
        }
      } else {
        grouped.putIfAbsent(_groupOf(k), () => []).add(k);
      }
    }
    for (final list in grouped.values) {
      list.sort((a, b) => _fieldLabel(a.contains('.') ? a.split('.')[1] : a)
          .toLowerCase()
          .compareTo(
              _fieldLabel(b.contains('.') ? b.split('.')[1] : b).toLowerCase()));
    }
    final orderedGroups = [
      ..._germanGroupOrder.where(grouped.containsKey),
      ...grouped.keys.where((g) => !_germanGroupOrder.contains(g)),
    ];

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      tr('sys_warning'),
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ]),
              ),
            ),
            // Editierbare Gruppen ZUERST ...
            for (var gi = 0; gi < orderedGroups.length; gi++)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: CollapsibleSection(
                  initiallyExpanded: gi == 0,
                  leading: _isRiskyGroup(orderedGroups[gi])
                      ? const Icon(Icons.warning_amber, color: Colors.orange)
                      : null,
                  title: Text(_gName(orderedGroups[gi]),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: _isRiskyGroup(orderedGroups[gi])
                      ? Text(tr('sys_caution'),
                          style: const TextStyle(fontSize: 12))
                      : null,
                  children: [
                    for (final fk in grouped[orderedGroups[gi]]!) _fieldRow(fk),
                  ],
                ),
              ),
            // ... dann Info & Wartung.
            SectionCard(
              title: tr('device_stats'),
              icon: Icons.info_outline,
              children: _kv(_device),
            ),
            SectionCard(
              title: tr('maintenance'),
              icon: Icons.build,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmed(
                          tr('reboot_q'), tr('reboot'), api.reboot),
                      icon: const Icon(Icons.restart_alt),
                      label: Text(tr('reboot')),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error),
                      onPressed: () => _confirmed(tr('factory_reset_q'),
                          tr('do_reset'), api.factoryReset),
                      icon: const Icon(Icons.settings_backup_restore),
                      label: Text(tr('factory_reset')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(tr('reload')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => backupExport(context, api),
                      icon: const Icon(Icons.save_alt),
                      label: Text(tr('backup')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => backupImport(context, api, _load),
                      icon: const Icon(Icons.restore),
                      label: Text(tr('restore')),
                    ),
                  ],
                ),
              ],
            ),
          ],
          ),
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
