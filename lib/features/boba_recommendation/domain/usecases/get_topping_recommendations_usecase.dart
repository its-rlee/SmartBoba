import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/drink.dart';
import '../entities/recommendation.dart';
import '../repositories/boba_repository.dart';

class GetToppingRecommendationsUseCase {
  final BobaRepository repository;

  GetToppingRecommendationsUseCase(this.repository);

  Future<Either<Failure, Recommendation>> call(Drink drink) {
    return repository.getToppingRecommendations(drink);
  }
}
