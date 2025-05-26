import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/firestore_collections_service.dart';

class ViewStockPage extends StatefulWidget {
  const ViewStockPage({super.key});

  @override
  ViewStockPageState createState() => ViewStockPageState();
}

class ViewStockPageState extends State<ViewStockPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final FirestoreCollectionsService _firestoreService = FirestoreCollectionsService();

  Future<void> _deleteStockItem(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this stock item?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteStockItem(docId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock item deleted successfully!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete item: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editStockItem(
    String docId,
    String itemName,
    double quantity,
    double sellingPrice,
    double restockAlert,
    String unit,
  ) async {
    TextEditingController itemController = TextEditingController(text: itemName);
    TextEditingController quantityController = TextEditingController(text: quantity.toString());
    TextEditingController unitController = TextEditingController(text: unit);
    TextEditingController sellingPriceController = TextEditingController(text: sellingPrice.toString());
    TextEditingController restockAlertController = TextEditingController(text: restockAlert.toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Stock Item'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Item Name')),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
                  TextField(
                    controller: sellingPriceController,
                    decoration: const InputDecoration(labelText: 'Selling Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: restockAlertController,
                    decoration: const InputDecoration(labelText: 'Restock Alert'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  try {
                    await _firestoreService.updateStockItem(
                      docId: docId,
                      item: itemController.text.trim(),
                      quantity: double.parse(quantityController.text),
                      unit: unitController.text.trim(),
                      sellingPrice: double.parse(sellingPriceController.text),
                      restockAlert: double.parse(restockAlertController.text),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stock item updated successfully!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed to update item: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View Stock"), backgroundColor: Colors.teal),
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
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by item name',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.stockCollection.orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allStocks = snapshot.data!.docs;
                    final stockList =
                        allStocks.where((doc) {
                          final name = doc['item'].toString().toLowerCase();
                          return name.contains(searchQuery.toLowerCase());
                        }).toList();

                    if (stockList.isEmpty) {
                      return const Center(child: Text("No stock found.", style: TextStyle(color: Colors.white)));
                    }

                    return ListView.builder(
                      itemCount: stockList.length,
                      itemBuilder: (context, index) {
                        final stock = stockList[index];
                        final item = stock['item'] ?? 'Unnamed';

                        // Fix: parse numeric part from quantity string
                        final rawQuantity = stock['quantity'] ?? '0';
                        final unit = stock['unit'] ?? '';

                        double quantityValue = 0;
                        try {
                          final numericString = RegExp(r'[\d.]+').stringMatch(rawQuantity.toString()) ?? '0';
                          quantityValue = double.parse(numericString);
                        } catch (e) {
                          quantityValue = 0;
                        }

                        final sellingPrice = (stock['sellingPrice'] ?? 0.0).toDouble();
                        final restockAlert = (stock['restockAlert'] ?? 0.0).toDouble();
                        final docId = stock.id;

                        bool isRestock = quantityValue <= restockAlert;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        isRestock ? '$item - Restock' : item,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isRestock ? Colors.red : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'Edit') {
                                          _editStockItem(docId, item, quantityValue, sellingPrice, restockAlert, unit);
                                        } else if (value == 'Delete') {
                                          _deleteStockItem(docId);
                                        }
                                      },
                                      itemBuilder: (context) {
                                        return ['Edit', 'Delete'].map((choice) {
                                          return PopupMenuItem<String>(value: choice, child: Text(choice));
                                        }).toList();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Quantity: $rawQuantity $unit"),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isRestock ? Colors.red : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isRestock ? 'Low Stock' : 'In Stock',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      'KSH ${sellingPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
