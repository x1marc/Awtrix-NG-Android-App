import 'package:flutter/material.dart';

import 'api.dart';
import 'widgets.dart';

class AppsPage extends StatefulWidget {
  final AwtrixDevice device;
  const AppsPage({super.key, required this.device});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;
  String? _error;

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
      _apps = await api.getApps();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Apps nicht erreichbar (${widget.device.host}).';
        });
      }
    }
  }

  String _name(Map<String, dynamic> a) =>
      (a['name'] ?? a['id'] ?? a['app'] ?? '').toString();

  Future<void> _do(Future f, String ok) async {
    try {
      await f;
      snack(context, ok);
    } catch (_) {
      snack(context, 'Nicht erreichbar');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _do(api.prevApp(), 'Zurück'),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Vorherige'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _do(api.nextApp(), 'Weiter'),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Nächste'),
              ),
            ),
            IconButton(
              tooltip: 'Aktualisieren',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _apps.isEmpty
                ? ListView(children: const [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Keine Apps gemeldet.')),
                    ),
                  ])
                : ListView.builder(
                    itemCount: _apps.length,
                    itemBuilder: (_, i) {
                      final a = _apps[i];
                      final name = _name(a);
                      final enabled = a['enabled'];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.web_stories),
                          title: Text(name.isEmpty ? '(unbenannt)' : name),
                          subtitle: enabled is bool
                              ? Text(enabled ? 'aktiv' : 'deaktiviert')
                              : null,
                          onTap: name.isEmpty
                              ? null
                              : () => _do(api.switchApp(name), 'Zeige „$name"'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Löschen',
                            onPressed: name.isEmpty
                                ? null
                                : () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text('„$name" löschen?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Abbrechen')),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Löschen')),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await _do(api.deleteApp(name), 'Gelöscht');
                                      _load();
                                    }
                                  },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
