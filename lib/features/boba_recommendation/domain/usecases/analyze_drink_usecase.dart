import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/drink.dart';
import '../repositories/boba_repository.dart';

class AnalyzeDrinkUseCase {
  final BobaRepository repository;

  AnalyzeDrinkUseCase(this.repository);

  Future<Either<Failure, Drink>> call(String drinkName) {
    return repository.analyzeDrink(drinkName);
  }
}
