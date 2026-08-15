import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'version.dart';

const String kBmcUrl = 'https://buymeacoffee.com/x1marc';
const String kScriptsUrl = 'https://github.com/x1marc/ha-awtrix-ng-scripts';
const String kBlueprintsUrl = 'https://github.com/x1marc/ha-blueprints';

Future<void> openUrl(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Konnte $url nicht öffnen')));
  }
}

Future<void> openBuyMeACoffee(BuildContext context) => openUrl(context, kBmcUrl);

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

/// Auffällige Unterstützen-Karte (Startseite).
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

/// Bottom-Sheet mit Kaffee-Link + Verweis auf die anderen Projekte.
void showSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Danke, dass du die App nutzt!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Wenn sie dir gefällt, freue ich mich über einen '
                'Kaffee – und schau gern bei meinen anderen Projekten vorbei.'),
            const SizedBox(height: 6),
            Text('Installierte Version: $kAppVersion',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 8),
            const BmcCard(),
            const SizedBox(height: 4),
            const Text('Meine anderen Projekte',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.watch),
              title: const Text('AWTRIX NG – Home-Assistant-Skripte'),
              subtitle: const Text('MQTT-Skripte für AWTRIX NG'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openUrl(ctx, kScriptsUrl),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dashboard_customize),
              title: const Text('Home-Assistant-Blueprints'),
              subtitle: const Text('u. a. „Sensor → AWTRIX NG App"'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openUrl(ctx, kBlueprintsUrl),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Schließen'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Zeigt den Unterstützen-Hinweis „hin und wieder" (nicht öfter als alle 3 Tage,
/// und erst nach ein paar App-Starts).
Future<void> maybeShowSupportSheet(BuildContext context) async {
  final p = await SharedPreferences.getInstance();
  final opens = (p.getInt('app_opens') ?? 0) + 1;
  await p.setInt('app_opens', opens);

  final last = p.getInt('support_last_shown') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  const threeDays = 3 * 24 * 60 * 60 * 1000;

  if (last == 0) {
    if (opens < 3) return; // am Anfang nicht sofort nerven
  } else if (now - last < threeDays) {
    return;
  }

  await p.setInt('support_last_shown', now);
  if (context.mounted) showSupportSheet(context);
}
