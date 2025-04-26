import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/drink.dart';
import '../entities/recommendation.dart';
import '../entities/topping.dart';

abstract class BobaRepository {
  /// Analyzes a drink name and returns a Drink entity with its properties
  Future<Either<Failure, Drink>> analyzeDrink(String drinkName);

  /// Gets topping recommendations for a given drink
  Future<Either<Failure, Recommendation>> getToppingRecommendations(
      Drink drink);

  /// Gets all available toppings regardless of drink
  Future<Either<Failure, List<Topping>>> getAllToppings();

  /// Gets past recommendations
  Future<Either<Failure, List<Recommendation>>> getPastRecommendations();

  /// Saves a recommendation
  Future<Either<Failure, bool>> saveRecommendation(
      Recommendation recommendation);
}
