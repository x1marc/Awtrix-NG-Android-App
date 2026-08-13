import 'package:flutter/material.dart';

import 'api.dart';
import 'control_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AwtrixDevice> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _devices = await DeviceStore.load();
    if (mounted) setState(() {});
  }

  Future<void> _persist() => DeviceStore.save(_devices);

  Future<void> _discover() async {
    setState(() => _scanning = true);
    final found = await discoverAwtrix();
    var added = 0;
    for (final d in found) {
      if (!_devices.any((x) => x.host == d.host)) {
        _devices.add(d);
        added++;
      }
    }
    await _persist();
    if (!mounted) return;
    setState(() => _scanning = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(found.isEmpty
          ? 'Keine Uhr gefunden – per IP hinzufügen (+)'
          : '${found.length} Uhr(en) gefunden, $added neu'),
    ));
  }

  Future<void> _addByIp() async {
    final ipC = TextEditingController();
    final nameC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Uhr per IP hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipC,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'IP oder Hostname',
                hintText: '192.168.1.50  oder  awtrixng-a1b2c3.local',
              ),
            ),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hinzufügen')),
        ],
      ),
    );
    if (ok == true && ipC.text.trim().isNotEmpty) {
      _devices.add(AwtrixDevice(host: ipC.text.trim(), name: nameC.text.trim()));
      await _persist();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AWTRIX NG Remote'),
        actions: [
          IconButton(
            tooltip: 'Per IP hinzufügen',
            onPressed: _addByIp,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _devices.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.watch, size: 64),
                    SizedBox(height: 12),
                    Text('Noch keine Uhr hinzugefügt.',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 6),
                    Text('Tippe unten auf „Uhr suchen" (gleiches WLAN) '
                        'oder oben auf + für eine IP.',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (_, i) {
                final d = _devices[i];
                return ListTile(
                  leading: const Icon(Icons.watch, size: 32),
                  title: Text(d.name),
                  subtitle: Text('${d.host}${d.port == 80 ? '' : ':${d.port}'}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ControlPage(device: d)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      _devices.removeAt(i);
                      await _persist();
                      setState(() {});
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _discover,
        icon: _scanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.wifi_find),
        label: Text(_scanning ? 'Suche…' : 'Uhr suchen'),
      ),
    );
  }
}
