import 'package:flutter/material.dart';

import 'api.dart';
import 'device_shell.dart';
import 'l10n.dart';
import 'main.dart' show LanguageButton, ThemeToggleButton;
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
          ? tr('discover_none')
          : added > 0
              ? trp('discover_found_new',
                  {'n': '${found.length}', 'a': '$added'})
              : trp('discover_found_known', {'n': '${found.length}'})),
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
          title: Text(editing ? tr('edit_clock') : tr('add_clock')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipC,
                  autofocus: !editing,
                  decoration: InputDecoration(
                    labelText: tr('ip_or_host'),
                    hintText: '192.168.1.111',
                    filled: false,
                  ),
                ),
                TextField(
                  controller: nameC,
                  decoration: InputDecoration(
                      labelText: tr('name_optional'), filled: false),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(tr('login_hint'),
                      style: const TextStyle(fontSize: 12)),
                ),
                TextField(
                  controller: userC,
                  decoration: InputDecoration(
                      labelText: tr('user_optional'), filled: false),
                ),
                TextField(
                  controller: passC,
                  obscureText: !showPass,
                  decoration: InputDecoration(
                    labelText: tr('password_optional'),
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
                child: Text(tr('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(editing ? tr('save') : tr('add'))),
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

  Future<void> _broadcast() async {
    final c = TextEditingController(text: 'Hallo!');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('broadcast_title')),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(
              labelText: tr('text'),
              filled: false,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('send'))),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    var n = 0;
    for (final d in _devices) {
      try {
        await AwtrixApi(d).notify(c.text.trim());
        n++;
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trp('broadcast_result',
              {'n': '$n', 'total': '${_devices.length}'}))));
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('help_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('help_1')),
              const SizedBox(height: 8),
              Text(tr('help_2')),
              const SizedBox(height: 8),
              Text(tr('help_3')),
              const SizedBox(height: 8),
              Text(tr('help_4')),
              const SizedBox(height: 8),
              Text(tr('help_5')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showSupportSheet(context);
            },
            child: Text(tr('help_projects')),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ok'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awtrix NG App'),
        actions: [
          IconButton(
            tooltip: tr('help'),
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
          if (_devices.isNotEmpty)
            IconButton(
              tooltip: tr('broadcast'),
              icon: const Icon(Icons.campaign),
              onPressed: _broadcast,
            ),
          const BmcButton(),
          const LanguageButton(),
          const ThemeToggleButton(),
        ],
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
                    Text(tr('no_clock_title'),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      tr('no_clock_hint'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Text(trp('version', {'v': kAppVersion}),
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
                            tooltip: tr('edit_login'),
                            onPressed: () =>
                                _deviceDialog(existing: _devices[i]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: tr('remove'),
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
            label: Text(_scanning ? tr('searching') : tr('find_clock')),
          ),
        ],
      ),
    );
  }
}
