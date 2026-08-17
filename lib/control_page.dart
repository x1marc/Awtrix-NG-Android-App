import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'color_picker.dart';
import 'favorites.dart';
import 'l10n.dart';
import 'matrix_preview.dart';
import 'notify_page.dart';
import 'sensors.dart';
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
  List<String> _moodFavs = [];

  @override
  void initState() {
    super.initState();
    FavStore.moodColors().then((c) {
      if (mounted) setState(() => _moodFavs = c);
    });
  }

  Future<void> _run(Future<http.Response> Function() f, String ok) async {
    setState(() => _busy = true);
    try {
      final r = await f();
      snack(
          context,
          (r.statusCode >= 200 && r.statusCode < 300)
              ? ok
              : trp('rejected', {'code': '${r.statusCode}'}));
    } catch (_) {
      snack(context, tr('notReachable'));
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
        SensorsCard(api: api),

        // --- Benachrichtigung ---
        SectionCard(
          title: tr('notification'),
          icon: Icons.notifications,
          children: [
            TextField(
              controller: _textC,
              decoration: InputDecoration(
                  labelText: tr('text'),
                  filled: false,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in kColors.entries)
                  ChoiceChip(
                    label: Text(colorLabel(e.key)),
                    selected: _notifyColor == e.value,
                    onSelected: (_) => setState(() => _notifyColor = e.value),
                  ),
                ActionChip(
                  avatar:
                      CircleAvatar(radius: 9, backgroundColor: rgb(_notifyColor)),
                  label: Text(tr('custom_dots')),
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
                          tr('sent')),
                  icon: const Icon(Icons.send),
                  label: Text(tr('send')),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    _busy ? null : () => _run(api.dismiss, tr('dismissed')),
                child: Text(tr('dismiss')),
              ),
            ]),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NotifyPage(device: widget.device)),
                ),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(tr('advanced_notify')),
              ),
            ),
          ],
        ),

        // --- Apps ---
        SectionCard(
          title: tr('nav_apps'),
          icon: Icons.apps,
          children: [
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(api.prevApp, tr('back')),
                  icon: const Icon(Icons.chevron_left),
                  label: Text(tr('previous')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _run(api.nextApp, tr('forward')),
                  icon: const Icon(Icons.chevron_right),
                  label: Text(tr('next')),
                ),
              ),
            ]),
          ],
        ),

        // --- Display ---
        SectionCard(
          title: tr('display'),
          icon: Icons.monitor,
          children: [
            Row(children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed:
                      _busy ? null : () => _run(() => api.power(true), tr('on')),
                  child: Text(tr('on')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => _run(() => api.power(false), tr('off')),
                  child: Text(tr('off')),
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
              Text(tr('weather_overlay')),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _overlay,
                items: [
                  DropdownMenuItem(value: 'off', child: Text(tr('ov_off'))),
                  DropdownMenuItem(value: 'rain', child: Text(tr('ov_rain'))),
                  DropdownMenuItem(value: 'snow', child: Text(tr('ov_snow'))),
                  DropdownMenuItem(
                      value: 'drizzle', child: Text(tr('ov_drizzle'))),
                  DropdownMenuItem(value: 'storm', child: Text(tr('ov_storm'))),
                  DropdownMenuItem(
                      value: 'thunder', child: Text(tr('ov_thunder'))),
                  DropdownMenuItem(value: 'frost', child: Text(tr('ov_frost'))),
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
          title: tr('moodlight'),
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
                for (final hex in _moodFavs)
                  ActionChip(
                    avatar: CircleAvatar(
                        radius: 9, backgroundColor: hexToColor(hex)),
                    label: const Text('★'),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => api.moodlight(rgbFromHex(hex),
                                brightness: _moodBright.round()),
                            tr('moodlight')),
                  ),
                for (final e in kColors.entries)
                  ActionChip(
                    avatar: CircleAvatar(
                        radius: 9, backgroundColor: rgb(e.value)),
                    label: Text(colorLabel(e.key)),
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => api.moodlight(e.value,
                                brightness: _moodBright.round()),
                            tr('moodlight')),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.palette, size: 18),
                  label: Text(tr('custom_dots')),
                  onPressed: _busy
                      ? null
                      : () async {
                          final hex = await pickColor(context);
                          if (hex != null) {
                            final favs = await FavStore.addMoodColor(hex);
                            if (mounted) setState(() => _moodFavs = favs);
                            _run(
                                () => api.moodlight(rgbFromHex(hex),
                                    brightness: _moodBright.round()),
                                tr('moodlight'));
                          }
                        },
                ),
                ActionChip(
                  avatar: const Icon(Icons.power_settings_new, size: 18),
                  label: Text(tr('off')),
                  onPressed:
                      _busy ? null : () => _run(api.moodlightOff, tr('off')),
                ),
              ],
            ),
          ],
        ),

        // --- Status-LEDs ---
        SectionCard(
          title: tr('status_leds'),
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
                    tooltip: tr('own_color'),
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
                    tooltip: tr('off'),
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
