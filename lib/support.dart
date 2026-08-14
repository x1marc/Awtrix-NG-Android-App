import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String kBmcUrl = 'https://buymeacoffee.com/x1marc';

Future<void> openBuyMeACoffee(BuildContext context) async {
  final uri = Uri.parse(kBmcUrl);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Konnte $kBmcUrl nicht öffnen')),
    );
  }
}

/// Kaffee-Icon für die AppBar.
class BmcButton extends StatelessWidget {
  const BmcButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Buy me a coffee',
      icon: const Icon(Icons.coffee),
      onPressed: () => openBuyMeACoffee(context),
    );
  }
}

/// Auffällige Unterstützen-Karte (Startseite/Info).
class BmcCard extends StatelessWidget {
  const BmcCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      color: const Color(0xFFFFDD00),
      child: InkWell(
        onTap: () => openBuyMeACoffee(context),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text('☕', style: TextStyle(fontSize: 26)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gefällt dir die App?',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('Spendier mir einen Kaffee ☕',
                        style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Colors.black54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
