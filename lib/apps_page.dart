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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _apps = await api.getApps(); // wirft nicht mehr
    if (mounted) setState(() => _loading = false);
  }

  String _name(Map<String, dynamic> a) =>
      (a['name'] ?? a['id'] ?? a['app'] ?? '').toString();

  Future<void> _do(Future f, String ok) async {
    try {
      await f;
      snack(context, ok);
    } catch (_) {
      snack(context, 'Uhr nicht erreichbar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Immer sichtbare Steuerleiste
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _apps.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 40),
                          Icon(Icons.apps, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Keine App-Liste erhalten.\n'
                                'Die Vor-/Zurück-Tasten oben funktionieren trotzdem.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ])
                      : ListView.builder(
                          itemCount: _apps.length,
                          itemBuilder: (_, i) {
                            final a = _apps[i];
                            final name = _name(a);
                            final enabled = a['enabled'];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.web_stories),
                                title:
                                    Text(name.isEmpty ? '(unbenannt)' : name),
                                subtitle: enabled is bool
                                    ? Text(enabled ? 'aktiv' : 'deaktiviert')
                                    : null,
                                onTap: name.isEmpty
                                    ? null
                                    : () => _do(
                                        api.switchApp(name), 'Zeige „$name"'),
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
                                                        Navigator.pop(
                                                            context, false),
                                                    child:
                                                        const Text('Abbrechen')),
                                                FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child:
                                                        const Text('Löschen')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            await _do(api.deleteApp(name),
                                                'Gelöscht');
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
