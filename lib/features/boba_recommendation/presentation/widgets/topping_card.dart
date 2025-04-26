import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/topping.dart';

class ToppingCard extends StatelessWidget {
  final Topping topping;
  final double scale;

  const ToppingCard({
    super.key,
    required this.topping,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and category
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name and category
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(topping.category),
                        color: _getCategoryColor(topping.category),
                        size: 28 * scale,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          topping.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(topping.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    topping.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getCategoryColor(topping.category),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Compatibility Score
            _buildCompatibilityBar(context),

            const SizedBox(height: 12),

            // Description
            Text(
              topping.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatibility: ${(topping.compatibilityScore * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Foreground
            LayoutBuilder(builder: (context, constraints) {
              return Container(
                height: 8,
                width: constraints.maxWidth * topping.compatibilityScore,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pearls':
        return Colors.brown;
      case 'Jellies':
        return Colors.green;
      case 'Puddings':
        return Colors.orange;
      case 'Beans':
        return Colors.redAccent;
      case 'Fruits':
        return Colors.purpleAccent;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pearls':
        return Icons.circle;
      case 'Jellies':
        return Icons.waves;
      case 'Puddings':
        return Icons.cake;
      case 'Beans':
        return Icons.grain;
      case 'Fruits':
        return Icons.apple;
      default:
        return Icons.category;
    }
  }
}
