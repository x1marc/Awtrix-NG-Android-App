import 'package:flutter/material.dart';

import 'api.dart';
import 'device_shell.dart';
import 'main.dart' show ThemeToggleButton;
import 'support.dart';
import 'version.dart';

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

  Future<void> _deviceDialog({AwtrixDevice? existing}) async {
    final editing = existing != null;
    final ipC = TextEditingController(text: existing?.host ?? '');
    final nameC = TextEditingController(
        text: (editing && existing.name != existing.host) ? existing.name : '');
    final userC = TextEditingController(text: existing?.user ?? '');
    final passC = TextEditingController(text: existing?.pass ?? '');
    var showPass = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(editing ? 'Uhr bearbeiten' : 'Uhr hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipC,
                  autofocus: !editing,
                  decoration: const InputDecoration(
                    labelText: 'IP oder Hostname',
                    hintText: '192.168.1.111',
                    filled: false,
                  ),
                ),
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                      labelText: 'Name (optional)', filled: false),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Nur falls die Uhr einen Login verlangt:',
                      style: TextStyle(fontSize: 12)),
                ),
                TextField(
                  controller: userC,
                  decoration: const InputDecoration(
                      labelText: 'Benutzer (optional)', filled: false),
                ),
                TextField(
                  controller: passC,
                  obscureText: !showPass,
                  decoration: InputDecoration(
                    labelText: 'Passwort (optional)',
                    filled: false,
                    suffixIcon: IconButton(
                      icon: Icon(showPass
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setLocal(() => showPass = !showPass),
                    ),
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
                child: Text(editing ? 'Speichern' : 'Hinzufügen')),
          ],
        ),
      ),
    );
    if (ok != true || ipC.text.trim().isEmpty) return;
    final host = ipC.text.trim();
    final name = nameC.text.trim();
    final user = userC.text.trim();
    final pass = passC.text;
    if (editing) {
      existing.host = host;
      existing.name = name.isEmpty ? host : name;
      existing.user = user.isEmpty ? null : user;
      existing.pass = pass.isEmpty ? null : pass;
    } else {
      _devices.add(AwtrixDevice(
        host: host,
        name: name,
        user: user.isEmpty ? null : user,
        pass: pass.isEmpty ? null : pass,
      ));
    }
    await _persist();
    setState(() {});
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
                    const SizedBox(height: 28),
                    Text('Version $kAppVersion',
                        style: TextStyle(color: cs.outline, fontSize: 12)),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Bearbeiten (Login)',
                            onPressed: () =>
                                _deviceDialog(existing: _devices[i]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Entfernen',
                            onPressed: () async {
                              _devices.removeAt(i);
                              await _persist();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const BmcCard(),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 14),
                  child: Center(
                    child: Text('Awtrix NG App · v$kAppVersion',
                        style: TextStyle(color: cs.outline, fontSize: 12)),
                  ),
                ),
              ],
            ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ip',
            onPressed: () => _deviceDialog(),
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
