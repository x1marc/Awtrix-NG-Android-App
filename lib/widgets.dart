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

/// Eingabefeld OHNE Material-InputDecorator. Dessen "input area" rendert auf
/// manchen Geräten (MIUI/HyperOS) einen grauen Balken – unabhängig von
/// `filled`. Hier kommt der Rahmen vom Container, das Feld selbst ist
/// `InputDecoration.collapsed` (kein Decorator) -> garantiert kein Grau.
class PlainField extends StatefulWidget {
  final Key? fieldKey;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextAlign textAlign;
  const PlainField({
    super.key,
    this.fieldKey,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.hint,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
  });

  @override
  State<PlainField> createState() => _PlainFieldState();
}

class _PlainFieldState extends State<PlainField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final focused = _focus.hasFocus;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: focused ? const Color(0xFFFFC107) : cs.outline,
          width: focused ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: widget.fieldKey,
              controller: widget.controller,
              initialValue:
                  widget.controller == null ? widget.initialValue : null,
              focusNode: _focus,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              textAlign: widget.textAlign,
              style: TextStyle(color: cs.onSurface, fontSize: 15),
              decoration: InputDecoration.collapsed(hintText: widget.hint),
            ),
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: 6),
            Text(widget.suffix!, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ],
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
