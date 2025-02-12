
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:provider/provider.dart';

import 'adminDashboard.dart';
import 'auth_service.dart';
import 'checkin_screen.dart';
import 'loginScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
      apiKey: "AIzaSyCvpF_y9NHJeNL0xvQRvjKMqkC_5qzLLhs",
      appId: "1:342522546817:android:279abb58ec25bf29565b80",
      messagingSenderId: "342522546817",
      projectId: "attendance-app-be3a9",
    ),);
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCvpF_y9NHJeNL0xvQRvjKMqkC_5qzLLhs",
        appId: "1:342522546817:android:279abb58ec25bf29565b80",
        messagingSenderId: "342522546817",
        projectId: "attendance-app-be3a9",
      ),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Attendance Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          } else {
            return user.email == "admin@gmail.com" ? const AdminDashboard() : const CheckInScreen();
          }
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}