import 'package:equatable/equatable.dart';

import '../../domain/entities/drink.dart';

abstract class RecommendationEvent extends Equatable {
  const RecommendationEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeDrinkEvent extends RecommendationEvent {
  final String drinkName;

  const AnalyzeDrinkEvent(this.drinkName);

  @override
  List<Object> get props => [drinkName];
}

class GetRecommendationsEvent extends RecommendationEvent {
  final Drink drink;

  const GetRecommendationsEvent(this.drink);

  @override
  List<Object> get props => [drink];
}

class SaveRecommendationEvent extends RecommendationEvent {
  final bool shouldSave;

  const SaveRecommendationEvent({this.shouldSave = true});

  @override
  List<Object> get props => [shouldSave];
}

class LoadPastRecommendationsEvent extends RecommendationEvent {
  const LoadPastRecommendationsEvent();
}

class ResetEvent extends RecommendationEvent {
  const ResetEvent();
}
