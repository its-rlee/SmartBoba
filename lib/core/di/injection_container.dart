import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/boba_recommendation/data/datasources/ai_service.dart';
import '../../features/boba_recommendation/data/repositories/boba_repository_impl.dart';
import '../../features/boba_recommendation/domain/repositories/boba_repository.dart';
import '../../features/boba_recommendation/domain/usecases/analyze_drink_usecase.dart';
import '../../features/boba_recommendation/domain/usecases/get_topping_recommendations_usecase.dart';
import '../../features/boba_recommendation/presentation/bloc/recommendation_bloc.dart';
import '../services/firebase_service.dart';

final sl = GetIt.instance;

// Set to false to use the Google AI service, true to use mock data
bool useMockData = false;

Future<void> init() async {
  print("Initializing dependency injection...");
  print("Mock data mode: $useMockData");

  // Initialize Firebase service
  final firebaseService = FirebaseService();
  sl.registerLazySingleton(() => firebaseService);

  // Get API key from Firestore only
  String googleApiKey = await firebaseService.getGoogleApiKey();
  if (googleApiKey.isEmpty) {
    throw Exception('No API key found in Firestore.');
  }
  print("Google API key length: [32m${googleApiKey.length}[0m");

  // BLoC
  sl.registerFactory(
    () => RecommendationBloc(
      analyzeDrinkUseCase: sl(),
      getToppingRecommendationsUseCase: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => AnalyzeDrinkUseCase(sl()));
  sl.registerLazySingleton(() => GetToppingRecommendationsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<BobaRepository>(
    () => BobaRepositoryImpl(
      aiService: sl(),
      sharedPreferences: sl(),
      useMockData: useMockData, // Use the global flag
    ),
  );

  // Data sources
  sl.registerLazySingleton<AIService>(
    () => GoogleGenerativeAIService(
      client: sl(),
      apiKey: googleApiKey, // Use the API key from Firestore only
    ),
  );

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());

  print("Dependency injection initialized successfully.");
}
