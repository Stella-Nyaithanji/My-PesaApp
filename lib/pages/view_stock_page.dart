import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViewStockPage extends StatefulWidget {
  const ViewStockPage({super.key});

  @override
  _ViewStockPageState createState() => _ViewStockPageState();
}

class _ViewStockPageState extends State<ViewStockPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  double totalStockValue = 0.0;

  Future<void> _deleteStockItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('stock').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stock item deleted successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete item: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _editStockItem(
    String docId,
    String itemName,
    double quantity,
    double buyingPrice,
    double sellingPrice,
    double restockAlert,
  ) async {
    TextEditingController itemController = TextEditingController(text: itemName);
    TextEditingController quantityController = TextEditingController(text: quantity.toString());
    TextEditingController buyingPriceController = TextEditingController(text: buyingPrice.toString());
    TextEditingController sellingPriceController = TextEditingController(text: sellingPrice.toString());
    TextEditingController restockAlertController = TextEditingController(text: restockAlert.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Stock Item'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: itemController, decoration: InputDecoration(labelText: 'Item Name')),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: buyingPriceController,
                  decoration: InputDecoration(labelText: 'Buying Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: sellingPriceController,
                  decoration: InputDecoration(labelText: 'Selling Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: restockAlertController,
                  decoration: InputDecoration(labelText: 'Restock Alert'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  double updatedQuantity = double.parse(quantityController.text);
                  double updatedBuyingPrice = double.parse(buyingPriceController.text);
                  double updatedSellingPrice = double.parse(sellingPriceController.text);
                  double updatedRestockAlert = double.parse(restockAlertController.text);

                  await FirebaseFirestore.instance.collection('stock').doc(docId).update({
                    'item': itemController.text,
                    'quantity': '$updatedQuantity',
                    'buyingPrice': updatedBuyingPrice,
                    'sellingPrice': updatedSellingPrice,
                    'restockAlert': updatedRestockAlert,
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stock item updated successfully!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Failed to update item: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Stock"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = _searchController.text;
              });
            },
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by item name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('stock')
                          .where('item', isGreaterThanOrEqualTo: searchQuery)
                          .where('item', isLessThanOrEqualTo: '$searchQuery\uf8ff')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final stockList = snapshot.data!.docs;

                    if (stockList.isEmpty) {
                      return const Center(child: Text("No stock found.", style: TextStyle(color: Colors.white)));
                    }

                    // Calculate total stock value
                    totalStockValue = 0;
                    for (var stock in stockList) {
                      // Ensure quantity is parsed as a double
                      double quantity = 0;
                      try {
                        quantity = double.parse(stock['quantity'].split(' ')[0]);
                      } catch (e) {
                        quantity = 0; // Fallback if the quantity is invalid
                      }

                      double buyingPrice = stock['buyingPrice'] ?? 0.0;
                      totalStockValue += quantity * buyingPrice;
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: stockList.length,
                      itemBuilder: (context, index) {
                        final stock = stockList[index];
                        final item = stock['item'] ?? 'No name available';
                        final quantity = stock['quantity'] ?? 'N/A';
                        final buyingPrice = stock['buyingPrice'] ?? 0.0;
                        final sellingPrice = stock['sellingPrice'] ?? 0.0;
                        final restockAlert = stock['restockAlert'] ?? 0.0;
                        final docId = stock.id;

                        bool isRestockAlert = double.parse(quantity.split(' ')[0]) <= restockAlert;

                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text("Quantity: $quantity"),
                                Text("Buying Price: KSH $buyingPrice"),
                                Text("Selling Price: KSH $sellingPrice"),
                                isRestockAlert
                                    ? Text("Restock Alert! Quantity is low!", style: TextStyle(color: Colors.red))
                                    : SizedBox.shrink(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'Edit') {
                                          _editStockItem(
                                            docId,
                                            item,
                                            double.parse(quantity.split(' ')[0]),
                                            buyingPrice,
                                            sellingPrice,
                                            restockAlert,
                                          );
                                        } else if (value == 'Delete') {
                                          _deleteStockItem(docId);
                                        }
                                      },
                                      itemBuilder: (context) {
                                        return ['Edit', 'Delete'].map((String choice) {
                                          return PopupMenuItem<String>(value: choice, child: Text(choice));
                                        }).toList();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Stock Value: KSH ${totalStockValue.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
