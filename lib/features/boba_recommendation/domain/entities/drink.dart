import 'package:equatable/equatable.dart';

class Drink extends Equatable {
  final String name;
  final List<String>? ingredients;
  final Map<String, double>?
      flavor; // Flavor attributes (sweetness, bitterness, etc.)
  final Map<String, double>?
      texture; // Texture attributes (thickness, smoothness, etc.)
  final String? base; // E.g., "milk tea", "fruit tea", etc.

  const Drink({
    required this.name,
    this.ingredients,
    this.flavor,
    this.texture,
    this.base,
  });

  @override
  List<Object?> get props => [name, base];
}
