import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_pesa_app/pages/landing_page.dart';
import 'package:my_pesa_app/pages/my_account_page.dart';
import 'package:my_pesa_app/pages/sign_in_page.dart';
import 'package:my_pesa_app/pages/sign_up_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyPesaApp());
}

class MyPesaApp extends StatelessWidget {
  const MyPesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pesa App',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => LandingPage(),
        '/account': (context) => const MyAccountPage(),
      },
    );
  }
}
