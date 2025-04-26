import 'package:uuid/uuid.dart';

import '../../domain/entities/topping.dart';

class ToppingModel extends Topping {
  const ToppingModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.compatibilityScore,
    super.attributes,
  });

  factory ToppingModel.fromJson(Map<String, dynamic> json) {
    return ToppingModel(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'],
      description: json['description'],
      category: json['category'],
      compatibilityScore: json['compatibilityScore'].toDouble(),
      attributes: json['attributes'] != null
          ? Map<String, double>.from(json['attributes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'compatibilityScore': compatibilityScore,
      'attributes': attributes,
    };
  }
}
