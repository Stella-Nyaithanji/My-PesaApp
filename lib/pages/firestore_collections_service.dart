import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreCollectionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Reference to the stock collection
  CollectionReference get stockCollection => _firestore.collection('stock');

  // Add stock item
  Future<void> addStockItem({
    required String item,
    required double quantity,
    required String unit,
    required double restockAlert,
    required double sellingPrice,
    required double buyingPrice,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    await stockCollection.add({
      'item': item,
      'quantity': quantity,
      'unit': unit,
      'restockAlert': restockAlert,
      'sellingPrice': sellingPrice,
      'buyingPrice': buyingPrice,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  // Update stock item
  Future<void> updateStockItem({
    required String docId,
    required String item,
    required double quantity,
    required String unit,
    required double sellingPrice,
    required double restockAlert,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    await stockCollection.doc(docId).update({
      'item': item,
      'quantity': quantity,
      'unit': unit,
      'sellingPrice': sellingPrice,
      'restockAlert': restockAlert,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Delete stock item
  Future<void> deleteStockItem(String docId) async {
    if (userId == null) throw Exception('User not authenticated');

    await stockCollection.doc(docId).delete();
  }

  // Log a customer credit
  Future<void> addCustomerCredit({
    required String customerName,
    required double amount,
    required List<Map<String, dynamic>> items,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    log('Saving credit for userId: $userId');
    await _firestore.collection('credits').add({
      'customerName': customerName,
      'amount': amount,
      'items': items,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  // Log a supplier debt
  Future<void> addSupplierDebt({
    required String supplierName,
    required double amount,
    required String reason,
    required String userId,
  }) async {
    if (userId.isEmpty) throw Exception('User not authenticated');
    log('Saving supplier debt for userId: $userId');
    await FirebaseFirestore.instance.collection('debts').add({
      'supplierName': supplierName,
      'amount': amount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  // Log customer change (excess paid to be kept for next time)
  Future<void> logCustomerChange({
    required String customerName,
    required double changeAmount,
    required String reason, // e.g. "Paid extra, store credit"
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('change').add({
      'customerName': customerName,
      'changeAmount': changeAmount,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  Future<List<DocumentSnapshot>> fetchStockItems() async {
    if (userId == null) throw Exception('User not authenticated');

    final snapshot =
        await _firestore
            .collection('stock')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    return snapshot.docs;
  }

  Future<void> updateStockQuantities(List<Map<String, dynamic>> cartItems) async {
    final batch = _firestore.batch();

    for (var item in cartItems) {
      final docId = item['docId'] as String?;
      if (docId == null) throw Exception('Missing docId in cart item');

      final docRef = stockCollection.doc(docId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) throw Exception('Document not found for $docId');

      final rawQty = docSnapshot.get('quantity');
      final currentQty = rawQty is String ? double.tryParse(rawQty) ?? 0.0 : rawQty as double;

      final soldQty = (item['quantity'] ?? 0).toDouble();
      final newQty = currentQty - soldQty;

      if (newQty < 0) throw Exception('Not enough stock for ${item['item']}');

      batch.update(docRef, {'quantity': newQty});
    }

    await batch.commit();
  }

  /// Add a credit record (for credit sales or extra cash left)
  Future<void> addCreditRecord({
    required String customerName,
    required double amount,
    required List<Map<String, dynamic>> cartItems,
    String? reason,
  }) async {
    final data = {'customerName': customerName, 'timestamp': Timestamp.now()};

    if (reason != null) {
      data['reason'] = reason;
      data['creditAmount'] = amount;
    } else {
      data['amountOwed'] = amount;
      data['items'] = cartItems;
    }

    await _firestore.collection('credits').add(data);
  }

  Future<void> updateCredit({required String docId, required Map<String, dynamic> updatedData}) async {
    if (userId == null) throw Exception('User not authenticated');

    log('Starting Firestore update for credit $docId...');
    await _firestore.collection('credits').doc(docId).update(updatedData);
    log('Firestore update completed for credit $docId.');
  }

  Future<void> updateDebt({required String docId, required Map<String, dynamic> updatedData}) async {
    if (userId == null) throw Exception('User not authenticated');

    log('Starting Firestore update for debt $docId...');
    await _firestore.collection('debts').doc(docId).update(updatedData);
    log('Firestore update completed for debt $docId.');
  }

  Future<void> applyPaymentToCredit({required String docId, required double paymentAmount}) async {
    if (userId == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('credits').doc(docId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) throw Exception('Credit document not found');

    final data = docSnapshot.data() as Map<String, dynamic>;
    double currentAmount = 0;

    // Check if amount or amountOwed field exists
    if (data.containsKey('amount')) {
      currentAmount = (data['amount'] as num).toDouble();
    } else if (data.containsKey('amountOwed')) {
      currentAmount = (data['amountOwed'] as num).toDouble();
    } else {
      throw Exception('No credit amount field found');
    }

    double newAmount = currentAmount - paymentAmount;
    if (newAmount < 0) newAmount = 0;

    // Prepare updated data depending on the field present
    Map<String, dynamic> updatedData = {};
    if (data.containsKey('amount')) {
      updatedData['amount'] = newAmount;
    } else {
      updatedData['amountOwed'] = newAmount;
    }

    await docRef.update(updatedData);
  }
}

Future<void> convertStockQuantitiesToDouble() async {
  final firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    log('User not authenticated');
    return;
  }

  final snapshot = await firestore.collection('stock').where('userId', isEqualTo: userId).get();

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final quantity = data['quantity'];

    if (quantity is String) {
      final parsedQuantity = double.tryParse(quantity);

      if (parsedQuantity != null) {
        log('Updating ${doc.id} → $parsedQuantity');
        await firestore.collection('stock').doc(doc.id).update({'quantity': parsedQuantity});
      } else {
        log('Failed to parse quantity for ${doc.id}: $quantity');
      }
    } else {
      log('Quantity already a number for ${doc.id}');
    }
  }

  log('✔ Quantity conversion completed.');
}
