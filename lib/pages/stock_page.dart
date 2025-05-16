import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/add_stock_page.dart';
import 'package:my_pesa_app/pages/view_stock_page.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Stock Manager'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.white,
            tabs: [Tab(icon: Icon(Icons.add_box), text: 'Add Stock'), Tab(icon: Icon(Icons.block), text: 'View Stock')],
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: const TabBarView(children: [AddStockPage(), ViewStockPage()]),
      ),
    );
  }
}
