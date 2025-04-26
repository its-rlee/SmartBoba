import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/recommendation.dart';
import '../../domain/repositories/boba_repository.dart';
import '../../domain/usecases/analyze_drink_usecase.dart';
import '../../domain/usecases/get_topping_recommendations_usecase.dart';
import 'recommendation_event.dart';
import 'recommendation_state.dart';

class RecommendationBloc
    extends Bloc<RecommendationEvent, RecommendationState> {
  final AnalyzeDrinkUseCase analyzeDrinkUseCase;
  final GetToppingRecommendationsUseCase getToppingRecommendationsUseCase;
  final BobaRepository repository;
  Recommendation? _currentRecommendation;

  RecommendationBloc({
    required this.analyzeDrinkUseCase,
    required this.getToppingRecommendationsUseCase,
    required this.repository,
  }) : super(const InitialState()) {
    on<AnalyzeDrinkEvent>(_onAnalyzeDrink);
    on<GetRecommendationsEvent>(_onGetRecommendations);
    on<SaveRecommendationEvent>(_onSaveRecommendation);
    on<LoadPastRecommendationsEvent>(_onLoadPastRecommendations);
    on<ResetEvent>(_onReset);
  }

  Future<void> _onAnalyzeDrink(
    AnalyzeDrinkEvent event,
    Emitter<RecommendationState> emit,
  ) async {
    emit(AnalyzingDrinkState(event.drinkName));

    final result = await analyzeDrinkUseCase(event.drinkName);

    result.fold(
      (failure) => emit(ErrorState(failure.message)),
      (drink) => emit(DrinkAnalyzedState(drink)),
    );
  }

  Future<void> _onGetRecommendations(
    GetRecommendationsEvent event,
    Emitter<RecommendationState> emit,
  ) async {
    emit(LoadingRecommendationsState(event.drink));

    final result = await getToppingRecommendationsUseCase(event.drink);

    result.fold(
      (failure) => emit(ErrorState(failure.message)),
      (recommendation) {
        _currentRecommendation = recommendation;
        emit(RecommendationsLoadedState(recommendation));
      },
    );
  }

  Future<void> _onSaveRecommendation(
    SaveRecommendationEvent event,
    Emitter<RecommendationState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecommendationsLoadedState &&
        _currentRecommendation != null) {
      if (event.shouldSave) {
        final saveResult =
            await repository.saveRecommendation(_currentRecommendation!);

        saveResult.fold(
          (failure) => emit(ErrorState(failure.message)),
          (success) => emit(currentState.copyWith(isSaved: true)),
        );
      }
    }
  }

  Future<void> _onLoadPastRecommendations(
    LoadPastRecommendationsEvent event,
    Emitter<RecommendationState> emit,
  ) async {
    emit(const LoadingPastRecommendationsState());

    final result = await repository.getPastRecommendations();

    result.fold(
      (failure) => emit(ErrorState(failure.message)),
      (recommendations) =>
          emit(PastRecommendationsLoadedState(recommendations)),
    );
  }

  Future<void> _onReset(
    ResetEvent event,
    Emitter<RecommendationState> emit,
  ) async {
    _currentRecommendation = null;
    emit(const InitialState());
  }
}
