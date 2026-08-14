# AWTRIX NG Remote

Eine kleine **Android-App**, um eine **[AWTRIX NG](https://blueforcer.github.io/awtrix-ng/)**-Uhr
**lokal im WLAN** zu steuern und einzustellen – ganz ohne Cloud, ohne MQTT-Broker.
Die App spricht direkt die lokale **HTTP-API** der Uhr (`/api/v1/…`).

<p align="center">
  <b>☕ Gefällt dir dieses Projekt? Dann spendier mir gern einen Kaffee!</b><br><br>
  <a href="https://buymeacoffee.com/x1marc"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60"></a>
</p>

## Funktionen
- 🔎 **Uhr automatisch finden** im WLAN (UDP-Broadcast `FIND_AWTRIXNG`) **oder per IP/Hostname** hinzufügen
- 🔔 **Benachrichtigungen** senden (Text + Farbe) und wegwischen
- ◀ ▶ **Apps** vor/zurück blättern
- 🖥️ **Display**: an/aus, **Helligkeit**, Wetter-**Overlay** (Regen/Schnee/…)
- 💡 **Stimmungslicht** (Moodlight) in Farbe / aus
- 🚦 **Status-LEDs** (1–3) setzen/aus
- ⚙️ **Auto-Helligkeit**, **Neustart**
- 💾 Mehrere Uhren werden gespeichert

## APK herunterladen & installieren
Es ist **kein** Android-Studio/Flutter nötig – die APK wird von GitHub automatisch gebaut.

1. **APK holen:** unter [**Releases → „latest"**](../../releases/latest) die
   `app-release.apk` herunterladen (oder aus dem jeweiligen
   [Actions-Lauf](../../actions) unter *Artifacts*).
2. Auf dem Handy öffnen, **„Installieren aus unbekannter Quelle" erlauben**, installieren.
3. Fertig – Handy und Uhr müssen im **gleichen WLAN** sein.

> Die APK ist mit dem Debug-Schlüssel signiert (für private Nutzung/Sideloading völlig ok,
> nur nicht für den Play Store).

### Automatische Updates via Obtainium (empfohlen)
[Obtainium](https://github.com/ImranR98/Obtainium) installiert die App direkt aus
diesem GitHub-Repo und **hält sie automatisch aktuell** – ohne Google Play, ohne Konto.

1. **Obtainium** installieren (aus dem
   [Obtainium-Release](https://github.com/ImranR98/Obtainium/releases) oder F-Droid).
2. In Obtainium **„App hinzufügen"** → diese URL einfügen:
   ```
   https://github.com/x1marc/awtrix-ng-remote
   ```
3. Installieren. Bei jedem neuen Build (höhere Versionsnummer) bietet Obtainium das Update an.

## Benutzen
1. App öffnen → **„Uhr suchen"** (findet Uhren im WLAN) **oder** oben **+** für IP/Hostname
   (z. B. `192.168.1.50` oder `awtrixng-a1b2c3.local`).
2. Uhr antippen → steuern.

## Voraussetzungen
- Uhr mit **AWTRIX-NG-Firmware** (nicht AWTRIX 3)
- Handy + Uhr im **gleichen lokalen Netzwerk**
- HTTP-API der Uhr erreichbar (Standard: Port 80, Basic-Auth aus)

## Technik
- **Flutter** (Dart), Abhängigkeiten nur `http` + `shared_preferences`
- Discovery: `dart:io` `RawDatagramSocket` (UDP-Broadcast an `:4210`, Antwort auf `:4211`)
- Der komplette App-Code liegt in [`lib/`](lib); das Android-Projektgerüst wird im
  CI-Build per `flutter create` erzeugt (siehe [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml)).

## Verwandte Projekte
- [ha-awtrix-ng-scripts](https://github.com/x1marc/ha-awtrix-ng-scripts) – HA-Skripte für AWTRIX NG
- [ha-blueprints](https://github.com/x1marc/ha-blueprints) – u. a. „Sensor → AWTRIX NG App"

## Lizenz
MIT
