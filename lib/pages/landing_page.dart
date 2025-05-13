import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/add_stock_page.dart';
import 'package:my_pesa_app/pages/view_stock_page.dart';
import 'package:my_pesa_app/pages/sell_item_page.dart';
import 'package:my_pesa_app/pages/cart_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int currentPage = 0;

  final List<Widget> pages = [
    AddStockPage(),
    ViewStockPage(),
    SellItemPage(),
    CartPage(
      selectedItems: {}, // You can pass actual cart data if needed
      total: 0.0,
      onSaleCompleted: () {},
    ),
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
            NavigationDestination(icon: Icon(Icons.add_box), label: "Add Stock"),
            NavigationDestination(icon: Icon(Icons.inventory), label: "View Stock"),
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: "Sell"),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: "Cart"),
          ],
        ),
      ),
      body: pages[currentPage],
    );
  }
}
