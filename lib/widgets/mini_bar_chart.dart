import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Data: [isHealthy, heightFraction]
    const bars = [
      (true, 0.6),
      (true, 0.8),
      (false, 0.4),
      (true, 1.0),
      (false, 0.3),
      (true, 0.7),
      (false, 0.55),
    ];

    return SizedBox(
      height: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: FractionallySizedBox(
                heightFactor: bar.$2,
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: bar.$1
                        ? AppTheme.primaryGreen
                        : AppTheme.tomatoRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
