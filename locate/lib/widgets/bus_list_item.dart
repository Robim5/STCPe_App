import 'package:flutter/material.dart';
import '../models/bus_line.dart';

class BusListItem extends StatelessWidget {
  final BusLine busLine;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const BusListItem({
    super.key,
    required this.busLine,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // line badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: busLine.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    busLine.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // route info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busLine.routeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: busLine.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        busLine.municipality,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: busLine.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // favorite button
              IconButton(
                onPressed: onFavoriteToggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    busLine.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(busLine.isFavorite),
                    color: busLine.isFavorite
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface.withAlpha(77),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
