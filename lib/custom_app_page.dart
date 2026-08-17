import 'package:flutter/material.dart';

import 'api.dart';
import 'color_picker.dart';
import 'l10n.dart';
import 'widgets.dart';

/// Baut eine dauerhafte „eigene App" (bleibt in der Uhr-Rotation).
class CustomAppPage extends StatefulWidget {
  final AwtrixDevice device;
  const CustomAppPage({super.key, required this.device});

  @override
  State<CustomAppPage> createState() => _CustomAppPageState();
}

class _CustomAppPageState extends State<CustomAppPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  final _name = TextEditingController(text: 'meineapp');
  final _text = TextEditingController(text: 'Hallo');
  final _icon = TextEditingController();
  List<int> _color = const [0, 200, 255];
  double _duration = 7;
  double _scroll = 100;
  bool _rainbow = false;
  bool _busy = false;

  Map<String, dynamic> _body() {
    final b = <String, dynamic>{
      'text': _text.text,
      if (_icon.text.trim().isNotEmpty) 'icon': _icon.text.trim(),
      if (_duration > 0) 'durationMs': (_duration * 1000).round(),
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

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      snack(context, tr('enter_app_name'));
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await api.pushApp(name, _body());
      if (r.statusCode >= 200 && r.statusCode < 300) {
        snack(context, trp('app_created', {'name': name}));
        if (mounted) Navigator.pop(context, true);
      } else {
        snack(context, trp('rejected', {'code': '${r.statusCode}'}));
      }
    } catch (_) {
      snack(context, tr('notReachable'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await api.deleteApp(name);
      snack(context, trp('app_deleted', {'name': name}));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      snack(context, tr('notReachableShort'));
    }
    if (mounted) setState(() => _busy = false);
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
      final base =
          sel.contains('.') ? sel.substring(0, sel.lastIndexOf('.')) : sel;
      setState(() => _icon.text = base);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('custom_app'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SectionCard(
            title: tr('app'),
            icon: Icons.apps,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: tr('app_name_unique'),
                    helperText: tr('app_update_hint'),
                    filled: false,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
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
                        labelText: tr('icon_name_or_id_opt'),
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
                    final hex = await pickColor(context,
                        initialHex: colorToHex(rgb(_color)));
                    if (hex != null) setState(() => _color = rgbFromHex(hex));
                  },
                ),
              ]),
            ],
          ),
          SectionCard(
            title: tr('appearance'),
            icon: Icons.tune,
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(tr('rainbow_text')),
                value: _rainbow,
                onChanged: (v) => setState(() => _rainbow = v),
              ),
              _slider(tr('duration'), '${_duration.round()} s', _duration, 1, 30,
                  (v) => setState(() => _duration = v)),
              _slider(
                  tr('scroll_speed'),
                  _scroll == 100 ? tr('standard') : '${_scroll.round()} %',
                  _scroll,
                  10,
                  200,
                  (v) => setState(() => _scroll = v)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.check),
                label: Text(tr('create_update')),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(tr('delete')),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max,
      ValueChanged<double> on) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        Slider(
            value: v.clamp(min, max).toDouble(), min: min, max: max, onChanged: on),
      ],
    );
  }
}
