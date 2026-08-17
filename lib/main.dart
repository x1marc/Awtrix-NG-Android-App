import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'l10n.dart';

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
          ThemeMode.system =>
            (Icons.brightness_auto, tr('theme_system'), ThemeMode.light),
          ThemeMode.light =>
            (Icons.light_mode, tr('theme_light'), ThemeMode.dark),
          ThemeMode.dark =>
            (Icons.dark_mode, tr('theme_dark'), ThemeMode.system),
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

/// Button zum Umschalten der Sprache (System / Deutsch / English).
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (context, loc, _) {
        return PopupMenuButton<String>(
          tooltip: tr('language'),
          icon: const Icon(Icons.translate),
          onSelected: (v) => setLocale(v == 'sys' ? null : Locale(v)),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
                value: 'sys',
                checked: loc == null,
                child: Text(tr('lang_system'))),
            CheckedPopupMenuItem(
                value: 'de',
                checked: loc?.languageCode == 'de',
                child: Text(tr('lang_de'))),
            CheckedPopupMenuItem(
                value: 'en',
                checked: loc?.languageCode == 'en',
                child: Text(tr('lang_en'))),
          ],
        );
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadTheme();
  await loadLocale();
  runApp(const AwtrixApp());
}

class AwtrixApp extends StatelessWidget {
  const AwtrixApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final fieldBorder = dark ? Colors.white24 : Colors.black26;
    OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorSchemeSeed: const Color(0xFFFFC107), // AWTRIX-Gelb
      // WICHTIG: filled:false. Eine GEFÜLLTE Dekoration zeigt auf MIUI/HyperOS
      // das Material-3-Grau (auch bei gesetzter Füllfarbe). Nur Umrandung,
      // keine Füllung -> kein Grau. (Bewährter Fix aus Build #4.)
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
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
        return ValueListenableBuilder<Locale?>(
          valueListenable: localeNotifier,
          builder: (context, locale, __) {
            return MaterialApp(
              title: 'Awtrix NG App',
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: _theme(Brightness.light),
              darkTheme: _theme(Brightness.dark),
              locale: locale,
              supportedLocales: kSupportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const HomePage(),
            );
          },
        );
      },
    );
  }
}
