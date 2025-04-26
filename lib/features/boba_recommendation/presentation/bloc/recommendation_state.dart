import 'package:equatable/equatable.dart';

import '../../domain/entities/drink.dart';
import '../../domain/entities/recommendation.dart';

abstract class RecommendationState extends Equatable {
  const RecommendationState();

  @override
  List<Object?> get props => [];
}

class InitialState extends RecommendationState {
  const InitialState();
}

// Analysis States
class AnalyzingDrinkState extends RecommendationState {
  final String drinkName;

  const AnalyzingDrinkState(this.drinkName);

  @override
  List<Object> get props => [drinkName];
}

class DrinkAnalyzedState extends RecommendationState {
  final Drink drink;

  const DrinkAnalyzedState(this.drink);

  @override
  List<Object> get props => [drink];
}

// Recommendation States
class LoadingRecommendationsState extends RecommendationState {
  final Drink drink;

  const LoadingRecommendationsState(this.drink);

  @override
  List<Object> get props => [drink];
}

class RecommendationsLoadedState extends RecommendationState {
  final Recommendation recommendation;
  final bool isSaved;

  const RecommendationsLoadedState(this.recommendation, {this.isSaved = false});

  @override
  List<Object> get props => [recommendation, isSaved];

  RecommendationsLoadedState copyWith({
    Recommendation? recommendation,
    bool? isSaved,
  }) {
    return RecommendationsLoadedState(
      recommendation ?? this.recommendation,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

// Past Recommendations States
class LoadingPastRecommendationsState extends RecommendationState {
  const LoadingPastRecommendationsState();
}

class PastRecommendationsLoadedState extends RecommendationState {
  final List<Recommendation> recommendations;

  const PastRecommendationsLoadedState(this.recommendations);

  @override
  List<Object> get props => [recommendations];
}

// Error States
class ErrorState extends RecommendationState {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object> get props => [message];
}
