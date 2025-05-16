import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_pesa_app/pages/firestore_collections_service.dart';

class AddDebtDialog extends StatefulWidget {
  const AddDebtDialog({super.key});

  @override
  AddDebtDialogState createState() => AddDebtDialogState();
  String? get userId => FirebaseAuth.instance.currentUser?.uid;
}

class AddDebtDialogState extends State<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _itemController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _amountPaidController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _supplierController.dispose();
    _itemController.dispose();
    _buyingPriceController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final supplierName = _supplierController.text.trim();
    final itemName = _itemController.text.trim();
    final buyingPrice = double.parse(_buyingPriceController.text.trim());
    final amountPaid = double.parse(_amountPaidController.text.trim());

    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirestoreCollectionsService().addSupplierDebt(
        supplierName: supplierName,
        amount: buyingPrice - amountPaid,
        reason: itemName,
        userId: userId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: const Text('Debt added successfully'), backgroundColor: Colors.teal));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add debt: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Debt', style: TextStyle(color: Colors.teal)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name',
                  icon: Icon(Icons.person, color: Colors.teal),
                ),
                validator: (value) => value!.isEmpty ? 'Enter supplier name' : null,
              ),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  icon: Icon(Icons.inventory, color: Colors.teal),
                ),
                validator: (value) => value!.isEmpty ? 'Enter item name' : null,
              ),
              TextFormField(
                controller: _buyingPriceController,
                decoration: const InputDecoration(
                  labelText: 'Buying Price',
                  icon: Icon(Icons.attach_money, color: Colors.teal),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Enter valid price' : null,
              ),
              TextFormField(
                controller: _amountPaidController,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  icon: Icon(Icons.payment, color: Colors.teal),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Enter valid amount' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Debt'),
        ),
      ],
    );
  }
}
