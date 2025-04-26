import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../models/drink_model.dart';
import '../models/topping_model.dart';

abstract class AIService {
  Future<DrinkModel> analyzeDrink(String drinkName);
  Future<List<ToppingModel>> recommendToppings(DrinkModel drink);
}

class OpenAIService implements AIService {
  final http.Client client;
  final String apiKey;
  static const String openAIEndpoint =
      'https://api.openai.com/v1/chat/completions';

  OpenAIService({
    required this.client,
    String? apiKey,
  }) : apiKey = apiKey ?? '';

  @override
  Future<DrinkModel> analyzeDrink(String drinkName) async {
    try {
      if (apiKey.isEmpty) {
        throw const AIModelFailure(message: AppConstants.apiKeyMissingMessage);
      }

      // Print first few characters of API key to verify it's loaded (for debugging)
      print('API Key prefix: ${apiKey.substring(0, min(apiKey.length, 5))}...');

      // Prompt for the OpenAI model to analyze the drink
      final prompt = """
Analyze this boba drink: "$drinkName".
Return ONLY a valid JSON object with the following fields (no additional text, just JSON):
- ingredients (list of likely ingredients)
- flavor (map of flavor attributes with scores from 0-1: sweetness, bitterness, sourness, etc.)
- texture (map of texture attributes with scores from 0-1: smoothness, thickness, etc.)
- base (milk tea, fruit tea, etc.)
      """;

      final requestBody = {
        'model': AppConstants.openAIModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant that responds only with valid JSON. Do not include any explanations, just the JSON object.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      };

      print('Making API request to: $openAIEndpoint');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await client.post(
        Uri.parse(openAIEndpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print(
            'Response body: ${response.body.substring(0, min(response.body.length, 100))}...');

        final generatedText =
            jsonResponse['choices'][0]['message']['content'] as String;
        print(
            'Generated text: ${generatedText.substring(0, min(generatedText.length, 100))}...');

        // Extract JSON from generated text - should be just JSON, but handle potential text wrapping
        final jsonStartIndex = generatedText.indexOf('{');
        final jsonEndIndex = generatedText.lastIndexOf('}') + 1;

        // Check if we found valid JSON markers
        if (jsonStartIndex < 0 || jsonEndIndex <= jsonStartIndex) {
          print('Invalid JSON format in response. Using raw text.');
          throw const AIModelFailure(
              message: 'Invalid response format from OpenAI');
        }

        final jsonString =
            generatedText.substring(jsonStartIndex, jsonEndIndex);
        print(
            'Extracted JSON: ${jsonString.substring(0, min(jsonString.length, 100))}...');

        try {
          final Map<String, dynamic> drinkData = jsonDecode(jsonString);

          return DrinkModel(
            name: drinkName,
            ingredients: drinkData['ingredients'] != null
                ? List<String>.from(drinkData['ingredients'])
                : null,
            flavor: drinkData['flavor'] != null
                ? Map<String, double>.from(drinkData['flavor'])
                : null,
            texture: drinkData['texture'] != null
                ? Map<String, double>.from(drinkData['texture'])
                : null,
            base: drinkData['base'],
          );
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          throw const AIModelFailure(
              message: 'Failed to parse JSON from OpenAI response');
        }
      } else {
        print('Error response body: ${response.body}');
        throw AIModelFailure(
          message:
              'Failed to analyze drink. Status code: ${response.statusCode}. Response: ${response.body}',
        );
      }
    } catch (e) {
      print('Error in analyzeDrink: $e');
      if (e is AIModelFailure) {
        rethrow;
      }
      throw AIModelFailure(
        message: 'Error analyzing drink: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ToppingModel>> recommendToppings(DrinkModel drink) async {
    try {
      if (apiKey.isEmpty) {
        throw const AIModelFailure(message: AppConstants.apiKeyMissingMessage);
      }

      // Create a prompt for the OpenAI model to recommend toppings based on drink properties
      final prompt = """
Recommend 5 boba toppings for this drink: "${drink.name}".
${drink.ingredients != null ? 'Ingredients: ${drink.ingredients!.join(', ')}' : ''}
${drink.base != null ? 'Base: ${drink.base}' : ''}
${drink.flavor != null ? 'Flavor profile: ${drink.flavor.toString()}' : ''}
${drink.texture != null ? 'Texture profile: ${drink.texture.toString()}' : ''}

Return ONLY a valid JSON array with 5 toppings. Each topping should have (no additional text, just the JSON array):
- name (topping name)
- description (why this topping works well with the drink)
- category (one of: Pearls, Jellies, Puddings, Beans, Fruits, Others)
- compatibilityScore (0-1 score of how well it works with the drink)
- attributes (map of attributes with scores from 0-1: sweetness, chewiness, etc.)
      """;

      final requestBody = {
        'model': AppConstants.openAIModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant that responds only with valid JSON. Do not include any explanations, just the JSON array.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      };

      print('Making toppings API request to: $openAIEndpoint');

      final response = await client.post(
        Uri.parse(openAIEndpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Toppings response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedText =
            jsonResponse['choices'][0]['message']['content'] as String;
        print(
            'Toppings generated text: ${generatedText.substring(0, min(generatedText.length, 100))}...');

        // Extract JSON from generated text - should be just JSON, but handle potential text wrapping
        final jsonStartIndex = generatedText.indexOf('[');
        final jsonEndIndex = generatedText.lastIndexOf(']') + 1;

        // Check if we found valid JSON markers
        if (jsonStartIndex < 0 || jsonEndIndex <= jsonStartIndex) {
          print('Invalid JSON format in toppings response. Using raw text.');
          throw const AIModelFailure(
              message: 'Invalid response format from OpenAI for toppings');
        }

        final jsonString =
            generatedText.substring(jsonStartIndex, jsonEndIndex);

        try {
          final List<dynamic> toppingsData = jsonDecode(jsonString);

          return toppingsData.map((topping) {
            String category = topping['category'] ?? 'Others';
            return ToppingModel(
              id: const Uuid().v4(),
              name: topping['name'],
              description: topping['description'],
              category: category,
              compatibilityScore: topping['compatibilityScore'].toDouble(),
              attributes: topping['attributes'] != null
                  ? Map<String, double>.from(topping['attributes'])
                  : null,
            );
          }).toList();
        } catch (jsonError) {
          print('Toppings JSON parsing error: $jsonError');
          throw const AIModelFailure(
              message: 'Failed to parse JSON from OpenAI toppings response');
        }
      } else {
        print('Toppings error response body: ${response.body}');
        throw AIModelFailure(
          message:
              'Failed to recommend toppings. Status code: ${response.statusCode}. Response: ${response.body}',
        );
      }
    } catch (e) {
      print('Error in recommendToppings: $e');
      if (e is AIModelFailure) {
        rethrow;
      }
      throw AIModelFailure(
        message: 'Error recommending toppings: ${e.toString()}',
      );
    }
  }

  // Helper function to avoid index out of bounds
  int min(int a, int b) {
    return a < b ? a : b;
  }
}

class GoogleGenerativeAIService implements AIService {
  final http.Client client;
  final String apiKey;

  GoogleGenerativeAIService({required this.client, required this.apiKey});

  @override
  Future<DrinkModel> analyzeDrink(String drinkName) async {
    try {
      if (apiKey.isEmpty) {
        print("API key is empty, throwing failure");
        throw const AIModelFailure(
            message: AppConstants.googleApiKeyMissingMessage);
      }

      print("Initializing Google Generative AI model");
      // Initialize the Google Generative AI model
      final model = GenerativeModel(
        model: AppConstants.googleAIModel,
        apiKey: apiKey,
      );

      // Prompt for the Google AI model to analyze the drink
      final prompt = """
Analyze this boba drink: "$drinkName".
Return ONLY a valid JSON object with the following fields (no additional text, just JSON):
- ingredients (list of likely ingredients)
- flavor (map of flavor attributes with scores from 0-1: sweetness, bitterness, sourness, etc.)
- texture (map of texture attributes with scores from 0-1: smoothness, thickness, etc.)
- base (milk tea, fruit tea, etc.)
      """;

      print(
          "Sending prompt to Google AI: ${prompt.substring(0, min(prompt.length, 50))}...");
      // Generate content from the model
      final content = [Content.text(prompt)];

      try {
        print("Calling generateContent()");
        final response = await model.generateContent(content);
        print("Got response from Google AI");
        final generatedText = response.text ?? '';
        print("Generated text length: ${generatedText.length}");

        if (generatedText.isEmpty) {
          print("Empty response from Google AI");
          throw const AIModelFailure(message: "Empty response from Google AI");
        }

        print(
            'Generated text preview: ${generatedText.substring(0, min(generatedText.length, 100))}...');

        // Extract JSON from generated text
        final jsonStartIndex = generatedText.indexOf('{');
        final jsonEndIndex = generatedText.lastIndexOf('}') + 1;

        // Check if we found valid JSON markers
        if (jsonStartIndex < 0 || jsonEndIndex <= jsonStartIndex) {
          print('Invalid JSON format in response. Using raw text.');
          throw const AIModelFailure(
              message: 'Invalid response format from Google AI');
        }

        final jsonString =
            generatedText.substring(jsonStartIndex, jsonEndIndex);

        try {
          final Map<String, dynamic> drinkData = jsonDecode(jsonString);

          return DrinkModel(
            name: drinkName,
            ingredients: drinkData['ingredients'] != null
                ? List<String>.from(drinkData['ingredients'])
                : null,
            flavor: drinkData['flavor'] != null
                ? Map<String, double>.from(drinkData['flavor'])
                : null,
            texture: drinkData['texture'] != null
                ? Map<String, double>.from(drinkData['texture'])
                : null,
            base: drinkData['base'],
          );
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          throw const AIModelFailure(
              message: 'Failed to parse JSON from Google AI response');
        }
      } catch (apiCallError) {
        print("Error calling Google AI API: $apiCallError");
        rethrow;
      }
    } catch (e) {
      print('Error in analyzeDrink: $e');
      if (e is AIModelFailure) {
        rethrow;
      }
      throw AIModelFailure(
        message: 'Error analyzing drink: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ToppingModel>> recommendToppings(DrinkModel drink) async {
    try {
      if (apiKey.isEmpty) {
        throw const AIModelFailure(
            message: AppConstants.googleApiKeyMissingMessage);
      }

      // Initialize the Google Generative AI model
      final model = GenerativeModel(
        model: AppConstants.googleAIModel,
        apiKey: apiKey,
      );

      // Create a prompt for the Google AI model to recommend toppings based on drink properties
      final prompt = """
Recommend 5 boba toppings for this drink: "${drink.name}".
${drink.ingredients != null ? 'Ingredients: ${drink.ingredients!.join(', ')}' : ''}
${drink.base != null ? 'Base: ${drink.base}' : ''}
${drink.flavor != null ? 'Flavor profile: ${drink.flavor.toString()}' : ''}
${drink.texture != null ? 'Texture profile: ${drink.texture.toString()}' : ''}

Return ONLY a valid JSON array with 5 toppings. Each topping should have (no additional text, just the JSON array):
- name (topping name)
- description (why this topping works well with the drink)
- category (one of: Pearls, Jellies, Puddings, Beans, Fruits, Others)
- compatibilityScore (0-1 score of how well it works with the drink)
- attributes (map of attributes with scores from 0-1: sweetness, chewiness, etc.)
      """;

      // Generate content from the model
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final generatedText = response.text ?? '';

      print(
          'Toppings generated text: ${generatedText.substring(0, min(generatedText.length, 100))}...');

      // Extract JSON from generated text
      final jsonStartIndex = generatedText.indexOf('[');
      final jsonEndIndex = generatedText.lastIndexOf(']') + 1;

      // Check if we found valid JSON markers
      if (jsonStartIndex < 0 || jsonEndIndex <= jsonStartIndex) {
        print('Invalid JSON format in toppings response. Using raw text.');
        throw const AIModelFailure(
            message: 'Invalid response format from Google AI for toppings');
      }

      final jsonString = generatedText.substring(jsonStartIndex, jsonEndIndex);

      try {
        final List<dynamic> toppingsData = jsonDecode(jsonString);

        return toppingsData.map((topping) {
          String category = topping['category'] ?? 'Others';
          return ToppingModel(
            id: const Uuid().v4(),
            name: topping['name'],
            description: topping['description'],
            category: category,
            compatibilityScore: topping['compatibilityScore'].toDouble(),
            attributes: topping['attributes'] != null
                ? Map<String, double>.from(topping['attributes'])
                : null,
          );
        }).toList();
      } catch (jsonError) {
        print('Toppings JSON parsing error: $jsonError');
        throw const AIModelFailure(
            message: 'Failed to parse JSON from Google AI toppings response');
      }
    } catch (e) {
      print('Error in recommendToppings: $e');
      if (e is AIModelFailure) {
        rethrow;
      }
      throw AIModelFailure(
        message: 'Error recommending toppings: ${e.toString()}',
      );
    }
  }

  // Helper function to avoid index out of bounds
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
