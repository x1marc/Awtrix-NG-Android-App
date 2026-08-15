import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'color_picker.dart';
import 'matrix_preview.dart';
import 'widgets.dart';

class ControlPage extends StatefulWidget {
  final AwtrixDevice device;
  final ValueListenable<bool>? active;
  const ControlPage({super.key, required this.device, this.active});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  final _textC = TextEditingController(text: 'Hallo!');
  List<int> _notifyColor = const [255, 255, 255];
  double _brightness = 120;
  double _moodBright = 120;
  String _overlay = 'off';
  bool _busy = false;

  Future<void> _run(Future<http.Response> Function() f, String ok) async {
    setState(() => _busy = true);
    try {
      final r = await f();
      snack(context,
          (r.statusCode >= 200 && r.statusCode < 300) ? ok : 'Fehler ${r.statusCode}');
    } catch (_) {
      snack(context, 'Uhr nicht erreichbar');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        MatrixPreview(api: api, active: widget.active),

        // --- Benachrichtigung ---
        SectionCard(
          title: 'Benachrichtigung',
          icon: Icons.notifications,
          children: [
            TextField(
              controller: _textC,
              decoration: const InputDecoration(
                  labelText: 'Text', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in kColors.entries)
                  ChoiceChip(
                    label: Text(e.key),
                    selected: _notifyColor == e.value,
                    onSelected: (_) => setState(() => _notifyColor = e.value),
                  ),
                ActionChip(
                  avatar:
                      CircleAvatar(radius: 9, backgroundColor: rgb(_notifyColor)),
                  label: const Text('Eigene…'),
                  onPressed: () async {
                    final hex = await pickColor(context,
                        initialHex: colorToHex(rgb(_notifyColor)));
                    if (hex != null) {
                      setState(() => _notifyColor = rgbFromHex(hex));
                    }
                  },
                ),
              ],
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
          ],
        ),

        // --- Apps ---
        SectionCard(
          title: 'Apps',
          icon: Icons.apps,
          children: [
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
          ],
        ),

        // --- Display ---
        SectionCard(
          title: 'Display',
          icon: Icons.monitor,
          children: [
            Row(children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _busy ? null : () => _run(() => api.power(true), 'An'),
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
                  onChangeEnd: (v) =>
                      _run(() => api.setBrightness(v.round()), 'Helligkeit'),
                ),
              ),
              SizedBox(width: 34, child: Text(_brightness.round().toString())),
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
          ],
        ),

        // --- Moodlight ---
        SectionCard(
          title: 'Stimmungslicht',
          icon: Icons.lightbulb,
          children: [
            Row(children: [
              const Icon(Icons.brightness_6, size: 20),
              Expanded(
                child: Slider(
                  value: _moodBright,
                  min: 0,
                  max: 255,
                  divisions: 51,
                  label: _moodBright.round().toString(),
                  onChanged: (v) => setState(() => _moodBright = v),
                ),
              ),
              SizedBox(width: 34, child: Text(_moodBright.round().toString())),
            ]),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in kColors.entries)
                  ActionChip(
                    avatar: CircleAvatar(
                        radius: 9, backgroundColor: rgb(e.value)),
                    label: Text(e.key),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => api.moodlight(e.value,
                                brightness: _moodBright.round()),
                            'Moodlight'),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.palette, size: 18),
                  label: const Text('Eigene…'),
                  onPressed: _busy
                      ? null
                      : () async {
                          final hex = await pickColor(context);
                          if (hex != null) {
                            _run(
                                () => api.moodlight(rgbFromHex(hex),
                                    brightness: _moodBright.round()),
                                'Moodlight');
                          }
                        },
                ),
                ActionChip(
                  avatar: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Aus'),
                  onPressed:
                      _busy ? null : () => _run(api.moodlightOff, 'Aus'),
                ),
              ],
            ),
          ],
        ),

        // --- Status-LEDs ---
        SectionCard(
          title: 'Status-LEDs',
          icon: Icons.circle,
          children: [
            for (var id = 1; id <= 3; id++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  SizedBox(width: 44, child: Text('LED $id')),
                  for (final c in kColors.values.take(3))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _busy
                            ? null
                            : () =>
                                _run(() => api.indicator(id, c), 'LED $id'),
                        child: CircleAvatar(radius: 12, backgroundColor: rgb(c)),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Eigene Farbe',
                    icon: const Icon(Icons.palette, size: 18),
                    onPressed: _busy
                        ? null
                        : () async {
                            final hex = await pickColor(context);
                            if (hex != null) {
                              _run(() => api.indicator(id, rgbFromHex(hex)),
                                  'LED $id');
                            }
                          },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'aus',
                    onPressed: _busy
                        ? null
                        : () => _run(() => api.indicatorOff(id), 'LED $id aus'),
                  ),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
