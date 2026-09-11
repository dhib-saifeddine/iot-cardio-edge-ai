import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/welcome_screen.dart';

Future<void> testFirebaseConnection() async {
  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('test');
    await ref.set({
      'connected': true,
      'message': 'Hello from Flutter!',
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Firebase write successful!');
  } catch (e) {
    debugPrint('❌ Firebase write failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBzkr9apFqQGNu6v3vPSg4EKEBq8oJQrao',
      appId: '1:150399631124:android:4d306357ee4805ba6c0c01',
      messagingSenderId: '150399631124',
      projectId: 'pfe-cardio-iot',
      databaseURL: 'https://pfe-cardio-iot-default-rtdb.firebaseio.com',
      storageBucket: 'pfe-cardio-iot.firebasestorage.app',
    ),
  );
  await testFirebaseConnection();
  runApp(const CardioIotApp());
}

class CardioIotApp extends StatelessWidget {
  const CardioIotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PFE Cardio IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const WelcomeScreen(),
    );
  }
}
