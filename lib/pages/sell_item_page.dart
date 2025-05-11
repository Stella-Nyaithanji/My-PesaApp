import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final Map<String, dynamic> selectedItems = {}; // {itemId: {item, qty, price}}
  double total = 0.0;

  void showSellDialog(DocumentSnapshot stockItem) {
    final qtyController = TextEditingController();
    final priceController = TextEditingController(text: stockItem['price'].toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Sell ${stockItem['item']}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Quantity Sold'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Selling Price'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {
                  _addSale(stockItem, qtyController, priceController, isCredit: false);
                },
                child: Text('Add Sale'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  _addSale(stockItem, qtyController, priceController, isCredit: true);
                },
                child: Text('Add as Credit'),
              ),
            ],
          ),
    );
  }

  void _addSale(
    DocumentSnapshot stockItem,
    TextEditingController qtyController,
    TextEditingController priceController, {
    required bool isCredit,
  }) {
    final soldQty = double.tryParse(qtyController.text) ?? 0;
    final soldPrice = double.tryParse(priceController.text) ?? 0;

    if (soldQty <= 0 || soldPrice <= 0) return;

    setState(() {
      selectedItems[stockItem.id] = {
        'item': stockItem['item'],
        'quantity': soldQty,
        'price': soldPrice,
        'isCredit': isCredit,
      };
      total = selectedItems.values.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
    });

    Navigator.pop(context);
  }

  void _completeSale() async {
    for (var entry in selectedItems.entries) {
      final itemId = entry.key;
      final soldQty = entry.value['quantity'];
      final isCredit = entry.value['isCredit'];

      if (isCredit) {
        await FirebaseFirestore.instance.collection('credits').add({
          'itemId': itemId,
          'item': entry.value['item'],
          'quantity': soldQty,
          'price': entry.value['price'],
          'timestamp': Timestamp.now(),
        });
        continue; // Skip stock update for credits
      }

      final doc = FirebaseFirestore.instance.collection('stock').doc(itemId);
      final snapshot = await doc.get();
      final oldQtyStr = snapshot['quantity'].toString().split(' ').first;
      final unit = snapshot['quantity'].toString().split(' ').last;
      double oldQty = double.tryParse(oldQtyStr) ?? 0;

      double newQty = oldQty - soldQty;
      if (newQty < 0) newQty = 0;

      await doc.update({'quantity': '${newQty.toStringAsFixed(2)} $unit'});
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Items sold successfully!'), backgroundColor: Colors.green.shade700));

    setState(() {
      selectedItems.clear();
      total = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sell Item')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stock').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final items = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final stockItem = items[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(stockItem['item'], overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Available: ${stockItem['quantity']}"),
                            Text("Buying Price: KSH ${stockItem['price']}"),
                          ],
                        ),
                        onTap: () => showSellDialog(stockItem),
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sold Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...selectedItems.values.map(
                    (item) => Text(
                      "${item['item']} - ${item['quantity']} @ KSH ${item['price']}${item['isCredit'] ? " (Credit)" : ""}",
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Total: KSH ${total.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _completeSale,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: Text("Sale Completed"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
