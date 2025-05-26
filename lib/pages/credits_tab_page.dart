import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreditsTabPage extends StatefulWidget {
  const CreditsTabPage({super.key});

  @override
  State<CreditsTabPage> createState() => _CreditsTabPageState();
}

class _CreditsTabPageState extends State<CreditsTabPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final CollectionReference _creditsCollection = FirebaseFirestore.instance.collection('credits');

  void _addCredit() async {
    final String customerName = _nameController.text.trim();
    final String amount = _amountController.text.trim();

    if (customerName.isEmpty || amount.isEmpty) return;

    await _creditsCollection.add({
      'customerName': customerName,
      'amount': double.tryParse(amount) ?? 0.0,
      'timestamp': Timestamp.now(),
    });

    _nameController.clear();
    _amountController.clear();

    Navigator.of(context).pop();
  }

  void _editCredit(String docId, String currentName, String currentAmount) {
    final TextEditingController _amountPaidController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Pay Credit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: currentName),
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              TextField(
                controller: TextEditingController(text: currentAmount),
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Current Amount (KSH)'),
              ),
              TextField(
                controller: _amountPaidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Paid (KSH)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                final paidStr = _amountPaidController.text.trim();
                if (paidStr.isEmpty) return;
                final paid = double.tryParse(paidStr) ?? 0;
                final current = double.tryParse(currentAmount) ?? 0;
                final newAmount = (current - paid).clamp(0, current);

                await _creditsCollection.doc(docId).update({'amount': newAmount});

                await _creditsCollection.doc(docId).collection('creditHistory').add({
                  'type': 'payment',
                  'amount': paid,
                  'previousBalance': current,
                  'newBalance': newAmount,
                  'timestamp': FieldValue.serverTimestamp(),
                  'customerName': currentName,
                });

                Navigator.of(context).pop();
              },
              child: const Text('Apply Payment'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCredit(String docId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Delete Credit'),
            content: const Text('Are you sure you want to delete this credit record?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await _creditsCollection.doc(docId).delete();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddCreditDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Add Credit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Credit Amount'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _nameController.clear();
                  _amountController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addCredit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _viewCreditHistory(String docId, String customerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'Credit History - $customerName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _creditsCollection
                            .doc(docId)
                            .collection('creditHistory')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(padding: EdgeInsets.all(16), child: Text('Error loading history'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(padding: EdgeInsets.all(16), child: Text('No credit history available'));
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          final amount = (data['amount'] ?? 0) as num;
                          final prev = (data['previousBalance'] ?? 0) as num;
                          final newBal = (data['newBalance'] ?? 0) as num;
                          final ts = data['timestamp'] as Timestamp?;
                          final dateStr = ts != null ? DateFormat.yMMMd().add_jm().format(ts.toDate()) : '';

                          final type = data['type'] ?? 'payment';

                          if (type.toString().toLowerCase().contains('credit')) {
                            final List cart = data['cartItems'] ?? [];

                            return ExpansionTile(
                              leading: const Icon(Icons.shopping_cart, color: Colors.teal),
                              title: Text(
                                'Credit Sale - KSH ${amount.toDouble().toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('Date: $dateStr'),
                              children: [
                                ...cart.map<Widget>((item) {
                                  final String itemName = item['item'] ?? '';
                                  final quantity = (item['quantity'] ?? 0).toDouble();
                                  final unit = item['unit'] ?? '';
                                  final price = (item['sellingPrice'] ?? 0).toDouble();

                                  return ListTile(
                                    dense: true,
                                    title: Text(itemName, style: const TextStyle(color: Colors.teal)),
                                    subtitle: Text('$quantity $unit x KSH ${price.toStringAsFixed(2)}'),
                                  );
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total: KSH ${cart.fold<double>(0, (sum, item) => sum + ((item['quantity'] ?? 0) * (item['sellingPrice'] ?? 0))).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return ListTile(
                              leading: const Icon(Icons.history, color: Colors.teal),
                              title: Text('Paid: KSH ${amount.toDouble().toStringAsFixed(2)}'),
                              subtitle: Text(
                                'Previous: KSH ${prev.toDouble().toStringAsFixed(2)} → Now: KSH ${newBal.toDouble().toStringAsFixed(2)}\n$dateStr',
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credits'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.green, Colors.teal])),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _creditsCollection.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading credits'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No credit records found'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final customerName = data['customerName'] ?? 'Unknown';
              final rawAmount = data['amount'] as num?;
              final amount = rawAmount != null ? (rawAmount.toDouble()).toStringAsFixed(2) : '0.00';
              final timestamp = data['timestamp'] as Timestamp;

              return GestureDetector(
                onTap: () => _viewCreditHistory(doc.id, customerName),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    subtitle: Text(
                      'Amount: KSH $amount\nDate: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editCredit(doc.id, customerName, amount);
                        } else if (value == 'delete') {
                          _deleteCredit(doc.id);
                        }
                      },
                      itemBuilder:
                          (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: const [
                                  Icon(Icons.edit, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: const [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCreditDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
