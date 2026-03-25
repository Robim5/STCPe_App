import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/settings_modal.dart';
import '../widgets/info_modal.dart';
import 'mainscreens/home_screen.dart';
import 'mainscreens/stcp_screen.dart';
import 'mainscreens/metro_screen.dart';
import 'mainscreens/favorites_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    StcpScreen(),
    MetroScreen(),
    FavoritesScreen(),
  ];

  void _toggleTheme() {
    final current = themeNotifier.value;
    final brightness = Theme.of(context).brightness;

    if (current == ThemeMode.system) {
      // if system, toggle based on current brightness
      themeNotifier.value =
          brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      themeNotifier.value =
          current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LocaTe',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showInfoModal(context),
          ),
          IconButton(
            icon: Icon(isDark
                ? Icons.wb_sunny_rounded
                : Icons.nightlight_round),
            onPressed: _toggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus_rounded),
            label: 'STCP',
          ),
          NavigationDestination(
            icon: Icon(Icons.subway_outlined),
            selectedIcon: Icon(Icons.subway_rounded),
            label: 'Metro',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
