import 'package:equatable/equatable.dart';

import 'drink.dart';
import 'topping.dart';

class Recommendation extends Equatable {
  final Drink drink;
  final List<Topping> toppings;
  final String recommendationRationale; // The AI's explanation
  final DateTime createdAt;

  const Recommendation({
    required this.drink,
    required this.toppings,
    required this.recommendationRationale,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [drink, toppings, createdAt];
}
