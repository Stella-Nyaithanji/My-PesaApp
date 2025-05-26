import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/credits_tab_page.dart';
import 'package:my_pesa_app/pages/debts_tab_page.dart';

class BalancesPage extends StatelessWidget {
  const BalancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Debts and Credits
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Balances'),
          bottom: const TabBar(tabs: [Tab(text: 'Debts'), Tab(text: 'Credits')]),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.green, Colors.teal])),
          ),
        ),
        body: TabBarView(children: [DebtsTabPage(userId: 'userId'), const CreditsTabPage()]),
      ),
    );
  }
}
