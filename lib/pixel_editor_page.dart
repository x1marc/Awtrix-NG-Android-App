import 'package:flutter/material.dart';

import 'api.dart';
import 'color_picker.dart';

/// Einfacher Pixel-Editor: auf der Matrix malen und als App/Overlay senden.
class PixelEditorPage extends StatefulWidget {
  final AwtrixDevice device;
  const PixelEditorPage({super.key, required this.device});

  @override
  State<PixelEditorPage> createState() => _PixelEditorPageState();
}

class _PixelEditorPageState extends State<PixelEditorPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  int _w = 32;
  int _h = 8;
  late List<int> _px = List.filled(_w * _h, 0); // 0xRRGGBB, 0 = aus
  int _color = 0xFF0000;
  bool _erase = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  Future<void> _loadScreen() async {
    try {
      final s = await api.getScreen();
      if (s != null && s.pixels.isNotEmpty) {
        setState(() {
          _w = s.width;
          _h = s.height;
          _px = List<int>.from(s.pixels.map((e) => e & 0xFFFFFF));
        });
      }
    } catch (_) {}
  }

  void _paintAt(Offset local, double cell) {
    final x = (local.dx / cell).floor();
    final y = (local.dy / cell).floor();
    if (x < 0 || x >= _w || y < 0 || y >= _h) return;
    final i = y * _w + x;
    final v = _erase ? 0 : _color;
    if (_px[i] != v) setState(() => _px[i] = v);
  }

  List<List<dynamic>> _draw() {
    final out = <List<dynamic>>[];
    for (var y = 0; y < _h; y++) {
      for (var x = 0; x < _w; x++) {
        final v = _px[y * _w + x] & 0xFFFFFF;
        if (v != 0) {
          out.add(['pixel', x, y, '#${v.toRadixString(16).padLeft(6, '0')}']);
        }
      }
    }
    return out;
  }

  Future<void> _sendApp() async {
    setState(() => _busy = true);
    try {
      final r = await api.pushApp('pixelart', {
        'draw': _draw(),
        'durationMs': 15000,
      });
      _report(r.statusCode, 'Als App „pixelart" gespeichert');
    } catch (_) {
      _snack('Uhr nicht erreichbar');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendNotify() async {
    setState(() => _busy = true);
    try {
      final r = await api.sendNotification({
        'draw': _draw(),
        'durationMs': 8000,
      });
      _report(r.statusCode, 'Kurz angezeigt');
    } catch (_) {
      _snack('Uhr nicht erreichbar');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _report(int code, String ok) =>
      _snack((code >= 200 && code < 300) ? ok : 'Uhr lehnte ab ($code)');
  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(m), duration: const Duration(milliseconds: 1300)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel-Editor'),
        actions: [
          IconButton(
            tooltip: 'Alles löschen',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _px = List.filled(_w * _h, 0)),
          ),
          IconButton(
            tooltip: 'Aktuelles Bild laden',
            icon: const Icon(Icons.download),
            onPressed: _loadScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, c) {
                final cell = c.maxWidth / _w;
                return GestureDetector(
                  onTapDown: (d) => _paintAt(d.localPosition, cell),
                  onPanStart: (d) => _paintAt(d.localPosition, cell),
                  onPanUpdate: (d) => _paintAt(d.localPosition, cell),
                  child: CustomPaint(
                    size: Size(c.maxWidth, cell * _h),
                    painter: _GridPainter(_px, _w, _h, cell),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final c in kPresetColors)
                  GestureDetector(
                    onTap: () => setState(() {
                      _erase = false;
                      _color = c.value & 0xFFFFFF;
                    }),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (!_erase && (c.value & 0xFFFFFF) == _color)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black26,
                          width: (!_erase && (c.value & 0xFFFFFF) == _color) ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.colorize, size: 18),
                  label: const Text('Eigene'),
                  onPressed: () async {
                    final hex = await pickColor(context);
                    if (hex != null) {
                      setState(() {
                        _erase = false;
                        _color = hexToColor(hex).value & 0xFFFFFF;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.cleaning_services, size: 18),
                  label: const Text('Radierer'),
                  selected: _erase,
                  onSelected: (v) => setState(() => _erase = v),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _sendApp,
                  icon: const Icon(Icons.save),
                  label: const Text('Als App'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _sendNotify,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Kurz zeigen'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final List<int> px;
  final int w, h;
  final double cell;
  _GridPainter(this.px, this.w, this.h, this.cell);

  @override
  void paint(Canvas canvas, Size size) {
    final off = Paint()..color = const Color(0xFF141414);
    final grid = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final r = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        final v = px[y * w + x] & 0xFFFFFF;
        canvas.drawRect(
            r.deflate(0.5),
            v == 0 ? off : (Paint()..color = Color(0xFF000000 | v)));
        canvas.drawRect(r, grid);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}
