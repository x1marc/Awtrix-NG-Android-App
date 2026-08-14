import 'package:flutter/material.dart';

/// Wandelt eine Farbe in "#RRGGBB".
String colorToHex(Color c) {
  String h(int v) => v.toRadixString(16).padLeft(2, '0');
  return '#${h(c.red)}${h(c.green)}${h(c.blue)}'.toUpperCase();
}

/// Parst "#RRGGBB" / "RRGGBB" -> Color (Fallback Weiß).
Color hexToColor(String? s) {
  if (s == null) return const Color(0xFFFFFFFF);
  var h = s.replaceAll('#', '').trim();
  if (h.length == 3) h = h.split('').map((e) => '$e$e').join();
  if (h.length != 6) return const Color(0xFFFFFFFF);
  final v = int.tryParse(h, radix: 16);
  if (v == null) return const Color(0xFFFFFFFF);
  return Color(0xFF000000 | v);
}

/// "#RRGGBB" -> [r, g, b] (für API-Aufrufe, die ein Array erwarten).
List<int> rgbFromHex(String hex) {
  final c = hexToColor(hex);
  return [c.red, c.green, c.blue];
}

const List<Color> kPresetColors = [
  Color(0xFFFFFFFF), Color(0xFFFF0000), Color(0xFFFF7A00), Color(0xFFFFC800),
  Color(0xFF00FF00), Color(0xFF00C8FF), Color(0xFF0050FF), Color(0xFF8A2BE2),
  Color(0xFFFF00AA), Color(0xFFFFA03C), Color(0xFF00FFC8), Color(0xFF666666),
];

/// Zeigt den Farbwähler und liefert "#RRGGBB" oder null (Abbrechen).
Future<String?> pickColor(BuildContext context, {String? initialHex}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ColorPickerDialog(initial: hexToColor(initialHex)),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _r = widget.initial.red.toDouble();
  late double _g = widget.initial.green.toDouble();
  late double _b = widget.initial.blue.toDouble();

  Color get _color => Color.fromARGB(255, _r.round(), _g.round(), _b.round());

  Widget _slider(String label, Color c, double v, ValueChanged<double> on) {
    return Row(children: [
      SizedBox(width: 18, child: Text(label)),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: c, thumbColor: c),
          child: Slider(value: v, min: 0, max: 255, onChanged: on),
        ),
      ),
      SizedBox(width: 34, child: Text(v.round().toString(), textAlign: TextAlign.end)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Farbe wählen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(colorToHex(_color),
                  style: TextStyle(
                      color: _color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _slider('R', Colors.red, _r, (v) => setState(() => _r = v)),
            _slider('G', Colors.green, _g, (v) => setState(() => _g = v)),
            _slider('B', Colors.blue, _b, (v) => setState(() => _b = v)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kPresetColors)
                  InkWell(
                    onTap: () => setState(() {
                      _r = c.red.toDouble();
                      _g = c.green.toDouble();
                      _b = c.blue.toDouble();
                    }),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen')),
        FilledButton(
            onPressed: () => Navigator.pop(context, colorToHex(_color)),
            child: const Text('Übernehmen')),
      ],
    );
  }
}
