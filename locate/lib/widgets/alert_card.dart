import 'package:flutter/material.dart';
import '../models/arrival_alert.dart';

class AlertCard extends StatelessWidget {
  final ArrivalAlert alert;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMetro = alert.type == 'metro';
    final accent =
        isMetro ? const Color(0xFF2E7D32) : theme.colorScheme.primary;

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(40)),
        ),
        child: Row(
          children: [
            // Type badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isMetro
                    ? Icons.subway_rounded
                    : Icons.directions_bus_rounded,
                size: 22,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.displayLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12,
                          color:
                              theme.colorScheme.onSurface.withAlpha(120)),
                      const SizedBox(width: 4),
                      Text(
                        alert.timeRange,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              theme.colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                      if (alert.direction != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurface
                                .withAlpha(100)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            alert.direction!,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withAlpha(120),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  size: 18,
                  onTap: onEdit,
                  theme: theme,
                ),
                const SizedBox(height: 2),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  size: 18,
                  onTap: onDelete,
                  theme: theme,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.theme,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: size,
          color: color ?? theme.colorScheme.onSurface.withAlpha(140),
        ),
      ),
    );
  }
}
