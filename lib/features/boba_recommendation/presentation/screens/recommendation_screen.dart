import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/drink.dart';
import '../../domain/entities/recommendation.dart';
import '../bloc/recommendation_bloc.dart';
import '../bloc/recommendation_event.dart';
import '../bloc/recommendation_state.dart';
import '../widgets/loading_animation.dart';
import '../widgets/topping_card.dart';

class RecommendationScreen extends StatefulWidget {
  final Drink drink;

  const RecommendationScreen({
    super.key,
    required this.drink,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  @override
  void initState() {
    super.initState();
    // Request recommendations
    context.read<RecommendationBloc>().add(
          GetRecommendationsEvent(widget.drink),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Recommended Toppings'),
        actions: [
          BlocBuilder<RecommendationBloc, RecommendationState>(
            builder: (context, state) {
              if (state is RecommendationsLoadedState) {
                return IconButton(
                  icon: Icon(
                    state.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: state.isSaved ? AppTheme.primaryColor : null,
                  ),
                  onPressed: () {
                    context.read<RecommendationBloc>().add(
                          const SaveRecommendationEvent(),
                        );
                  },
                  tooltip: 'Save recommendation',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<RecommendationBloc, RecommendationState>(
        builder: (context, state) {
          if (state is LoadingRecommendationsState) {
            return const LoadingAnimation(
              message: 'Finding the perfect toppings for your drink...',
            );
          } else if (state is RecommendationsLoadedState) {
            final recommendation = state.recommendation;
            return _buildRecommendationContent(recommendation);
          } else if (state is ErrorState) {
            return _buildErrorContent(state.message);
          }

          return const Center(
            child: Text('Something went wrong. Please try again.'),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationContent(Recommendation recommendation) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drink Information
            _buildDrinkHeader(),
            const SizedBox(height: 24),

            // Rationale
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recommendation Rationale',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.recommendationRationale,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Toppings
            Text(
              'Recommended Toppings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendation.toppings.length,
              itemBuilder: (context, index) {
                final topping = recommendation.toppings[index];
                return ToppingCard(topping: topping);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinkHeader() {
    final Color drinkColor = _getDrinkColor();
    // Darken the drink color for better text contrast
    final Color darkDrinkColor = HSLColor.fromColor(drinkColor)
        .withLightness(
            (HSLColor.fromColor(drinkColor).lightness * 0.7).clamp(0.0, 1.0))
        .toColor();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: darkDrinkColor, // Use the darker color
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.drink.name,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients
            if (widget.drink.ingredients != null) ...[
              Text(
                'Ingredients:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0.5, 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.drink.ingredients!.join(', '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 12),
            ],

            // Base
            if (widget.drink.base != null) ...[
              Row(
                children: [
                  Text(
                    'Base: ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.drink.base!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Flavor and Texture
            Row(
              children: [
                if (widget.drink.flavor != null)
                  Expanded(
                    child: _buildAttributeChips(
                      'Flavor',
                      widget.drink.flavor!,
                    ),
                  ),
                if (widget.drink.flavor != null && widget.drink.texture != null)
                  const SizedBox(width: 12),
                if (widget.drink.texture != null)
                  Expanded(
                    child: _buildAttributeChips(
                      'Texture',
                      widget.drink.texture!,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeChips(String title, Map<String, double> attributes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: attributes.entries
              .map(
                (entry) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    '${entry.key}: ${(entry.value * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDrinkColor() {
    final base = widget.drink.base?.toLowerCase() ?? '';

    if (base.contains('matcha') || base.contains('green')) {
      return AppTheme.matchaColor;
    } else if (base.contains('taro')) {
      return AppTheme.tarodColor;
    } else if (base.contains('coffee')) {
      return AppTheme.coffeeColor;
    } else if (base.contains('milk')) {
      return AppTheme.milkTeaColor;
    } else {
      return AppTheme.primaryColor;
    }
  }
}
