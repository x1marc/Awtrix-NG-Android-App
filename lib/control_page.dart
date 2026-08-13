import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

class ControlPage extends StatefulWidget {
  final AwtrixDevice device;
  const ControlPage({super.key, required this.device});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  final _textC = TextEditingController(text: 'Hallo!');
  List<int> _notifyColor = const [255, 255, 255];
  double _brightness = 120;
  bool _autoBrightness = false;
  String _overlay = 'off';
  bool _busy = false;

  static const _colors = <String, List<int>>{
    'Weiß': [255, 255, 255],
    'Rot': [255, 0, 0],
    'Grün': [0, 255, 0],
    'Blau': [0, 80, 255],
    'Gelb': [255, 200, 0],
    'Warmweiß': [255, 160, 60],
  };

  Future<void> _run(Future<http.Response> Function() f, String ok) async {
    setState(() => _busy = true);
    try {
      final r = await f();
      _snack((r.statusCode >= 200 && r.statusCode < 300)
          ? ok
          : 'Fehler ${r.statusCode}');
    } catch (_) {
      _snack('Uhr nicht erreichbar');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(milliseconds: 1200)),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: ListView(
        children: [
          // --- Benachrichtigung ---
          _card('Benachrichtigung', Icons.notifications, [
            TextField(
              controller: _textC,
              decoration: const InputDecoration(
                labelText: 'Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: _colors.entries.map((e) {
                final selected = _notifyColor == e.value;
                return ChoiceChip(
                  label: Text(e.key),
                  selected: selected,
                  onSelected: (_) => setState(() => _notifyColor = e.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => api.notify(_textC.text, color: _notifyColor),
                          'Gesendet'),
                  icon: const Icon(Icons.send),
                  label: const Text('Senden'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => _run(api.dismiss, 'Verworfen'),
                child: const Text('Wegwischen'),
              ),
            ]),
          ]),

          // --- Apps ---
          _card('Apps', Icons.apps, [
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(api.prevApp, 'Zurück'),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Vorherige'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(api.nextApp, 'Weiter'),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Nächste'),
                ),
              ),
            ]),
          ]),

          // --- Display ---
          _card('Display', Icons.monitor, [
            Row(children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed:
                      _busy ? null : () => _run(() => api.power(true), 'An'),
                  child: const Text('An'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed:
                      _busy ? null : () => _run(() => api.power(false), 'Aus'),
                  child: const Text('Aus'),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.brightness_6, size: 20),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: 0,
                  max: 255,
                  divisions: 51,
                  label: _brightness.round().toString(),
                  onChanged: (v) => setState(() => _brightness = v),
                  onChangeEnd: (v) => _run(
                      () => api.setBrightness(v.round()), 'Helligkeit gesetzt'),
                ),
              ),
              SizedBox(
                  width: 34, child: Text(_brightness.round().toString())),
            ]),
            Row(children: [
              const Text('Wetter-Overlay:'),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _overlay,
                items: const [
                  DropdownMenuItem(value: 'off', child: Text('aus')),
                  DropdownMenuItem(value: 'rain', child: Text('Regen')),
                  DropdownMenuItem(value: 'snow', child: Text('Schnee')),
                  DropdownMenuItem(value: 'drizzle', child: Text('Niesel')),
                  DropdownMenuItem(value: 'storm', child: Text('Sturm')),
                  DropdownMenuItem(value: 'thunder', child: Text('Gewitter')),
                  DropdownMenuItem(value: 'frost', child: Text('Frost')),
                ],
                onChanged: _busy
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() => _overlay = v);
                        _run(() => api.overlay(v == 'off' ? null : v),
                            'Overlay: $v');
                      },
              ),
            ]),
          ]),

          // --- Moodlight ---
          _card('Stimmungslicht', Icons.lightbulb, [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._colors.entries.map((e) => ActionChip(
                      avatar: CircleAvatar(
                          backgroundColor: Color.fromARGB(
                              255, e.value[0], e.value[1], e.value[2])),
                      label: Text(e.key),
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => api.moodlight(e.value), 'Moodlight ${e.key}'),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Aus'),
                  onPressed:
                      _busy ? null : () => _run(api.moodlightOff, 'Moodlight aus'),
                ),
              ],
            ),
          ]),

          // --- Status-LEDs ---
          _card('Status-LEDs', Icons.circle, [
            for (var id = 1; id <= 3; id++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(width: 44, child: Text('LED $id')),
                  ..._colors.values.take(4).map((c) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: _busy
                              ? null
                              : () => _run(() => api.indicator(id, c),
                                  'LED $id gesetzt'),
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor:
                                Color.fromARGB(255, c[0], c[1], c[2]),
                          ),
                        ),
                      )),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _busy
                        ? null
                        : () => _run(() => api.indicatorOff(id), 'LED $id aus'),
                  ),
                ]),
              ),
          ]),

          // --- System ---
          _card('System', Icons.settings, [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatische Helligkeit'),
              value: _autoBrightness,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() => _autoBrightness = v);
                      _run(() => api.autoBrightness(v),
                          'Auto-Helligkeit ${v ? 'an' : 'aus'}');
                    },
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Uhr neu starten?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Abbrechen')),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Neu starten')),
                          ],
                        ),
                      );
                      if (ok == true) _run(api.reboot, 'Startet neu…');
                    },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Neu starten'),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
