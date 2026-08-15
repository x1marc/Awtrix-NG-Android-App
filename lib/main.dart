import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

/// Globales Theme (Hell/Dunkel/System), persistent.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

const _themeKey = 'theme_mode';

Future<void> _loadTheme() async {
  final p = await SharedPreferences.getInstance();
  switch (p.getString(_themeKey)) {
    case 'light':
      themeModeNotifier.value = ThemeMode.light;
      break;
    case 'dark':
      themeModeNotifier.value = ThemeMode.dark;
      break;
    default:
      themeModeNotifier.value = ThemeMode.system;
  }
}

Future<void> setThemeMode(ThemeMode m) async {
  themeModeNotifier.value = m;
  final p = await SharedPreferences.getInstance();
  await p.setString(_themeKey, m.name);
}

/// Button zum Durchschalten System -> Hell -> Dunkel.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        final (icon, tip, next) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto, 'Design: System', ThemeMode.light),
          ThemeMode.light => (Icons.light_mode, 'Design: Hell', ThemeMode.dark),
          ThemeMode.dark => (Icons.dark_mode, 'Design: Dunkel', ThemeMode.system),
        };
        return IconButton(
          tooltip: tip,
          icon: Icon(icon),
          onPressed: () => setThemeMode(next),
        );
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadTheme();
  runApp(const AwtrixApp());
}

class AwtrixApp extends StatelessWidget {
  const AwtrixApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    // WICHTIG: DECKENDE Füllfarbe. Eine transparente/fehlende Füllung ließ
    // auf MIUI/HyperOS die graue Karten-/System-Farbe durchscheinen -> Felder
    // sahen grau/deaktiviert aus. Eine opake Farbe übermalt das komplett.
    final fieldFill = dark ? const Color(0xFF15151B) : Colors.white;
    final fieldBorder = dark ? Colors.white24 : Colors.black26;
    OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorSchemeSeed: const Color(0xFFFFC107), // AWTRIX-Gelb
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        isDense: true,
        border: ob(fieldBorder),
        enabledBorder: ob(fieldBorder),
        focusedBorder: ob(const Color(0xFFFFC107), 2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Awtrix NG App',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const HomePage(),
        );
      },
    );
  }
}
