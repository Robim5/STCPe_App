import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BentoFavorites extends StatelessWidget {
  const BentoFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 150,
      child: Row(
        children: [
          // bus card left
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppTheme.darkDark, AppTheme.darkMedium]
                      : [AppTheme.lightDark, AppTheme.lightMedium],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.darkDark : AppTheme.lightDark)
                        .withAlpha(77),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.directions_bus_rounded,
                      size: 110,
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber[300], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Favorito',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '600',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Av. Aliados \u2194 Barca',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // right two cards
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _StopCard(
                    icon: Icons.shopping_bag_outlined,
                    name: 'F\u00f3rum Maia',
                    waitTime: '8 min',
                    theme: theme,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _StopCard(
                    icon: Icons.location_city_rounded,
                    name: 'Aliados',
                    waitTime: '3 min',
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String waitTime;
  final ThemeData theme;

  const _StopCard({
    required this.icon,
    required this.name,
    required this.waitTime,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(51),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(128),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              waitTime,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
