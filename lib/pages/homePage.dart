import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/add_Stock_page.dart';
import 'package:my_pesa_app/pages/sell_item_page.dart';
import 'package:my_pesa_app/pages/view_stock_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text('My Pesa APP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 10),
          Text('Hello, Stella! Let us Kick off from where we left:', style: TextStyle(color: Colors.white)),
          SizedBox(height: 30),
          buildMenuButton(context, 'Add Stock'),
          buildMenuButton(context, 'View Stock'),
          buildMenuButton(context, 'Sell Item'),
          buildMenuButton(context, 'View Inventory'),
        ],
      ),
    );
  }

  Widget buildMenuButton(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton(
        onPressed: () {
          if (title == 'Add Stock') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AddStockPage()));
          } else if (title == 'Sell Item') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SellItemPage()));
          } else if (title == 'View Stock') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ViewStockPage()));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: Center(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }
}
