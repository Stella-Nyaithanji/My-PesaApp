import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_pesa_app/pages/mainPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔥 Initialize Firebase here

  runApp(MyMoneyApp());
}

class MyMoneyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'My Pesa App', theme: ThemeData(primarySwatch: Colors.green), home: MainPage());
  }
}
