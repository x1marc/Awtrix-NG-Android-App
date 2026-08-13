import 'package:flutter/material.dart';

import 'api.dart';
import 'widgets.dart';

class SystemPage extends StatefulWidget {
  final AwtrixDevice device;
  const SystemPage({super.key, required this.device});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  Map<String, dynamic> _device = {};
  Map<String, dynamic> _system = {};
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
      final d = await api.getDevice();
      Map<String, dynamic> s = {};
      try {
        s = await api.getSystem();
      } catch (_) {}
      _device = d;
      _system = s;
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
                child: Text(k,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(child: Text('${m[k]}')),
            ],
          ),
        ),
      if (m.isEmpty) const Text('—'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          SectionCard(
            title: 'Gerät & Statistik',
            icon: Icons.info_outline,
            children: _kv(_device),
          ),
          SectionCard(
            title: 'System / Netzwerk',
            icon: Icons.router,
            children: _kv(_system),
          ),
          SectionCard(
            title: 'Aktionen',
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
                        foregroundColor: Theme.of(context).colorScheme.error),
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
                    label: const Text('Aktualisieren'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
