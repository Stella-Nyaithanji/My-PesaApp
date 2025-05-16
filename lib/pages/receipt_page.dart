import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const ReceiptPage({super.key, required this.cartItems, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Receipt'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Thank you for your purchase!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    title: Text(item['item']),
                    subtitle: Text('${item['quantity']} ${item['unit']} x KSH ${item['price']}'),
                    trailing: Text('KSH ${item['total'].toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            const Divider(thickness: 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  'KSH ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
