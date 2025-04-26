import 'package:equatable/equatable.dart';

class Topping extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final double
      compatibilityScore; // 0.0 - 1.0 score for compatibility with the drink
  final Map<String, double>?
      attributes; // Optional attributes like sweetness, texture, etc.

  const Topping({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.compatibilityScore,
    this.attributes,
  });

  @override
  List<Object?> get props => [id, name, category, compatibilityScore];
}
