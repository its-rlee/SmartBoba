import '../../domain/entities/drink.dart';

class DrinkModel extends Drink {
  const DrinkModel({
    required super.name,
    super.ingredients,
    super.flavor,
    super.texture,
    super.base,
  });

  factory DrinkModel.fromJson(Map<String, dynamic> json) {
    return DrinkModel(
      name: json['name'],
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : null,
      flavor: json['flavor'] != null
          ? Map<String, double>.from(json['flavor'])
          : null,
      texture: json['texture'] != null
          ? Map<String, double>.from(json['texture'])
          : null,
      base: json['base'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ingredients': ingredients,
      'flavor': flavor,
      'texture': texture,
      'base': base,
    };
  }

  // Create a basic drink model from just a name
  factory DrinkModel.basic(String name) {
    return DrinkModel(name: name);
  }
}
