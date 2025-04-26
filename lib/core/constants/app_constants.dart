class AppConstants {
  static const String appName = 'Smart Boba';
  static const String appVersion = '1.0.0';

  // AI Model Info
  static const String openAIModel = 'gpt-3.5-turbo';
  static const String googleAIModel = 'gemini-1.5-flash';

  // Asset Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String animationPath = 'assets/animations/';

  // Error Messages
  static const String generalErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String aiErrorMessage =
      'Could not process your request. Please try again.';
  static const String apiKeyMissingMessage =
      'OpenAI API key is missing. Please add it to your .env file.';
  static const String googleApiKeyMissingMessage =
      'Google AI API key is missing. Please add it to your .env file.';

  // Topping Categories
  static const List<String> toppingCategories = [
    'Pearls',
    'Jellies',
    'Puddings',
    'Beans',
    'Fruits',
    'Others'
  ];
}
