import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firestore_collections_service.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onSaleCompleted;

  const CartPage({super.key, required this.cartItems, required this.onSaleCompleted});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final FirestoreCollectionsService _firestoreService = FirestoreCollectionsService();

  final NumberFormat _formatter = NumberFormat("#,##0.00", "en_US");
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in widget.cartItems) {
      final quantity = item['quantity'];
      final sellingPrice = (item['sellingPrice'] ?? 0).toDouble();
      double qtyValue = quantity is num ? quantity.toDouble() : double.tryParse(quantity.toString()) ?? 0.0;
      total += qtyValue * sellingPrice;
    }
    setState(() {
      _total = total;
    });
  }

  Future<void> _completeSale() async {
    final paid = double.tryParse(_cashController.text.trim()) ?? 0.0;
    final customerName = _customerNameController.text.trim();
    final isCredit = paid < _total;
    final change = paid > _total ? paid - _total : 0.0;

    if (isCredit && customerName.isEmpty) {
      _showSnackBar('Please enter customer name for credit sales.', isError: true);
      return;
    }

    final cartAsMaps =
        widget.cartItems
            .map(
              (item) => {
                'docId': item['docId'], // use bracket notation
                'item': item['item'],
                'quantity': item['quantity'],
                'unit': item['unit'],
                'sellingPrice': item['sellingPrice'],
                'buyingPrice': item['buyingPrice'],
              },
            )
            .toList();

    try {
      await _firestoreService.updateStockQuantities(widget.cartItems);

      await _firestoreService.recordSale(
        items: cartAsMaps, // pass converted list here
        total: _total,
        paid: paid,
        isCredit: isCredit,
        change: change,
        customerName: isCredit ? customerName : null,
      );

      if (isCredit) {
        log('Cart to save: $cartAsMaps'); // log converted cart

        await _firestoreService.addCustomerCredit(
          customerName: customerName,
          amount: _total - paid,
          reason: 'Credit Sale',
          cart: cartAsMaps, // pass converted list here as well
        );
        _showSnackBar('Sale completed on credit for $customerName.');
      } else if (change > 0) {
        await _firestoreService.logCustomerChange(
          customerName: customerName,
          changeAmount: change,
          reason: 'Change returned',
        );
        _showSnackBar('Change KSH ${_formatter.format(change)} returned.');
      } else {
        _showSnackBar('Sale completed successfully.');
      }

      widget.cartItems.clear();
      widget.onSaleCompleted();
      _cashController.clear();
      _customerNameController.clear();
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error completing sale: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.teal.shade700,
        duration: const Duration(seconds: 3),
      ),
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
    final paid = double.tryParse(_cashController.text.trim()) ?? 0.0;
    final balance = paid - _total;

    String balanceMessage = '';
    if (balance > 0) {
      balanceMessage = 'Change to return: KSH ${_formatter.format(balance)}';
    } else if (balance < 0) {
      balanceMessage = 'Credit: KSH ${_formatter.format(-balance)}';
    } else if (paid > 0) {
      balanceMessage = 'Exact amount received.';
    }

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
                          final qty = item['quantity'];
                          final sellingPrice = (item['sellingPrice'] ?? 0).toDouble();
                          final unit = item['unit']?.toString() ?? '';
                          double qtyValue = qty is num ? qty.toDouble() : double.tryParse(qty.toString()) ?? 0.0;

                          return Card(
                            child: ListTile(
                              title: Text(item['item'] ?? ''),
                              subtitle: Text('$qty $unit x KSH ${_formatter.format(sellingPrice)}'),
                              trailing: Text(
                                'KSH ${_formatter.format(qtyValue * sellingPrice)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 10),
            Text(
              'Total: KSH ${_formatter.format(_total)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Cash received', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            if (balanceMessage.isNotEmpty)
              Text(
                balanceMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: balance < 0 ? Colors.red : Colors.teal.shade700,
                  fontWeight: FontWeight.w600,
                ),
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
              onPressed: (widget.cartItems.isEmpty || _cashController.text.trim().isEmpty) ? null : _completeSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Complete Sale', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
