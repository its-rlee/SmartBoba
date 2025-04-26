import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/drink.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/entities/topping.dart';
import '../../domain/repositories/boba_repository.dart';
import '../datasources/ai_service.dart';
import '../models/drink_model.dart';
import '../models/recommendation_model.dart';
import '../models/topping_model.dart';

class BobaRepositoryImpl implements BobaRepository {
  final AIService aiService;
  final SharedPreferences sharedPreferences;
  static const String RECOMMENDATIONS_KEY = 'past_recommendations';

  // Flag to use mock data instead of API calls (for testing or when API is unavailable)
  final bool useMockData;

  BobaRepositoryImpl({
    required this.aiService,
    required this.sharedPreferences,
    this.useMockData = false,
  }) {
    print("BobaRepositoryImpl initialized with useMockData = $useMockData");
  }

  @override
  Future<Either<Failure, Drink>> analyzeDrink(String drinkName) async {
    try {
      print("analyzeDrink: starting for drink '$drinkName'");
      if (useMockData) {
        print("analyzeDrink: using mock data (as configured)");
        // Use mock data instead of making API call
        final mockDrink = _getMockDrinkForName(drinkName);
        return Right(mockDrink);
      }

      try {
        print("analyzeDrink: attempting AI service call");
        // Try the API call first
        final drinkModel = await aiService.analyzeDrink(drinkName);
        print("analyzeDrink: AI service call successful");
        return Right(drinkModel);
      } catch (apiError) {
        // If API call fails, use mock data as fallback
        print(
            'analyzeDrink: API call failed, using mock data instead: $apiError');
        final mockDrink = _getMockDrinkForName(drinkName);
        return Right(mockDrink);
      }
    } on AIModelFailure catch (e) {
      print("analyzeDrink: AIModelFailure: ${e.message}");
      return Left(e);
    } catch (e) {
      print("analyzeDrink: Unknown error: $e");
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Recommendation>> getToppingRecommendations(
      Drink drink) async {
    try {
      print("getToppingRecommendations: starting for drink '${drink.name}'");

      // Ensure we're working with a DrinkModel
      final drinkModel = drink is DrinkModel
          ? drink
          : DrinkModel(
              name: drink.name,
              ingredients: drink.ingredients,
              flavor: drink.flavor,
              texture: drink.texture,
              base: drink.base,
            );

      List<ToppingModel> toppings;
      if (useMockData) {
        print("getToppingRecommendations: using mock data (as configured)");
        // Use mock data instead of making API call
        toppings = _getMockToppingsForDrink(drinkModel);
      } else {
        try {
          print("getToppingRecommendations: attempting AI service call");
          // Try the API call first
          toppings = await aiService.recommendToppings(drinkModel);
          print("getToppingRecommendations: AI service call successful");
        } catch (apiError) {
          // If API call fails, use mock data as fallback
          print(
              'getToppingRecommendations: API call failed, using mock data instead: $apiError');
          toppings = _getMockToppingsForDrink(drinkModel);
        }
      }

      final recommendation = RecommendationModel(
        drink: drinkModel,
        toppings: toppings,
        recommendationRationale: _generateRationale(drinkModel, toppings),
        createdAt: DateTime.now(),
      );

      print("getToppingRecommendations: returning ${toppings.length} toppings");
      return Right(recommendation);
    } on AIModelFailure catch (e) {
      print("getToppingRecommendations: AIModelFailure: ${e.message}");
      return Left(e);
    } catch (e) {
      print("getToppingRecommendations: Unknown error: $e");
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Topping>>> getAllToppings() async {
    // Note: This is a placeholder implementation for a feature not currently used in the UI
    // If this feature is implemented in the future, consider fetching real data from a backend
    try {
      final List<ToppingModel> standardToppings = [
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Tapioca Pearls',
          description:
              'Classic chewy tapioca balls that complement most drinks.',
          category: 'Pearls',
          compatibilityScore: 0.9,
        ),
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Grass Jelly',
          description: 'Herbal jelly with a mild, slightly bitter taste.',
          category: 'Jellies',
          compatibilityScore: 0.7,
        ),
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Aloe Vera Jelly',
          description: 'Refreshing and slightly sweet aloe vera cubes.',
          category: 'Jellies',
          compatibilityScore: 0.8,
        ),
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Red Bean',
          description: 'Sweet red beans commonly used in Asian desserts.',
          category: 'Beans',
          compatibilityScore: 0.65,
        ),
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Pudding',
          description: 'Smooth, custard-like pudding that adds creaminess.',
          category: 'Puddings',
          compatibilityScore: 0.85,
        ),
      ];

      return Right(standardToppings);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Recommendation>>> getPastRecommendations() async {
    try {
      final jsonString = sharedPreferences.getString(RECOMMENDATIONS_KEY);

      if (jsonString == null) {
        return const Right([]);
      }

      final jsonList = jsonDecode(jsonString) as List;
      final recommendations =
          jsonList.map((json) => RecommendationModel.fromJson(json)).toList();

      return Right(recommendations);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> saveRecommendation(
      Recommendation recommendation) async {
    try {
      // Get existing recommendations
      final jsonString = sharedPreferences.getString(RECOMMENDATIONS_KEY);
      List<Map<String, dynamic>> jsonList = [];

      if (jsonString != null) {
        jsonList = List<Map<String, dynamic>>.from(
            (jsonDecode(jsonString) as List).cast<Map<String, dynamic>>());
      }

      // Add new recommendation
      final recommendationModel = recommendation as RecommendationModel;
      jsonList.add(recommendationModel.toJson());

      // Save back to shared preferences
      final success = await sharedPreferences.setString(
        RECOMMENDATIONS_KEY,
        jsonEncode(jsonList),
      );

      return Right(success);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // Helper to generate a recommendation rationale when the AI doesn't provide one
  String _generateRationale(DrinkModel drink, List<ToppingModel> toppings) {
    final topToppings = toppings.take(3).map((t) => t.name).join(', ');
    return 'Based on the flavor profile and characteristics of ${drink.name}, '
        'the top recommended toppings are: $topToppings. These toppings complement '
        'the ${drink.base ?? 'base'} and enhance the overall taste experience.';
  }

  // MOCK DATA METHODS

  // Generate mock drink data based on the name
  DrinkModel _getMockDrinkForName(String drinkName) {
    final name = drinkName.toLowerCase();

    // Default values
    List<String> ingredients = ['Tea', 'Sugar', 'Water'];
    Map<String, double> flavor = {'Sweetness': 0.6, 'Bitterness': 0.3};
    Map<String, double> texture = {'Smoothness': 0.7, 'Thickness': 0.5};
    String base = 'Milk Tea';

    // Customize based on drink name components
    if (name.contains('taro')) {
      ingredients.add('Taro');
      flavor['Sweetness'] = 0.7;
      flavor['Creaminess'] = 0.8;
      base = 'Taro Milk Tea';
    }

    if (name.contains('jasmine')) {
      ingredients.add('Jasmine Tea');
      flavor['Floral'] = 0.8;
      flavor['Bitterness'] = 0.2;
      base =
          base.contains('Taro') ? 'Taro Jasmine Milk Tea' : 'Jasmine Milk Tea';
    }

    if (name.contains('matcha')) {
      ingredients.add('Matcha Powder');
      flavor['Bitterness'] = 0.5;
      flavor['Earthiness'] = 0.7;
      texture['Thickness'] = 0.6;
      base = 'Matcha Latte';
    }

    if (name.contains('brown sugar')) {
      ingredients.add('Brown Sugar');
      flavor['Sweetness'] = 0.9;
      flavor['Caramel'] = 0.8;
      base = 'Brown Sugar Milk Tea';
    }

    if (name.contains('milk')) {
      ingredients.add('Milk');
      texture['Creaminess'] = 0.8;
    }

    return DrinkModel(
      name: drinkName,
      ingredients: ingredients,
      flavor: flavor,
      texture: texture,
      base: base,
    );
  }

  // Generate mock toppings based on the drink
  List<ToppingModel> _getMockToppingsForDrink(DrinkModel drink) {
    final drinkName = drink.name.toLowerCase();
    final drinkBase = drink.base?.toLowerCase() ?? '';

    // Default toppings that work well with many drinks
    List<ToppingModel> result = [
      ToppingModel(
        id: const Uuid().v4(),
        name: 'Tapioca Pearls',
        description:
            'Classic chewy boba pearls that complement the drink with their subtle sweetness and chewy texture.',
        category: 'Pearls',
        compatibilityScore: 0.9,
      ),
    ];

    // Specific recommendations based on drink type
    if (drinkName.contains('taro') || drinkBase.contains('taro')) {
      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Pudding',
          description:
              'Smooth, custard-like pudding that enhances the creamy nature of taro drinks.',
          category: 'Puddings',
          compatibilityScore: 0.95,
        ),
      );

      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Grass Jelly',
          description:
              'The slight bitterness of grass jelly provides a nice contrast to the sweet taro flavor.',
          category: 'Jellies',
          compatibilityScore: 0.75,
        ),
      );
    }

    if (drinkName.contains('jasmine') || drinkBase.contains('jasmine')) {
      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Lychee Jelly',
          description:
              'Sweet and floral lychee jelly pairs perfectly with the delicate jasmine flavor.',
          category: 'Jellies',
          compatibilityScore: 0.9,
        ),
      );

      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Aloe Vera',
          description:
              'Refreshing aloe vera complements the light floral notes in jasmine tea.',
          category: 'Jellies',
          compatibilityScore: 0.85,
        ),
      );
    }

    if (drinkName.contains('matcha') || drinkBase.contains('matcha')) {
      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Red Bean',
          description:
              'The traditional pairing of red bean with matcha creates a balanced flavor profile.',
          category: 'Beans',
          compatibilityScore: 0.95,
        ),
      );

      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Mochi',
          description:
              'Chewy mochi pieces complement the earthy matcha flavor with their subtle sweetness.',
          category: 'Others',
          compatibilityScore: 0.87,
        ),
      );
    }

    if (drinkName.contains('brown sugar') ||
        drinkBase.contains('brown sugar')) {
      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Cream Cheese Foam',
          description:
              'The tangy cream cheese foam balances the rich sweetness of brown sugar.',
          category: 'Others',
          compatibilityScore: 0.93,
        ),
      );

      result.add(
        ToppingModel(
          id: const Uuid().v4(),
          name: 'Brown Sugar Pearls',
          description:
              'Special tapioca pearls soaked in brown sugar syrup to enhance the caramel notes.',
          category: 'Pearls',
          compatibilityScore: 0.98,
        ),
      );
    }

    // Add standard options if we don't have enough specialized ones
    if (result.length < 5) {
      if (!result.any((t) => t.name == 'Pudding')) {
        result.add(
          ToppingModel(
            id: const Uuid().v4(),
            name: 'Pudding',
            description:
                'Smooth, custard-like pudding that adds creaminess to any milk tea.',
            category: 'Puddings',
            compatibilityScore: 0.7,
          ),
        );
      }

      if (!result.any((t) => t.name == 'Coconut Jelly')) {
        result.add(
          ToppingModel(
            id: const Uuid().v4(),
            name: 'Coconut Jelly',
            description:
                'Light and refreshing coconut jelly that adds tropical flavor and interesting texture.',
            category: 'Jellies',
            compatibilityScore: 0.65,
          ),
        );
      }

      if (!result.any((t) => t.name.contains('Fruit'))) {
        result.add(
          ToppingModel(
            id: const Uuid().v4(),
            name: 'Fresh Fruit Bits',
            description:
                'Small pieces of seasonal fruits for a refreshing burst of flavor.',
            category: 'Fruits',
            compatibilityScore: 0.6,
          ),
        );
      }
    }

    // Ensure we're returning at most 5 toppings
    return result.take(5).toList();
  }
}
