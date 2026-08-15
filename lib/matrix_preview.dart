import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

/// Live-Vorschau des Uhr-Displays: pollt /display/screen in einer schnellen
/// Schleife (~30 FPS) über eine Keep-Alive-Verbindung und zeichnet die Matrix
/// selbst. Pausiert automatisch, wenn [active] false ist (anderer Tab).
class MatrixPreview extends StatefulWidget {
  final AwtrixApi api;
  final ValueListenable<bool>? active;
  const MatrixPreview({super.key, required this.api, this.active});

  @override
  State<MatrixPreview> createState() => _MatrixPreviewState();
}

class _MatrixPreviewState extends State<MatrixPreview>
    with WidgetsBindingObserver {
  final ValueNotifier<ScreenData?> _screen = ValueNotifier(null);
  final http.Client _client = http.Client();
  bool _live = true;
  bool _failed = false;
  bool _running = false;
  bool _appResumed = true;
  double _fps = 0;
  int _frames = 0;
  DateTime _fpsSince = DateTime.now();

  static const _targetMs = 33; // ~30 FPS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.active?.addListener(_onActive);
    _start();
  }

  @override
  void dispose() {
    _running = false;
    widget.active?.removeListener(_onActive);
    WidgetsBinding.instance.removeObserver(this);
    _client.close();
    _screen.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed) _start();
  }

  void _onActive() {
    if (widget.active?.value == true) _start();
  }

  bool get _shouldRun =>
      _live && _appResumed && (widget.active?.value ?? true) && mounted;

  void _start() {
    if (!_running) {
      _running = true;
      _fpsSince = DateTime.now();
      _frames = 0;
      _loop();
    }
  }

  Future<void> _loop() async {
    while (_running && mounted) {
      if (!_shouldRun) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }
      final t = DateTime.now();
      final d = await widget.api.getScreenVia(_client);
      if (!mounted) break;
      if (d != null) {
        _screen.value = d;
        if (_failed) setState(() => _failed = false);
        _frames++;
        final ms = DateTime.now().difference(_fpsSince).inMilliseconds;
        if (ms >= 500) {
          setState(() {
            _fps = _frames * 1000 / ms;
            _frames = 0;
            _fpsSince = DateTime.now();
          });
        }
      } else if (_screen.value == null && !_failed) {
        setState(() => _failed = true);
      }
      final elapsed = DateTime.now().difference(t).inMilliseconds;
      final wait = _targetMs - elapsed;
      if (wait > 0) await Future.delayed(Duration(milliseconds: wait));
    }
    _running = false;
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(width: 8),
              if (_live)
                Text('${_fps.toStringAsFixed(0)} FPS',
                    style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              IconButton(
                tooltip: _live ? 'Pause' : 'Live',
                icon: Icon(_live ? Icons.pause : Icons.play_arrow, size: 20),
                onPressed: () => setState(() {
                  _live = !_live;
                  if (_live) _start();
                }),
              ),
            ]),
            ValueListenableBuilder<ScreenData?>(
              valueListenable: _screen,
              builder: (context, d, _) {
                return AspectRatio(
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
                );
              },
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
        paint.color =
            (v == 0) ? const Color(0xFF141414) : Color.fromARGB(255, r, g, b);
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
