import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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
    required String reason,
    required List<Map<String, dynamic>> cart,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      log('User not authenticated when trying to add customer credit.');
      throw Exception('User not authenticated');
    }

    log('Adding credit for customer: $customerName, amount: $amount, reason: $reason');

    // Reference to the customer's credit document
    final customerDocRef = _firestore.collection('credits').doc(customerName);

    final docSnapshot = await customerDocRef.get();

    double previousBalance = 0;
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data['amount'] != null) {
        previousBalance = (data['amount'] as num).toDouble();
        log('Found existing amount: $previousBalance for customer: $customerName');
      }
    } else {
      log('No existing credit document for customer: $customerName, will create new.');
    }

    double newBalance = previousBalance + amount;
    log('Updating credit amount from $previousBalance to $newBalance for customer: $customerName');

    // Update or create the customer's credit document
    await customerDocRef.set({
      'userId': uid,
      'customerName': customerName,
      'amount': newBalance,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    log('Credit document updated for customer: $customerName');

    // Add an entry to creditHistory subcollection
    await customerDocRef.collection('creditHistory').add({
      'type': reason,
      'amount': amount,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'timestamp': FieldValue.serverTimestamp(),
      'cartItems': cart,
    });

    log('Credit history entry added for customer: $customerName');
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

      final soldQty =
          (item['quantity'] ?? 0) is num
              ? (item['quantity'] as num).toDouble()
              : double.tryParse(item['quantity'].toString()) ?? 0.0;

      final newQty = currentQty - soldQty;

      if (newQty < 0) throw Exception('Not enough stock for ${item['item']}');

      batch.update(docRef, {'quantity': newQty});
    }

    await batch.commit();
  }

  /// Add a credit record (for credit sales or extra cash left)

  final CollectionReference _creditsCollection = FirebaseFirestore.instance.collection('credits');

  Future<bool> addCredit({required String customerName, required double amount}) async {
    if (customerName.isEmpty || amount <= 0) return false;

    try {
      await _creditsCollection.add({'customerName': customerName, 'amount': amount, 'timestamp': Timestamp.now()});
      return true;
    } catch (e) {
      print('Error adding credit: $e');
      return false;
    }
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

  Future<void> logCreditTransaction({
    required String creditDocId,
    required String type, // 'payment', 'storeCredit', 'sale'
    required double amount,
    required double previousBalance,
    required double newBalance,
    required String customerName,
  }) async {
    await _firestore.collection('credits').doc(creditDocId).collection('creditHistory').add({
      'type': type,
      'amount': amount,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'timestamp': FieldValue.serverTimestamp(),
      'customerName': customerName,
    });
  }

  /// Record a completed sale into the 'sales' collection
  Future<void> recordSale({
    required List<Map<String, dynamic>> items,
    required double total,
    required double paid,
    required bool isCredit,
    required double change,
    String? customerName,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('User not authenticated');
    final data = {
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'items': items,
      'total': total,
      'paid': paid,
      'change': change,
      'isCredit': isCredit,
      'timestamp': FieldValue.serverTimestamp(),
      if (isCredit && customerName != null) 'customerName': customerName,
    };
    await _firestore.collection('sales').add(data);
  }

  /// Fetch all sale records for the current user
  Future<List<QueryDocumentSnapshot>> fetchSalesRecords() async {
    final uid = userId;
    if (uid == null) throw Exception('User not authenticated');
    final snapshot =
        await _firestore
            .collection('sales')
            .where('userId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .get();
    return snapshot.docs;
  }

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a profile image and returns the download URL
  Future<String> uploadProfileImage(File imageFile) async {
    if (userId == null) throw Exception('User not authenticated');

    final ref = _storage.ref().child('profileImages').child('$userId.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    // Optionally update user profile data in Firestore (if you have a user profile collection)
    await _firestore.collection('users').doc(userId).update({'profileImageUrl': url});

    return url;
  }
}
