import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewDebtsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Debts"), backgroundColor: Colors.teal),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('debts').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            var debts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: debts.length,
              itemBuilder: (context, index) {
                var debt = debts[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    title: Text('${debt['supplier']} - ${debt['item']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Qty: ${debt['quantity']} | Price: ${debt['price']} KSH'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
