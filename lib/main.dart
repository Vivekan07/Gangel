import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/women_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('================= App Starting =================');
  print('Flutter binding initialized');
  
  bool firebaseInitialized = false;
  
  try {
    print('Attempting to initialize Firebase...');
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAQedaIxI4qoWBdCk6huYIeI-K9Ud-lzDI',
        appId: '1:407655520509:android:e1179f955ff6e8b6bf8694',
        messagingSenderId: '407655520509',
        projectId: 'ganagel-95192',
        storageBucket: 'ganagel-95192.appspot.com',
        authDomain: 'ganagel-95192.firebaseapp.com',
      ),
    );
    print('✓ Firebase core initialized successfully');
    firebaseInitialized = true;
    
    print('Attempting to write test document to Firestore...');
    // Test Firestore connection - create a test document
    try {
      await FirebaseFirestore.instance
          .collection('test-collection')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'message': 'Test connection',
            'appStartTime': DateTime.now().toString(),
          });
      print('✓ Firestore connection successful!');
    } catch (firestoreError) {
      print('! Firestore test write failed: $firestoreError');
      print('! This may affect app functionality, but will continue startup');
    }
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
  
  print('Starting app (Firebase initialized: $firebaseInitialized)');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gangel App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

