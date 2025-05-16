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
    final String name = _nameController.text.trim();
    final String amount = _amountController.text.trim();

    if (name.isEmpty || amount.isEmpty) return;

    await _creditsCollection.add({'name': name, 'amount': amount, 'timestamp': Timestamp.now()});

    _nameController.clear();
    _amountController.clear();

    Navigator.of(context).pop();
  }

  void _editCredit(String docId, String currentName, String currentAmount) {
    _nameController.text = currentName;
    _amountController.text = currentAmount;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Credit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await _creditsCollection.doc(docId).update({
                    'name': _nameController.text.trim(),
                    'amount': _amountController.text.trim(),
                  });

                  _nameController.clear();
                  _amountController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _deleteCredit(String docId) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
            title: const Text('Add Credit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
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
              ElevatedButton(onPressed: _addCredit, child: const Text('Add')),
            ],
          ),
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
              final name = data['name'] as String? ?? 'Unknown';
              final amount = data['amount'] as String? ?? '0';

              final timestamp = data['timestamp'] as Timestamp;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Amount: KSH $amount\nDate: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editCredit(doc.id, name, amount);
                      } else if (value == 'delete') {
                        _deleteCredit(doc.id);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
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
