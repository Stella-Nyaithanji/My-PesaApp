import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        await FirebaseFirestore.instance.collection('stock').doc(docId).delete();
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
  ) async {
    TextEditingController itemController = TextEditingController(text: itemName);
    TextEditingController quantityController = TextEditingController(text: quantity.toString());
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
                    await FirebaseFirestore.instance.collection('stock').doc(docId).update({
                      'item': itemController.text,
                      'quantity': quantityController.text,
                      'sellingPrice': double.parse(sellingPriceController.text),
                      'restockAlert': double.parse(restockAlertController.text),
                    });
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
      appBar: AppBar(
        title: const Text("View Stock"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = _searchController.text.trim();
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
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search by item name',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),

              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('stock').orderBy('timestamp', descending: true).snapshots(),
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
                        final quantity = stock['quantity'] ?? '0';
                        final sellingPrice = stock['sellingPrice'] ?? 0.0;
                        final restockAlert = stock['restockAlert'] ?? 0.0;
                        final docId = stock.id;

                        double qty = 0.0;
                        try {
                          qty = double.parse(quantity.toString().split(' ')[0]);
                        } catch (_) {}

                        bool isRestock = qty <= restockAlert;

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
                                          _editStockItem(docId, item, qty, sellingPrice, restockAlert);
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
                                Text("Quantity: $quantity"),
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
