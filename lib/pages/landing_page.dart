import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/stock_page.dart';
import 'package:my_pesa_app/pages/sell_item_page.dart';
import 'package:my_pesa_app/pages/home_page.dart';
import 'package:my_pesa_app/pages/debts_&_credits_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int currentPage = 0;

  final List<Widget> pages = [
    const HomePage(), //Home
    const StockPage(), //Stock
    const SellItemPage(), // Sell
    const DebtsCreditsPage(), // Debts & Credits
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: NavigationBar(
          backgroundColor: Colors.teal.shade50,
          indicatorColor: Colors.green.shade200,
          selectedIndex: currentPage,
          onDestinationSelected: (value) {
            setState(() {
              currentPage = value;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: "Home"),
            NavigationDestination(icon: Icon(Icons.store), label: "Stock"),
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: "Sell"),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: "Debts & Credits"),
          ],
        ),
      ),
      body: pages[currentPage],
    );
  }
}
