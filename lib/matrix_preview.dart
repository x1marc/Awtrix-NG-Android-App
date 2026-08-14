import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';

/// Live-Vorschau des Uhr-Displays: holt /display/screen (JSON mit Pixeln)
/// und zeichnet die LED-Matrix selbst. Aktualisiert sich automatisch.
class MatrixPreview extends StatefulWidget {
  final AwtrixApi api;
  const MatrixPreview({super.key, required this.api});

  @override
  State<MatrixPreview> createState() => _MatrixPreviewState();
}

class _MatrixPreviewState extends State<MatrixPreview> {
  ScreenData? _data;
  bool _live = true;
  bool _failed = false;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (_live) _tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    final d = await widget.api.getScreen();
    _busy = false;
    if (!mounted) return;
    setState(() {
      if (d != null) {
        _data = d;
        _failed = false;
      } else if (_data == null) {
        _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.aspect_ratio, size: 18),
              const SizedBox(width: 8),
              const Text('Live-Vorschau',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (d != null) ...[
                const SizedBox(width: 8),
                Text('${d.width}×${d.height}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const Spacer(),
              IconButton(
                tooltip: _live ? 'Pause' : 'Live',
                icon: Icon(_live ? Icons.pause : Icons.play_arrow, size: 20),
                onPressed: () => setState(() {
                  _live = !_live;
                  if (_live) _tick();
                }),
              ),
              IconButton(
                tooltip: 'Aktualisieren',
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _tick,
              ),
            ]),
            AspectRatio(
              aspectRatio: d == null ? 4.0 : (d.width / d.height),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: d == null
                    ? Center(
                        child: Text(
                          _failed ? 'Vorschau nicht verfügbar' : 'lädt…',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      )
                    : CustomPaint(
                        painter: _MatrixPainter(d.width, d.height, d.pixels),
                        size: Size.infinite,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrixPainter extends CustomPainter {
  final int w;
  final int h;
  final List<int> pixels;
  _MatrixPainter(this.w, this.h, this.pixels);

  @override
  void paint(Canvas canvas, Size size) {
    if (w <= 0 || h <= 0) return;
    final cellW = size.width / w;
    final cellH = size.height / h;
    final cell = cellW < cellH ? cellW : cellH;
    final gap = (cell * 0.12).clamp(0.0, 1.5);
    final radius = Radius.circular(cell * 0.22);
    final paint = Paint()..isAntiAlias = true;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        final v = idx < pixels.length ? pixels[idx] : 0;
        final r = (v >> 16) & 0xFF;
        final g = (v >> 8) & 0xFF;
        final b = v & 0xFF;
        // Dunkle Pixel leicht abheben, damit das Raster sichtbar bleibt.
        paint.color = (v == 0)
            ? const Color(0xFF141414)
            : Color.fromARGB(255, r, g, b);
        final rect = Rect.fromLTWH(
          x * cellW + gap,
          y * cellH + gap,
          cellW - 2 * gap,
          cellH - 2 * gap,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPainter old) =>
      old.w != w || old.h != h || !identical(old.pixels, pixels);
}
