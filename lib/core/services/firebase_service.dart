import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _apiKeysCollection = 'api_key';
  static const String _apiKeyDocument = 'EpmE6vlKYyL5WvkxfFOp';

  Future<String> getGoogleApiKey() async {
    try {
      final docSnapshot = await _firestore
          .collection(_apiKeysCollection)
          .doc(_apiKeyDocument)
          .get();

      print('docSnapshot.exists: \\${docSnapshot.exists}');
      print('docSnapshot.data(): \\${docSnapshot.data()}');

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('key')) {
          final key = data['key'] as String;
          debugPrint('Successfully retrieved API key from Firestore');
          return key;
        }
      }

      debugPrint('API key not found in Firestore document');
      return '';
    } catch (e) {
      debugPrint('Error fetching API key from Firestore: $e');
      return '';
    }
  }
}
