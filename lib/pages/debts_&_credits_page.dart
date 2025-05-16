import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/credits_tab_page.dart';
import 'package:my_pesa_app/pages/debts_tab_page.dart';

class DebtsCreditsPage extends StatelessWidget {
  const DebtsCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Debts and Credits
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debts & Credits'),
          bottom: const TabBar(tabs: [Tab(text: 'Debts'), Tab(text: 'Credits')]),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.green, Colors.teal])),
          ),
        ),
        body: TabBarView(
          children: [
            DebtsTabPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
            DebtsTabPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
            const CreditsTabPage(),
          ],
        ),
      ),
    );
  }
}
