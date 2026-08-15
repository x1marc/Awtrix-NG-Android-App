import 'package:flutter/material.dart';

import 'api.dart';
import 'device_shell.dart';
import 'main.dart' show ThemeToggleButton;
import 'support.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) maybeShowSupportSheet(context);
      });
    });
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
          : added > 0
              ? '${found.length} gefunden, $added neu hinzugefügt'
              : '${found.length} gefunden (schon in der Liste)'),
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
                hintText: '192.168.1.111',
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awtrix NG App'),
        actions: const [BmcButton(), ThemeToggleButton()],
      ),
      body: _devices.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.watch, size: 72, color: cs.primary),
                    const SizedBox(height: 12),
                    const Text('Noch keine Uhr hinzugefügt.',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 6),
                    const Text(
                      'Tippe unten auf „Uhr suchen" (gleiches WLAN) '
                      'oder oben auf + für eine IP.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (var i = 0; i < _devices.length; i++)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.watch, color: cs.onPrimaryContainer),
                      ),
                      title: Text(_devices[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${_devices[i].host}${_devices[i].port == 80 ? '' : ':${_devices[i].port}'}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                DeviceShell(device: _devices[i])),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          _devices.removeAt(i);
                          await _persist();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                const BmcCard(),
              ],
            ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ip',
            onPressed: _addByIp,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: _scanning ? null : _discover,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_find),
            label: Text(_scanning ? 'Suche…' : 'Uhr suchen'),
          ),
        ],
      ),
    );
  }
}
