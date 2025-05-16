import 'package:flutter/material.dart';
import 'firestore_collections_service.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onSaleCompleted;

  const CartPage({super.key, required this.cartItems, required this.onSaleCompleted});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();

  final FirestoreCollectionsService _firestoreService = FirestoreCollectionsService();

  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in widget.cartItems) {
      final dynamic quantity = item['quantity'] ?? 0;
      final sellingPrice = (item['sellingPrice'] ?? 0).toDouble();

      double quantityValue;
      if (quantity is num) {
        quantityValue = quantity.toDouble();
      } else if (quantity is String) {
        quantityValue = double.tryParse(quantity) ?? 0;
      } else {
        quantityValue = 0;
      }

      total += quantityValue * sellingPrice;
    }
    setState(() {
      _total = total;
    });
  }

  Future<void> _completeSale() async {
    final paid = double.tryParse(_cashController.text.trim()) ?? 0.0;
    final customerName = _customerNameController.text.trim();

    if (paid < _total && customerName.isEmpty) {
      _showSnackBar('Please enter customer name for credit sales.', isError: true);
      return;
    }

    try {
      // Ensure all cart items have a docId
      for (var item in widget.cartItems) {
        if (!item.containsKey('docId') || (item['docId'] == null || item['docId'] == '')) {
          throw Exception('Missing docId in one or more cart items.');
        }
      }

      // Update stock quantities in batch
      await _firestoreService.updateStockQuantities(widget.cartItems);

      // Handle credit and change
      if (paid < _total) {
        await _firestoreService.addCreditRecord(
          customerName: customerName,
          amount: _total - paid,
          cartItems: widget.cartItems,
        );
        _showSnackBar('Sale completed on credit for $customerName.');
      } else if (paid > _total && customerName.isNotEmpty) {
        await _firestoreService.addCreditRecord(
          customerName: customerName,
          amount: paid - _total,
          cartItems: [],
          reason: 'Extra cash left at store',
        );
        _showSnackBar('Change KSH ${(paid - _total).toStringAsFixed(2)} left for $customerName.');
      } else {
        _showSnackBar('Sale completed successfully.');
      }

      // Clear cart and close page
      widget.cartItems.clear();
      widget.onSaleCompleted();
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error completing sale: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final snackBarColor = isError ? Colors.redAccent : Colors.teal.shade700;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: snackBarColor, duration: const Duration(seconds: 3)),
    );
  }

  AppBar _buildGradientAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: const Text('Cart'),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child:
                  widget.cartItems.isEmpty
                      ? const Center(child: Text('No items in cart'))
                      : ListView.builder(
                        itemCount: widget.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = widget.cartItems[index];
                          final dynamic quantity = item['quantity'] ?? 0;
                          final sellingPrice = (item['sellingPrice'] ?? 0).toDouble();
                          final unit = item['unit']?.toString() ?? '';

                          double quantityValue;
                          if (quantity is num) {
                            quantityValue = quantity.toDouble();
                          } else if (quantity is String) {
                            quantityValue = double.tryParse(quantity) ?? 0;
                          } else {
                            quantityValue = 0;
                          }

                          return Card(
                            child: ListTile(
                              title: Text(item['item'] ?? ''),
                              subtitle: Text('$quantity $unit x KSH $sellingPrice'),
                              trailing: Text(
                                'KSH ${(quantityValue * sellingPrice).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 10),
            Text(
              'Total: KSH ${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cash received', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer name (if credit or change)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),

              onPressed: _completeSale,
              child: const Text('Complete Sale', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
