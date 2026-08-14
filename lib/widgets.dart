import 'package:flutter/material.dart';

/// Vordefinierte Farben (RGB) für Text/Moodlight/LEDs.
const Map<String, List<int>> kColors = {
  'Weiß': [255, 255, 255],
  'Rot': [255, 0, 0],
  'Grün': [0, 255, 0],
  'Blau': [0, 80, 255],
  'Gelb': [255, 200, 0],
  'Warmweiß': [255, 160, 60],
};

Color rgb(List<int> c) =>
    Color.fromARGB(255, c.elementAt(0), c.elementAt(1), c.elementAt(2));

void snack(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1300)),
  );
}

/// Live-Vorschau des Uhr-Displays (best effort über /api/v1/display/screen).
/// Zeigt bei nicht unterstütztem Format sauber einen Hinweis.
class MatrixPreview extends StatefulWidget {
  final String baseUrl; // http://ip[:port]
  const MatrixPreview({super.key, required this.baseUrl});

  @override
  State<MatrixPreview> createState() => _MatrixPreviewState();
}

class _MatrixPreviewState extends State<MatrixPreview> {
  int _t = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    final url = '${widget.baseUrl}/api/v1/display/screen?t=$_t';
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Aktualisieren',
                onPressed: () => setState(
                    () => _t = DateTime.now().millisecondsSinceEpoch),
              ),
            ]),
            AspectRatio(
              aspectRatio: 32 / 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  gaplessPlayback: true,
                  errorBuilder: (c, e, s) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Live-Vorschau nicht verfügbar',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  ),
                  loadingBuilder: (c, w, p) => p == null
                      ? w
                      : const Center(
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fehleranzeige mit „Erneut versuchen".
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Einheitliche Abschnitts-Karte mit Titelzeile.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: cs.primary),
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
}
