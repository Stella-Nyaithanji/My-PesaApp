import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pesa_app/pages/add_Stock_page.dart';
import 'package:my_pesa_app/pages/cart_page.dart';
import 'package:my_pesa_app/pages/reports_page.dart';
import 'package:my_pesa_app/pages/sell_item_page.dart';
import 'package:my_pesa_app/pages/view_stock_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final userName = user?.displayName ?? user?.email ?? 'User';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text('My Pesa APP', style: TextStyle(color: Colors.white)),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/account');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.teal) : null,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName!\nLet us kick off from where we left:',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 30),
            buildMenuButton(context, 'Add Stock'),
            buildMenuButton(context, 'View Stock'),
            buildMenuButton(context, 'Sell Item'),
            buildMenuButton(context, 'Cart Summary'),
            buildMenuButton(context, 'Reports'),
          ],
        ),
      ),
    );
  }

  Widget buildMenuButton(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton(
        onPressed: () {
          if (title == 'Add Stock') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStockPage()));
          } else if (title == 'Sell Item') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SellItemPage()));
          } else if (title == 'View Stock') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewStockPage()));
          } else if (title == 'Cart Summary') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage(cartItems: [], onSaleCompleted: () {})));
          } else if (title == 'Reports') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }
}
