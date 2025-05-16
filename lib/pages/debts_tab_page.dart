import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebtsTabPage extends StatelessWidget {
  final String userId; // Pass from parent widget

  const DebtsTabPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('debts')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final debts = snapshot.data?.docs ?? [];

        if (debts.isEmpty) {
          return const Center(child: Text('No debts found.'));
        }

        return ListView.builder(
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final doc = debts[index];
            final data = doc.data() as Map<String, dynamic>;

            final customer = data['customerName'] ?? 'Unknown';
            final amount = data['amount'] ?? 0;
            final reason = data['reason'] ?? '';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                title: Text(
                  '$customer - KSH ${amount.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reason.isNotEmpty) Text('Reason: $reason'),
                    Text('Date: ${DateFormat.yMMMd().format(timestamp)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: () => _showEditDialog(context, doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final amountController = TextEditingController(text: data['amount'].toString());
    final reasonController = TextEditingController(text: data['reason'] ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Debt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')),
              ],
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Save'),
                onPressed: () async {
                  final newAmount = double.tryParse(amountController.text) ?? data['amount'];
                  final newReason = reasonController.text.trim();

                  await FirebaseFirestore.instance.collection('debts').doc(docId).update({
                    'amount': newAmount,
                    'reason': newReason,
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Debt'),
            content: const Text('Are you sure you want to delete this debt?'),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('debts').doc(docId).delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debt deleted successfully'), backgroundColor: Colors.redAccent),
                  );
                },
              ),
            ],
          ),
    );
  }
}
