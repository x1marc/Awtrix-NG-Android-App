import 'package:flutter/material.dart';

import 'api.dart';
import 'color_picker.dart';
import 'favorites.dart';
import 'l10n.dart';
import 'widgets.dart';

/// Vollständiger Benachrichtigungs-Composer mit Effekten und Vorlagen.
class NotifyPage extends StatefulWidget {
  final AwtrixDevice device;
  const NotifyPage({super.key, required this.device});

  @override
  State<NotifyPage> createState() => _NotifyPageState();
}

class _NotifyPageState extends State<NotifyPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  final _text = TextEditingController(text: 'Hallo!');
  final _icon = TextEditingController();
  final _sound = TextEditingController();
  List<int> _color = const [255, 255, 255];
  double _duration = 0; // 0 = Standard
  double _scroll = 100; // % (100 = Standard)
  double _progress = -1; // -1 = aus
  bool _hold = false;
  bool _rainbow = false;
  bool _blink = false;
  bool _fade = false;
  bool _stack = true;
  bool _wakeup = false;
  bool _busy = false;
  List<Map<String, dynamic>> _presets = [];

  @override
  void initState() {
    super.initState();
    FavStore.notifyPresets().then((p) => setState(() => _presets = p));
  }

  Map<String, dynamic> _body() {
    final b = <String, dynamic>{
      'text': _text.text,
      'stack': _stack,
      if (_icon.text.trim().isNotEmpty) 'icon': _icon.text.trim(),
      if (_duration > 0) 'durationMs': (_duration * 1000).round(),
      if (_hold) 'hold': true,
      if (_wakeup) 'wakeup': true,
      if (_blink) 'textBlinkMs': 800,
      if (_fade) 'textFadeMs': 800,
      if (_progress >= 0) 'progress': _progress.round(),
      if (_sound.text.trim().isNotEmpty) 'soundRtttl': _sound.text.trim(),
    };
    if (_rainbow) {
      b['textColor'] = 'palette';
      b['palette'] = 'rainbow';
      b['paletteBlend'] = true;
    } else {
      b['textColor'] = _color;
    }
    if (_scroll != 100) b['scroll'] = {'speed': _scroll.round()};
    return b;
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final r = await api.sendNotification(_body());
      snack(
          context,
          (r.statusCode >= 200 && r.statusCode < 300)
              ? tr('sent')
              : trp('rejected', {'code': '${r.statusCode}'}));
    } catch (_) {
      snack(context, tr('notReachable'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Map<String, dynamic> _uiState() => {
        'text': _text.text,
        'icon': _icon.text,
        'sound': _sound.text,
        'color': _color,
        'duration': _duration,
        'scroll': _scroll,
        'progress': _progress,
        'hold': _hold,
        'rainbow': _rainbow,
        'blink': _blink,
        'fade': _fade,
        'stack': _stack,
        'wakeup': _wakeup,
      };

  void _loadPreset(Map<String, dynamic> p) {
    setState(() {
      _text.text = (p['text'] ?? '').toString();
      _icon.text = (p['icon'] ?? '').toString();
      _sound.text = (p['sound'] ?? '').toString();
      final c = p['color'];
      if (c is List && c.length == 3) {
        _color = c.map((e) => (e as num).toInt()).toList();
      }
      _duration = (p['duration'] as num?)?.toDouble() ?? 0;
      _scroll = (p['scroll'] as num?)?.toDouble() ?? 100;
      _progress = (p['progress'] as num?)?.toDouble() ?? -1;
      _hold = p['hold'] == true;
      _rainbow = p['rainbow'] == true;
      _blink = p['blink'] == true;
      _fade = p['fade'] == true;
      _stack = p['stack'] != false;
      _wakeup = p['wakeup'] == true;
    });
  }

  Future<void> _savePreset() async {
    final list = await FavStore.addNotifyPreset(_uiState());
    setState(() => _presets = list);
    snack(context, tr('saved_as_template'));
  }

  Future<void> _pickIcon() async {
    List<String> names = [];
    try {
      final data = await api.getFiles('/ICONS');
      final files = data['files'];
      if (files is List) {
        names = files
            .whereType<Map>()
            .map((e) => '${e['name']}')
            .where((n) => n.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    if (!mounted) return;
    if (names.isEmpty) {
      snack(context, tr('no_icons_on_clock'));
      return;
    }
    final sel = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        children: [
          for (final n in names)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(n),
              onTap: () => Navigator.pop(context, n),
            ),
        ],
      ),
    );
    if (sel != null) {
      // Dateiname ohne Endung als Icon-Referenz.
      final base = sel.contains('.') ? sel.substring(0, sel.lastIndexOf('.')) : sel;
      setState(() => _icon.text = base);
    }
  }

  Widget _sw(String label, bool v, ValueChanged<bool> on) =>
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: v,
        onChanged: on,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('notification'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SectionCard(
            title: tr('content'),
            icon: Icons.notifications,
            children: [
              TextField(
                controller: _text,
                decoration: InputDecoration(
                    labelText: tr('text'),
                    filled: false,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _icon,
                    decoration: InputDecoration(
                        labelText: tr('icon_name_or_id'),
                        filled: false,
                        border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickIcon,
                  icon: const Icon(Icons.image_search, size: 18),
                  label: Text(tr('choose')),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final e in kColors.entries)
                  ChoiceChip(
                    label: Text(colorLabel(e.key)),
                    selected: _color == e.value,
                    onSelected: (_) => setState(() => _color = e.value),
                  ),
                ActionChip(
                  avatar: CircleAvatar(radius: 9, backgroundColor: rgb(_color)),
                  label: Text(tr('custom_dots')),
                  onPressed: () async {
                    final hex =
                        await pickColor(context, initialHex: colorToHex(rgb(_color)));
                    if (hex != null) setState(() => _color = rgbFromHex(hex));
                  },
                ),
              ]),
            ],
          ),
          SectionCard(
            title: tr('effects'),
            icon: Icons.auto_awesome,
            children: [
              _sw(tr('eff_hold'), _hold, (v) => setState(() => _hold = v)),
              _sw(tr('eff_rainbow'), _rainbow,
                  (v) => setState(() => _rainbow = v)),
              _sw(tr('eff_blink'), _blink, (v) => setState(() => _blink = v)),
              _sw(tr('eff_fade'), _fade, (v) => setState(() => _fade = v)),
              _sw(tr('eff_wakeup'), _wakeup,
                  (v) => setState(() => _wakeup = v)),
              _sw(tr('eff_stack'), _stack, (v) => setState(() => _stack = v)),
            ],
          ),
          SectionCard(
            title: tr('fine_tuning'),
            icon: Icons.tune,
            children: [
              _sliderRow(
                  tr('duration'),
                  _duration == 0 ? tr('standard') : '${_duration.round()} s',
                  _duration,
                  0,
                  60,
                  (v) => setState(() => _duration = v)),
              _sliderRow(
                  tr('scroll_speed'),
                  _scroll == 100 ? tr('standard') : '${_scroll.round()} %',
                  _scroll,
                  10,
                  200,
                  (v) => setState(() => _scroll = v)),
              _sliderRow(
                  tr('progress_bar'),
                  _progress < 0 ? tr('off') : '${_progress.round()} %',
                  _progress,
                  -1,
                  100,
                  (v) => setState(() => _progress = v)),
              const SizedBox(height: 6),
              TextField(
                controller: _sound,
                decoration: InputDecoration(
                  labelText: tr('sound_rtttl'),
                  hintText: 'two_short:d=4,o=5,b=100:16e6,16e6',
                  filled: false,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(tr('send')),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      try {
                        await api.dismiss();
                        snack(context, tr('dismissed'));
                      } catch (_) {}
                    },
              icon: const Icon(Icons.clear),
              label: Text(tr('weg')),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _savePreset,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(tr('template')),
            ),
          ]),
          if (_presets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(tr('templates'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            for (var i = 0; i < _presets.length; i++)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text('${_presets[i]['text'] ?? tr('empty')}'),
                  onTap: () => _loadPreset(_presets[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final l = await FavStore.removeNotifyPreset(i);
                      setState(() => _presets = l);
                    },
                  ),
                ),
              ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sliderRow(String label, String value, double v, double min, double max,
      ValueChanged<double> on) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        Slider(
          value: v.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: on,
        ),
      ],
    );
  }
}
