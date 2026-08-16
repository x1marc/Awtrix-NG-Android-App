import 'package:flutter/material.dart';

import 'api.dart';
import 'custom_app_page.dart';
import 'pixel_editor_page.dart';
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
    _apps = await api.getApps();
    if (mounted) setState(() => _loading = false);
  }

  String _name(Map<String, dynamic> a) =>
      (a['name'] ?? a['id'] ?? a['app'] ?? '').toString();
  bool _enabled(Map<String, dynamic> a) => a['enabled'] != false;

  Future<void> _pushOrder() async {
    final order =
        _apps.map(_name).where((n) => n.isNotEmpty).toList();
    final disabled = _apps
        .where((a) => !_enabled(a))
        .map(_name)
        .where((n) => n.isNotEmpty)
        .toList();
    try {
      final r = await api.reorderApps(order, disabled);
      if (r.statusCode < 200 || r.statusCode >= 300) {
        snack(context, 'Uhr lehnte ab (${r.statusCode})');
      }
    } catch (_) {
      snack(context, 'Nicht erreichbar');
    }
  }

  Future<void> _toggle(int i, bool v) async {
    setState(() => _apps[i] = {..._apps[i], 'enabled': v});
    await _pushOrder();
  }

  void _reorder(int oldI, int newI) {
    setState(() {
      if (newI > oldI) newI -= 1;
      final item = _apps.removeAt(oldI);
      _apps.insert(newI, item);
    });
    _pushOrder();
  }

  Future<void> _do(Future f, String ok) async {
    try {
      await f;
      snack(context, ok);
    } catch (_) {
      snack(context, 'Nicht erreichbar');
    }
  }

  Future<void> _delete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('„$name" löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await _do(api.deleteApp(name), 'Gelöscht');
      _load();
    }
  }

  Future<void> _addApp() async {
    final nameC = TextEditingController();
    final textC = TextEditingController();
    final iconC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('App hinzufügen'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameC,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'App-Name (eindeutig)',
                  hintText: 'z. B. info',
                  filled: false),
            ),
            TextField(
              controller: textC,
              decoration: const InputDecoration(
                  labelText: 'Text', hintText: 'z. B. Hallo', filled: false),
            ),
            TextField(
              controller: iconC,
              decoration: const InputDecoration(
                  labelText: 'Icon-Nummer (optional)', filled: false),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Erstellen')),
        ],
      ),
    );
    if (ok == true && nameC.text.trim().isNotEmpty) {
      final name = nameC.text.trim();
      await _do(
        api.pushApp(name, {
          'text': textC.text,
          if (iconC.text.trim().isNotEmpty) 'icon': iconC.text.trim(),
        }),
        'Erstellt',
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(Icons.refresh)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonalIcon(
                onPressed: _addApp,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schnell-App'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CustomAppPage(device: widget.device)),
                  );
                  if (changed == true) _load();
                },
                icon: const Icon(Icons.dashboard_customize, size: 18),
                label: const Text('Eigene App'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PixelEditorPage(device: widget.device)),
                ),
                icon: const Icon(Icons.grid_on, size: 18),
                label: const Text('Pixel malen'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _apps.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 40),
                      Icon(Icons.apps, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Keine App-Liste erhalten.\n'
                            'Vor-/Zurück oben & „+ App" funktionieren trotzdem.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ])
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _apps.length,
                      onReorder: _reorder,
                      itemBuilder: (_, i) {
                        final a = _apps[i];
                        final name = _name(a);
                        final on = _enabled(a);
                        return Card(
                          key: ValueKey(name.isEmpty ? 'idx-$i' : 'app-$name'),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_indicator),
                            ),
                            title: Text(name.isEmpty ? '(unbenannt)' : name),
                            subtitle: Text(on ? 'aktiv' : 'deaktiviert'),
                            onTap: name.isEmpty
                                ? null
                                : () =>
                                    _do(api.switchApp(name), 'Zeige „$name"'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: on,
                                  onChanged: name.isEmpty
                                      ? null
                                      : (v) => _toggle(i, v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Löschen',
                                  onPressed:
                                      name.isEmpty ? null : () => _delete(name),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
