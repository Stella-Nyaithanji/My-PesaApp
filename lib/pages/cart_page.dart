import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  final Map<String, dynamic> selectedItems;
  final double total;
  final VoidCallback onSaleCompleted;

  const CartPage({super.key, required this.selectedItems, required this.total, required this.onSaleCompleted});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<String, dynamic> _cartItems;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cartItems = Map.from(widget.selectedItems);
  }

  double get total => _cartItems.values.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));

  void _editItem(String key, Map<String, dynamic> item) {
    final qtyController = TextEditingController(text: item['quantity'].toString());
    final priceController = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit ${item['item']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newQty = double.tryParse(qtyController.text) ?? item['quantity'];
                  final newPrice = double.tryParse(priceController.text) ?? item['price'];

                  setState(() {
                    _cartItems[key]['quantity'] = newQty;
                    _cartItems[key]['price'] = newPrice;
                  });

                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _removeItem(String key) {
    setState(() {
      _cartItems.remove(key);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item removed from cart'), backgroundColor: Colors.orange));
  }

  Future<void> _completeSale() async {
    setState(() => isProcessing = true);

    for (var entry in _cartItems.entries) {
      final itemId = entry.key;
      final itemData = entry.value;

      final soldQty = itemData['quantity'];
      final soldPrice = itemData['price'];
      final isCredit = itemData['isCredit'] ?? false;
      final customerName = (itemData['customer'] ?? '').toString();
      final finalCustomer = customerName.isEmpty ? 'Customer' : customerName;

      final docRef = FirebaseFirestore.instance.collection('stock').doc(itemId);
      final snapshot = await docRef.get();

      final quantityString = snapshot['quantity'].toString();
      final quantityParts = quantityString.split(' ');

      double oldQty = 0;
      String unit = 'unit';

      if (quantityParts.length >= 2) {
        oldQty = double.tryParse(quantityParts[0]) ?? 0;
        unit = quantityParts[1];
      }

      double newQty = oldQty - soldQty;
      if (newQty < 0) newQty = 0;

      // Update stock
      await docRef.update({'quantity': '${newQty.toStringAsFixed(2)} $unit'});

      // Save credit sale to 'credits'
      if (isCredit) {
        await FirebaseFirestore.instance.collection('credits').add({
          'customer': finalCustomer,
          'item': itemData['item'],
          'quantity': soldQty.toString(),
          'price': soldPrice,
          'balance': soldQty * soldPrice,
          'type': 'sale',
          'date': DateTime.now().toString().split(' ')[0],
          'timestamp': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        });
      }
    }

    setState(() => isProcessing = false);
    widget.onSaleCompleted();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Sale completed successfully!'), backgroundColor: Colors.green.shade700),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = _cartItems.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart Summary'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Items to Sell:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final key = items[index].key;
                  final item = items[index].value;
                  final isCredit = item['isCredit'] ?? false;
                  final customer = item['customer'] ?? 'Customer';

                  return Card(
                    child: ListTile(
                      title: Text(item['item']),
                      subtitle: Text(
                        "${item['quantity']} ${item['unit']} @ KSH ${item['price']} " +
                            (isCredit ? "(Credit to $customer)" : "(Cash)"),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => _editItem(key, item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(key),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              "Total: KSH ${total.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                  onPressed: _cartItems.isEmpty ? null : _completeSale,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Sale Completed'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size.fromHeight(50)),
                ),
          ],
        ),
      ),
    );
  }
}
