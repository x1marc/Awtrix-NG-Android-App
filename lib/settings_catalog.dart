/// Verständliche Beschreibung der AWTRIX-NG-Einstellungen.
/// Bekannte Schlüssel bekommen deutsches Label + Hilfe + passenden Bedien-Typ.

enum SKind { toggle, slider, number, dropdown, color, colorNullable, text }

class SMeta {
  final String key; // ggf. "eltern.kind" (verschachtelt)
  final String label;
  final String? help;
  final String group;
  final SKind kind;
  final num min;
  final num max;
  final int? divisions;
  final String? unit;
  final Map<String, String>? options; // Wert -> deutsches Label

  const SMeta(
    this.key,
    this.label, {
    required this.group,
    required this.kind,
    this.help,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.unit,
    this.options,
  });
}

// Gruppen in Anzeige-Reihenfolge.
const List<String> kGroupOrder = [
  'Helligkeit & Farbe',
  'Text & Scrollen',
  'App-Wechsel',
  'Uhr',
  'Datum',
  'Wochentagsleiste',
  'Sensoren',
  'Audio',
  'Bedienung',
  'Weitere',
];

const List<SMeta> kSettingsCatalog = [
  // --- Helligkeit & Farbe ---
  SMeta('autoBrightness', 'Automatische Helligkeit',
      group: 'Helligkeit & Farbe',
      kind: SKind.toggle,
      help: 'Passt die Helligkeit automatisch über den Lichtsensor an.'),
  SMeta('brightness', 'Helligkeit',
      group: 'Helligkeit & Farbe',
      kind: SKind.slider,
      min: 0,
      max: 255,
      divisions: 51,
      help: 'Feste Helligkeit (0–255). Wirkt nur, wenn die automatische '
          'Helligkeit aus ist.'),
  SMeta('saturation', 'Farbsättigung',
      group: 'Helligkeit & Farbe',
      kind: SKind.slider,
      min: 0,
      max: 100,
      divisions: 20,
      unit: '%',
      help: '0 = Graustufen, 100 = volle Farbe.'),
  SMeta('gamma', 'Gamma',
      group: 'Helligkeit & Farbe',
      kind: SKind.number,
      help: 'Farbkurve der Anzeige (Standard 1.9). Nur ändern, wenn nötig.'),
  SMeta('textColor', 'Standard-Textfarbe',
      group: 'Helligkeit & Farbe',
      kind: SKind.color,
      help: 'Farbe, in der Texte standardmäßig erscheinen.'),
  SMeta('colorCorrection', 'Farbkorrektur',
      group: 'Helligkeit & Farbe',
      kind: SKind.colorNullable,
      help: 'Feinkorrektur der Panelfarben (fortgeschritten). Leer = aus.'),
  SMeta('colorTint', 'Farbton-Überlagerung',
      group: 'Helligkeit & Farbe',
      kind: SKind.colorNullable,
      help: 'Zusätzlicher Farbschleier über dem Panel (fortgeschritten).'),

  // --- Text & Scrollen ---
  SMeta('uppercase', 'Großbuchstaben',
      group: 'Text & Scrollen',
      kind: SKind.toggle,
      help: 'Wandelt Text von Apps/Benachrichtigungen in GROSSBUCHSTABEN.'),
  SMeta('scroll.mode', 'Scroll-Modus',
      group: 'Text & Scrollen',
      kind: SKind.dropdown,
      help: 'Wie sich zu langer Text bewegt.',
      options: {
        'static': 'Stehend',
        'wrap': 'Umbruch',
        'loop': 'Endlos',
        'bounce': 'Hin & her',
      }),
  SMeta('scroll.direction', 'Scroll-Richtung',
      group: 'Text & Scrollen',
      kind: SKind.dropdown,
      options: {'left': 'Nach links', 'right': 'Nach rechts'}),
  SMeta('scroll.speed', 'Scroll-Tempo',
      group: 'Text & Scrollen',
      kind: SKind.slider,
      min: 0,
      max: 300,
      divisions: 30,
      unit: '%',
      help: 'Geschwindigkeit in Prozent (100 = normal).'),
  SMeta('scroll.entry', 'Text-Einstieg',
      group: 'Text & Scrollen',
      kind: SKind.dropdown,
      options: {'inline': 'Direkt', 'offscreen': 'Von außen herein'}),
  SMeta('scroll.whenFits', 'Wenn Text passt',
      group: 'Text & Scrollen',
      kind: SKind.dropdown,
      options: {'static': 'Nicht scrollen', 'scroll': 'Trotzdem scrollen'}),
  SMeta('scroll.gap', 'Abstand (Endlos)',
      group: 'Text & Scrollen',
      kind: SKind.slider,
      min: 0,
      max: 32,
      divisions: 32,
      unit: 'px',
      help: 'Abstand zwischen den Wiederholungen im Endlos-Modus.'),
  SMeta('scroll.holdMs', 'Pause',
      group: 'Text & Scrollen',
      kind: SKind.slider,
      min: 0,
      max: 5000,
      divisions: 50,
      unit: 'ms',
      help: 'Pause vor/zwischen den Textbewegungen (Millisekunden).'),

  // --- App-Wechsel ---
  SMeta('autoTransition', 'Apps automatisch wechseln',
      group: 'App-Wechsel',
      kind: SKind.toggle,
      help: 'Blättert selbstständig durch die Apps.'),
  SMeta('appDurationMs', 'Anzeigedauer je App',
      group: 'App-Wechsel',
      kind: SKind.slider,
      min: 1000,
      max: 30000,
      divisions: 29,
      unit: 'ms',
      help: 'Wie lange jede App gezeigt wird (7000 = 7 Sekunden).'),
  SMeta('transitionEffect', 'Übergangs-Effekt',
      group: 'App-Wechsel',
      kind: SKind.text,
      help: 'Effekt beim App-Wechsel (z. B. Rain, Fade, Slide). '
          'Verfügbare Namen zeigt die Weboberfläche der Uhr.'),
  SMeta('transitionDurationMs', 'Übergangsdauer',
      group: 'App-Wechsel',
      kind: SKind.slider,
      min: 0,
      max: 5000,
      divisions: 50,
      unit: 'ms',
      help: 'Dauer der Wechsel-Animation (Millisekunden).'),

  // --- Uhr ---
  SMeta('timeMode', 'Uhr-Stil',
      group: 'Uhr',
      kind: SKind.slider,
      min: 0,
      max: 6,
      divisions: 6,
      help: 'Verschiedene Uhr-Layouts (0–6).'),
  SMeta('time24h', '24-Stunden-Format',
      group: 'Uhr',
      kind: SKind.toggle,
      help: 'Aus = 12-Stunden mit AM/PM.'),
  SMeta('timeShowSeconds', 'Sekunden anzeigen',
      group: 'Uhr', kind: SKind.toggle),
  SMeta('timeLeadingZero', 'Führende Null',
      group: 'Uhr',
      kind: SKind.toggle,
      help: 'Zeigt z. B. 09:05 statt 9:05.'),
  SMeta('timeShowAmPm', 'AM/PM anzeigen',
      group: 'Uhr',
      kind: SKind.toggle,
      help: 'Nur im 12-Stunden-Format.'),
  SMeta('timeSeparatorMode', 'Doppelpunkt',
      group: 'Uhr',
      kind: SKind.dropdown,
      options: {'steady': 'Fest', 'blink': 'Blinkend', 'pulse': 'Pulsierend'}),
  SMeta('timeColor', 'Uhr-Farbe',
      group: 'Uhr',
      kind: SKind.colorNullable,
      help: 'Leer = Standard-Textfarbe.'),

  // --- Datum ---
  SMeta('dateOrder', 'Reihenfolge',
      group: 'Datum',
      kind: SKind.dropdown,
      options: {
        'dayMonthYear': 'Tag . Monat . Jahr',
        'monthDayYear': 'Monat / Tag / Jahr',
        'yearMonthDay': 'Jahr - Monat - Tag',
      }),
  SMeta('dateSeparator', 'Trennzeichen',
      group: 'Datum',
      kind: SKind.dropdown,
      options: {'dot': 'Punkt  .', 'slash': 'Schrägstrich  /', 'dash': 'Bindestrich  -'}),
  SMeta('dateYearMode', 'Jahr',
      group: 'Datum',
      kind: SKind.dropdown,
      options: {'none': 'Kein Jahr', 'twoDigit': '2-stellig', 'fourDigit': '4-stellig'}),
  SMeta('dateShowWeekday', 'Wochentag anzeigen',
      group: 'Datum', kind: SKind.toggle),
  SMeta('dateMonthNames', 'Monatsnamen statt Zahlen',
      group: 'Datum', kind: SKind.toggle),
  SMeta('dateColor', 'Datums-Farbe',
      group: 'Datum', kind: SKind.colorNullable, help: 'Leer = Standard-Textfarbe.'),
  SMeta('calendarHeaderColor', 'Kalender – Kopfzeile',
      group: 'Datum', kind: SKind.color),
  SMeta('calendarTextColor', 'Kalender – Tageszahl',
      group: 'Datum', kind: SKind.color),
  SMeta('calendarBodyColor', 'Kalender – Hintergrund',
      group: 'Datum', kind: SKind.color),

  // --- Wochentagsleiste ---
  SMeta('weekdayBar.show', 'Wochentagsleiste anzeigen',
      group: 'Wochentagsleiste', kind: SKind.toggle),
  SMeta('weekdayBar.startOnMonday', 'Woche beginnt Montag',
      group: 'Wochentagsleiste', kind: SKind.toggle),
  SMeta('weekdayBar.activeColor', 'Heute (Werktag)',
      group: 'Wochentagsleiste', kind: SKind.color),
  SMeta('weekdayBar.inactiveColor', 'Andere Werktage',
      group: 'Wochentagsleiste', kind: SKind.color),
  SMeta('weekdayBar.weekendActiveColor', 'Heute (Wochenende)',
      group: 'Wochentagsleiste', kind: SKind.color),
  SMeta('weekdayBar.weekendInactiveColor', 'Andere Wochenendtage',
      group: 'Wochentagsleiste', kind: SKind.color),

  // --- Sensoren ---
  SMeta('useCelsius', 'Temperatur in °C',
      group: 'Sensoren', kind: SKind.toggle, help: 'Aus = °F.'),
  SMeta('temperatureColor', 'Farbe Temperatur',
      group: 'Sensoren', kind: SKind.colorNullable),
  SMeta('humidityColor', 'Farbe Luftfeuchte',
      group: 'Sensoren', kind: SKind.colorNullable),
  SMeta('batteryColor', 'Farbe Batterie',
      group: 'Sensoren', kind: SKind.colorNullable),

  // --- Audio ---
  SMeta('soundEnabled', 'Töne aktiviert',
      group: 'Audio', kind: SKind.toggle, help: 'Schaltet kurze Töne ein/aus.'),
  SMeta('buzzerVolume', 'Lautstärke Summer',
      group: 'Audio', kind: SKind.slider, min: 0, max: 100, divisions: 20, unit: '%'),
  SMeta('mp3Volume', 'Lautstärke MP3',
      group: 'Audio', kind: SKind.slider, min: 0, max: 100, divisions: 20, unit: '%'),
  SMeta('dfplayerVolume', 'Lautstärke DFPlayer',
      group: 'Audio', kind: SKind.slider, min: 0, max: 100, divisions: 20, unit: '%'),
  SMeta('radioVolume', 'Lautstärke Radio',
      group: 'Audio', kind: SKind.slider, min: 0, max: 100, divisions: 20, unit: '%'),
  SMeta('radioMeta', 'Radio-Infos anzeigen',
      group: 'Audio',
      kind: SKind.toggle,
      help: 'Zeigt Sender/Titel während der Wiedergabe.'),

  // --- Bedienung ---
  SMeta('blockNavigation', 'Tasten-Navigation sperren',
      group: 'Bedienung',
      kind: SKind.toggle,
      help: 'Deaktiviert das Blättern über die Geräte-Tasten.'),
];

final Map<String, SMeta> kSettingsByKey = {
  for (final m in kSettingsCatalog) m.key: m,
};

/// Macht aus "someKeyName" / "weekdayBar.x" einen lesbaren Text (Fallback).
String prettifyKey(String key) {
  final last = key.contains('.') ? key.split('.').last : key;
  final spaced = last
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}
