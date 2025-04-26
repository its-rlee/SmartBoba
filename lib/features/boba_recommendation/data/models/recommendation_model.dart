import '../../domain/entities/recommendation.dart';
import 'drink_model.dart';
import 'topping_model.dart';

class RecommendationModel extends Recommendation {
  const RecommendationModel({
    required DrinkModel super.drink,
    required List<ToppingModel> super.toppings,
    required super.recommendationRationale,
    required super.createdAt,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      drink: DrinkModel.fromJson(json['drink']),
      toppings: (json['toppings'] as List)
          .map((topping) => ToppingModel.fromJson(topping))
          .toList(),
      recommendationRationale: json['recommendationRationale'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drink': (drink as DrinkModel).toJson(),
      'toppings': (toppings as List<ToppingModel>)
          .map((topping) => topping.toJson())
          .toList(),
      'recommendationRationale': recommendationRationale,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
