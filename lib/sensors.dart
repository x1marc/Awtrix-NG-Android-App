import 'package:flutter/material.dart';

import 'api.dart';
import 'l10n.dart';

/// Kompakte Sensor-Übersicht der Uhr (Temperatur, Luftfeuchte, Helligkeit,
/// Akku, RAM, Uptime). Liest /stats und /device und zeigt, was vorhanden ist.
class SensorsCard extends StatefulWidget {
  final AwtrixApi api;
  const SensorsCard({super.key, required this.api});

  @override
  State<SensorsCard> createState() => _SensorsCardState();
}

class _SensorsCardState extends State<SensorsCard> {
  Map<String, dynamic> _d = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final merged = <String, dynamic>{};
    try {
      merged.addAll(await widget.api.getDevice());
    } catch (_) {}
    try {
      merged.addAll(await widget.api.getStats());
    } catch (_) {}
    if (mounted) {
      setState(() {
        _d = merged;
        _loading = false;
      });
    }
  }

  // Sucht den ersten vorhandenen Key (case-insensitiv, mehrere Kandidaten).
  num? _num(List<String> keys) {
    for (final k in keys) {
      for (final e in _d.entries) {
        if (e.key.toLowerCase() == k.toLowerCase() && e.value is num) {
          return e.value as num;
        }
      }
    }
    return null;
  }

  Widget _tile(IconData icon, String label, String value, Color c) => Container(
        width: 104,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final temp = _num(['temp', 'temperature']);
    final hum = _num(['hum', 'humidity']);
    final lux = _num(['lux', 'brightness', 'ldr', 'illuminance']);
    final bat = _num(['bat', 'battery', 'batteryPercent', 'batRaw']);
    final ram = _num(['ram', 'freeHeap', 'heap']);

    final tiles = <Widget>[
      if (temp != null)
        _tile(Icons.thermostat, tr('sensor_temp'),
            '${temp.toStringAsFixed(1)}°C', Colors.orange),
      if (hum != null)
        _tile(Icons.water_drop, tr('sensor_hum'), '${hum.round()}%',
            Colors.blue),
      if (lux != null)
        _tile(Icons.light_mode, tr('sensor_lux'), '${lux.round()}',
            Colors.amber),
      if (bat != null && bat <= 100)
        _tile(Icons.battery_full, tr('sensor_bat'), '${bat.round()}%',
            Colors.green),
      if (ram != null)
        _tile(Icons.memory, tr('sensor_ram'), '${(ram / 1024).round()} KB',
            Colors.purple),
    ];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.sensors,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(tr('sensors'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loading ? null : _load,
              ),
            ]),
            const SizedBox(height: 6),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tiles.isEmpty)
              Text(tr('sensors_none'),
                  style: Theme.of(context).textTheme.bodySmall)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: tiles),
              ),
          ],
        ),
      ),
    );
  }
}
