import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseTest {
  static Future<void> testConnection() async {
    if (kIsWeb) {
      print('Skipping Firebase test on web platform');
      return;
    }
    
    try {
      final DatabaseReference reference = FirebaseDatabase.instance.ref('connection-test');
      
      // Write test data
      await reference.set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'Connection test'
      });
      
      print('✅ Firebase Database write successful');
      
      // Read test data to confirm
      final snapshot = await reference.get();
      if (snapshot.exists) {
        print('✅ Firebase Database read successful: ${snapshot.value}');
      } else {
        print('❌ Firebase Database read failed: snapshot does not exist');
      }
    } catch (e) {
      print('❌ Firebase Database connection test failed: $e');
      rethrow;
    }
  }
} 