import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/cart_page.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final Map<String, dynamic> selectedItems = {};
  double total = 0.0;
  bool isProcessingSale = false;
  int cartItemCount = 0;

  void showSellDialog(DocumentSnapshot stockItem) {
    final qtyController = TextEditingController();
    final priceController = TextEditingController(text: stockItem['sellingPrice'].toString());

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: Text("Sell ${stockItem['item']}"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: 'Quantity Sold (e.g., 0.5, 1.25)'),
                        ),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Selling Price'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () {
                        _addToCart(stockItem, qtyController, priceController);
                      },
                      child: Text('Add to Cart'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _addToCart(
    DocumentSnapshot stockItem,
    TextEditingController qtyController,
    TextEditingController priceController,
  ) {
    final soldQty = double.tryParse(qtyController.text) ?? 0;
    final soldPrice = double.tryParse(priceController.text) ?? 0;

    if (soldQty <= 0 || soldPrice <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid quantity or price!'), backgroundColor: Colors.red));
      return;
    }

    final availableQty = double.tryParse(stockItem['quantity'].toString().split(' ').first) ?? 0;
    if (availableQty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${stockItem['item']} is out of stock!'), backgroundColor: Colors.red));
      return;
    }

    if (soldQty > availableQty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Not enough stock available!'), backgroundColor: Colors.red));
      return;
    }

    final unit = stockItem['quantity'].toString().split(' ').last;

    setState(() {
      selectedItems[stockItem.id] = {'item': stockItem['item'], 'quantity': soldQty, 'price': soldPrice, 'unit': unit};
      total = selectedItems.values.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
      cartItemCount = selectedItems.length;
    });

    Navigator.pop(context);
  }

  Future<void> _completeSale() async {
    setState(() {
      isProcessingSale = true;
    });

    try {
      for (var entry in selectedItems.entries) {
        final itemId = entry.key;
        final soldQty = entry.value['quantity'];
        final soldPrice = entry.value['price'];

        final doc = FirebaseFirestore.instance.collection('stock').doc(itemId);
        final snapshot = await doc.get();
        final oldQtyStr = snapshot['quantity'].toString().split(' ').first;
        final unit = snapshot['quantity'].toString().split(' ').last;
        final restockAlert = double.tryParse(snapshot['restockAlert'].toString()) ?? 0;

        double oldQty = double.tryParse(oldQtyStr) ?? 0;
        double newQty = oldQty - soldQty;
        if (newQty < 0) newQty = 0;

        await doc.update({'quantity': '${newQty.toStringAsFixed(2)} $unit'});

        if (newQty <= restockAlert) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${snapshot['item']} is low in stock. Please restock.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Sale completed!'), backgroundColor: Colors.green.shade700));

      setState(() {
        selectedItems.clear();
        total = 0.0;
        cartItemCount = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to complete sale: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        isProcessingSale = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Item'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text('$cartItemCount', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(selectedItems: selectedItems, total: total, onSaleCompleted: () {}),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stock').orderBy('item').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final items = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final stockItem = items[index];
                    final availableQty = double.tryParse(stockItem['quantity'].toString().split(' ').first) ?? 0;
                    final restockAlert = double.tryParse(stockItem['restockAlert'].toString()) ?? 0;
                    final isLowStock = availableQty <= restockAlert;
                    final isOutOfStock = availableQty <= 0;

                    return Dismissible(
                      key: Key(stockItem.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        bool confirm = false;
                        await showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: Text('Delete "${stockItem['item']}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      confirm = true;
                                      Navigator.pop(context);
                                    },
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                        );
                        return confirm;
                      },
                      onDismissed: (_) async {
                        await FirebaseFirestore.instance.collection('stock').doc(stockItem.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${stockItem['item']} deleted'), backgroundColor: Colors.red),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            stockItem['item'],
                            style: TextStyle(color: isOutOfStock ? Colors.grey : Colors.black),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Available: ${stockItem['quantity']}",
                                style: TextStyle(color: isOutOfStock ? Colors.grey : Colors.black),
                              ),
                              Text(
                                "Selling Price: KSH ${stockItem['sellingPrice']}",
                                style: TextStyle(color: isOutOfStock ? Colors.grey : Colors.black),
                              ),
                              if (isLowStock && !isOutOfStock)
                                Text("⚠️ Restock needed", style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                          onTap: () {
                            if (isOutOfStock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${stockItem['item']} is out of stock.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              showSellDialog(stockItem);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (selectedItems.isNotEmpty) Divider(),
          if (selectedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selected Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...selectedItems.entries.map((entry) {
                    final item = entry.value;
                    return ListTile(
                      title: Text(item['item']),
                      subtitle: Text(
                        'Qty: ${item['quantity']} x KSH ${item['price']} = KSH ${item['quantity'] * item['price']}',
                      ),
                    );
                  }).toList(),
                  Divider(),
                  Text("Total: KSH $total", style: TextStyle(fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: isProcessingSale ? null : _completeSale,
                    child: isProcessingSale ? CircularProgressIndicator(color: Colors.white) : Text('Complete Sale'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
