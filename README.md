# AWTRIX NG Android App

Eine **Android-App**, um eine **[AWTRIX NG](https://blueforcer.github.io/awtrix-ng/)**-Uhr
**lokal im WLAN** zu steuern und komplett einzustellen – ganz ohne Cloud und ohne
MQTT-Broker. Die App spricht direkt die lokale **HTTP-API** der Uhr (`/api/v1/…`).

<p align="center">
  <b>☕ Gefällt dir dieses Projekt? Dann spendier mir gern einen Kaffee!</b><br><br>
  <a href="https://buymeacoffee.com/x1marc"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60"></a>
</p>

---

## ✨ Funktionen

### Verbinden
- 🔎 **Uhr automatisch finden** im WLAN (UDP-Broadcast `FIND_AWTRIXNG`) **oder per IP/Hostname**
- 🔐 **Login (Basic Auth):** Benutzer + Passwort pro Uhr hinterlegen, falls der Webserver
  der Uhr geschützt ist (in der Liste auf **✏️** tippen)
- 💾 Mehrere Uhren werden gespeichert; **„An alle senden"** verschickt eine Nachricht an alle

### Steuern
- 🔔 **Benachrichtigungs-Composer:** Text, Farbe, **Icon** (Auswahl von der Uhr),
  Effekte (Regenbogen, Blinken, Ein-/Ausblenden, Halten, Aufwecken, Stapeln),
  **Anzeigedauer**, **Scroll-Tempo**, **Fortschrittsbalken**, **Sound (RTTTL)** und **Vorlagen**
- 🖥️ **Display:** an/aus, **Helligkeit**, Wetter-**Overlay** (Regen/Schnee/…)
- 💡 **Stimmungslicht** inkl. **Favoriten-Farben**
- 🚦 **Status-LEDs** (1–3) in beliebiger Farbe setzen/aus
- 📊 **Sensor-Karte:** Temperatur, Luftfeuchte, Helligkeit, Akku, freier RAM

### Apps & Kreatives
- ◀ ▶ **Apps** blättern, **aktivieren/deaktivieren, sortieren (ziehen), löschen**
- 🧩 **Eigene App bauen:** dauerhafte App mit Text, Icon, Farbe, Regenbogen, Dauer, Tempo
- 🎨 **Pixel-Editor:** direkt auf der 8×32-Matrix malen und als App speichern oder kurz anzeigen
- 🖼️ **Icons:** gespeicherte Icons verwalten, **LaMetric-Galerie direkt in der App
  durchsuchen** und per Tipp auf die Uhr laden (oder per ID mit Live-Vorschau), Speicherbelegung

### Einstellungen & System
- ⚙️ **Alle Einstellungen** mit verständlichen Texten, Reglern, Farbwählern und **Suche**
- 🛠️ **System-/Hardware-Konfiguration** (WLAN, MQTT, Zeit, Panel, GPIO … inkl. Passwörter)
- 💾 **Backup & Wiederherstellen** (alle Einstellungen + System als JSON)
- 🔄 **Neustart / Werksreset**

### App selbst
- 🌗 **Hell-/Dunkel-/Systemdesign**, responsive (Handy & Tablet)
- 📺 **Live-Vorschau** des Displays (~30 fps)
- ❓ **Hilfe**-Dialog, Versionsanzeige, Verweis auf verwandte Projekte

---

## 📥 Installieren

Es ist **kein** Android-Studio/Flutter nötig – die APK wird von GitHub automatisch gebaut
und mit einem **festen Schlüssel signiert**, sodass **Updates sauber durchlaufen**.

### Automatische Updates via Obtainium (empfohlen)
[Obtainium](https://github.com/ImranR98/Obtainium) installiert die App direkt aus diesem
Repo und **hält sie automatisch aktuell** – ohne Google Play, ohne Konto.

1. **Obtainium** installieren (aus dem [Release](https://github.com/ImranR98/Obtainium/releases) oder F-Droid).
2. **„App hinzufügen"** → diese URL einfügen:
   ```
   https://github.com/x1marc/Awtrix-NG-Android-App
   ```
3. Installieren. Neue Builds werden automatisch als Update angeboten.

### Manuell
Unter [**Releases**](../../releases/latest) die `app-release.apk` laden, auf dem Handy öffnen,
**„Installieren aus unbekannter Quelle" erlauben**, installieren.

> **Hinweis:** Alle Versionen sind mit demselben Schlüssel signiert. Falls du noch eine
> ältere, anders signierte Version drauf hast, **einmalig deinstallieren** und neu installieren –
> danach laufen Updates automatisch.

---

## 🚀 Benutzen
1. App öffnen → **„Uhr suchen"** (findet Uhren im WLAN) **oder** oben **+** für IP/Hostname
   (z. B. `192.168.1.50` oder `awtrixng-a1b2c3.local`).
2. Verlangt die Uhr einen Login: in der Liste auf **✏️** → Benutzer/Passwort eintragen.
3. Uhr antippen → steuern, Apps, Icons, Einstellungen, System.

## ✅ Voraussetzungen
- Uhr mit **AWTRIX-NG-Firmware** (nicht AWTRIX 3)
- Handy + Uhr im **gleichen lokalen Netzwerk**
- HTTP-API der Uhr erreichbar (Standard: Port 80)

---

## 🧱 Technik
- **Flutter** (Dart); Abhängigkeiten: `http`, `shared_preferences`, `url_launcher`
- Discovery: `dart:io` `RawDatagramSocket` (UDP-Broadcast an `:4210`, Antwort auf `:4211`)
- Der komplette App-Code liegt in [`lib/`](lib); das Android-Projektgerüst wird im
  CI-Build per `flutter create` erzeugt (siehe [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml)).
- **Signatur:** Die CI signiert jede APK nach dem Build mit einem festen Keystore
  (GitHub-Secrets), damit Updates stabil bleiben.

### Selbst bauen
Kein lokales SDK nötig – Push auf `main` löst den Build aus. Lokal (mit Flutter):
```bash
flutter create --platforms=android --project-name awtrix_ng_remote --org com.x1marc .
git checkout -- pubspec.yaml lib
flutter pub get
flutter build apk --release
```

---

## 🔗 Verwandte Projekte
- [ha-awtrix-ng-scripts](https://github.com/x1marc/ha-awtrix-ng-scripts) – Home-Assistant-Skripte für AWTRIX NG
- [ha-blueprints](https://github.com/x1marc/ha-blueprints) – u. a. „Sensor → AWTRIX NG App"

## 📄 Lizenz
MIT
