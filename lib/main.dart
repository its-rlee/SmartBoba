import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'features/boba_recommendation/presentation/bloc/recommendation_bloc.dart';
import 'features/boba_recommendation/presentation/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RecommendationBloc>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Boba',
        theme: ThemeData(
          primarySwatch: Colors.brown,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
