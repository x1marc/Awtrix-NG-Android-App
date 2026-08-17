import 'package:flutter/material.dart';

import 'api.dart';
import 'apps_page.dart';
import 'control_page.dart';
import 'icons_page.dart';
import 'l10n.dart';
import 'main.dart' show LanguageButton, ThemeToggleButton;
import 'settings_page.dart';
import 'support.dart';
import 'system_page.dart';

class DeviceShell extends StatefulWidget {
  final AwtrixDevice device;
  const DeviceShell({super.key, required this.device});

  @override
  State<DeviceShell> createState() => _DeviceShellState();
}

class _DeviceShellState extends State<DeviceShell> {
  int _i = 0;
  final ValueNotifier<bool> _controlActive = ValueNotifier(true);

  late final List<Widget> _pages = [
    ControlPage(device: widget.device, active: _controlActive),
    AppsPage(device: widget.device),
    IconsPage(device: widget.device),
    SettingsPage(device: widget.device),
    SystemPage(device: widget.device),
  ];

  @override
  void dispose() {
    _controlActive.dispose();
    super.dispose();
  }

  void _select(int v) {
    setState(() => _i = v);
    _controlActive.value = v == 0;
  }

  List<String> get _labels => [
        tr('nav_control'),
        tr('nav_apps'),
        tr('nav_icons'),
        tr('nav_settings'),
        tr('nav_system'),
      ];
  static const _icons = [
    Icons.tune,
    Icons.apps,
    Icons.image,
    Icons.settings,
    Icons.dns,
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final content = IndexedStack(index: _i, children: _pages);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.name}  ·  ${_labels[_i]}'),
        actions: const [BmcButton(), LanguageButton(), ThemeToggleButton()],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _i,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (var k = 0; k < _labels.length; k++)
                      NavigationRailDestination(
                        icon: Icon(_icons[k]),
                        label: Text(_labels[k]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _i,
              onDestinationSelected: _select,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (var k = 0; k < _labels.length; k++)
                  NavigationDestination(icon: Icon(_icons[k]), label: _labels[k]),
              ],
            ),
    );
  }
}
