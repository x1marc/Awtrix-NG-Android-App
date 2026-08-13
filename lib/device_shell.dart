import 'package:flutter/material.dart';

import 'api.dart';
import 'apps_page.dart';
import 'control_page.dart';
import 'main.dart' show ThemeToggleButton;
import 'settings_page.dart';
import 'system_page.dart';

class DeviceShell extends StatefulWidget {
  final AwtrixDevice device;
  const DeviceShell({super.key, required this.device});

  @override
  State<DeviceShell> createState() => _DeviceShellState();
}

class _DeviceShellState extends State<DeviceShell> {
  int _i = 0;

  late final List<Widget> _pages = [
    ControlPage(device: widget.device),
    AppsPage(device: widget.device),
    SettingsPage(device: widget.device),
    SystemPage(device: widget.device),
  ];

  static const _labels = ['Steuern', 'Apps', 'Einstellungen', 'System'];
  static const _icons = [Icons.tune, Icons.apps, Icons.settings, Icons.dns];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final content = IndexedStack(index: _i, children: _pages);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.name}  ·  ${_labels[_i]}'),
        actions: const [ThemeToggleButton()],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _i,
                  onDestinationSelected: (v) => setState(() => _i = v),
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
              onDestinationSelected: (v) => setState(() => _i = v),
              destinations: [
                for (var k = 0; k < _labels.length; k++)
                  NavigationDestination(icon: Icon(_icons[k]), label: _labels[k]),
              ],
            ),
    );
  }
}
