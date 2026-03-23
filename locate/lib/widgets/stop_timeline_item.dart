import 'package:flutter/material.dart';

class StopTimelineItem extends StatelessWidget {
  // stop display name
  final String stopName;
  // line color values
  final Color lineColor;
  // first stop indicator
  final bool isFirst;
  // last stop indicator
  final bool isLast;
  final VoidCallback onTap;

  const StopTimelineItem({
    super.key,
    required this.stopName,
    required this.lineColor,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // line timeline column
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // top connector
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isFirst
                          ? Colors.transparent
                          : lineColor.withAlpha(64),
                    ),
                  ),
                  // dot
                  Container(
                    width: isFirst || isLast ? 20 : 14,
                    height: isFirst || isLast ? 20 : 14,
                    decoration: BoxDecoration(
                      color: isFirst || isLast ? lineColor : theme.cardTheme.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: lineColor,
                        width: isFirst || isLast ? 3 : 2.5,
                      ),
                      boxShadow: isFirst
                          ? [
                              BoxShadow(
                                color: lineColor.withAlpha(77),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isFirst
                        ? Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // bottom connector
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isLast
                          ? Colors.transparent
                          : lineColor.withAlpha(64),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // stop card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: isFirst || isLast
                      ? Border.all(
                          color: lineColor.withAlpha(100), width: 1.5)
                      : Border.all(
                          color: theme.colorScheme.outline.withAlpha(26)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stopName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isFirst || isLast
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (isFirst) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Partida',
                              style: TextStyle(
                                fontSize: 11,
                                color: lineColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else if (isLast) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Chegada',
                              style: TextStyle(
                                fontSize: 11,
                                color: lineColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lineColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: lineColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withAlpha(77),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
