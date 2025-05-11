import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddStockPage extends StatefulWidget {
  const AddStockPage({super.key});

  @override
  State<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends State<AddStockPage> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController itemController = TextEditingController();
  final TextEditingController qtyValueController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController debtItemController = TextEditingController();
  final TextEditingController debtQtyController = TextEditingController();
  final TextEditingController debtPriceController = TextEditingController();

  String selectedUnit = 'pieces';
  DateTime? stockDate;
  DateTime? debtDate;

  final List<String> units = [
    'grams',
    'kilograms',
    'litres',
    'pkts',
    'bottles',
    'crates',
    'packets',
    'satchets',
    'pieces',
    'others',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Stock")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: itemController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Enter item name' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyValueController,
                      decoration: InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedUnit,
                    items:
                        units.map((unit) {
                          return DropdownMenuItem(value: unit, child: Text(unit));
                        }).toList(),
                    onChanged: (value) {
                      setState(() => selectedUnit = value!);
                    },
                  ),
                ],
              ),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price per unit (KSH)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(
                  stockDate == null ? 'Select Stock Date' : 'Date: ${DateFormat('dd/MM/yyyy').format(stockDate!)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => stockDate = picked);
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate() && stockDate != null) {
                    FirebaseFirestore.instance
                        .collection('stock')
                        .add({
                          'item': itemController.text.trim(),
                          'quantity': '${qtyValueController.text.trim()} $selectedUnit',
                          'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                          'date': DateFormat('yyyy-MM-dd').format(stockDate!),
                          'timestamp': FieldValue.serverTimestamp(),
                        })
                        .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Stock added successfully!'),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          Future.delayed(Duration(milliseconds: 800), () {
                            Navigator.pop(context);
                          });
                        })
                        .catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red.shade700),
                          );
                        });
                  }
                },
                child: Text('Save Stock'),
              ),
              SizedBox(height: 10),
              OutlinedButton(onPressed: () => showDebtDialog(context), child: Text('Add as Credit (Debt)')),
            ],
          ),
        ),
      ),
    );
  }

  void showDebtDialog(BuildContext context) {
    debtDate = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selectDueDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                setModalState(() => debtDate = picked);
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: supplierController, decoration: InputDecoration(labelText: 'Supplier Name')),
                  TextField(controller: debtItemController, decoration: InputDecoration(labelText: 'Item Description')),
                  TextField(controller: debtQtyController, decoration: InputDecoration(labelText: 'Quantity')),
                  TextField(
                    controller: debtPriceController,
                    decoration: InputDecoration(labelText: 'Price (KSHs)'),
                    keyboardType: TextInputType.number,
                  ),
                  ListTile(
                    title: Text(
                      debtDate == null ? 'Select Date' : 'Date: ${DateFormat('dd/MM/yyyy').format(debtDate!)}',
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: selectDueDate,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          if (debtDate != null) {
                            final qty = double.tryParse(debtQtyController.text) ?? 0;
                            final price = double.tryParse(debtPriceController.text) ?? 0;
                            final amount = qty * price;

                            FirebaseFirestore.instance
                                .collection('debts')
                                .add({
                                  'supplier': supplierController.text.trim(),
                                  'item': debtItemController.text.trim(),
                                  'quantity': qty,
                                  'price': price,
                                  'amount': amount,
                                  'repaid': 0.0,
                                  'balance': amount,
                                  'type': 'creditor', // source of goods
                                  'date': DateFormat('yyyy-MM-dd').format(debtDate!),
                                  'timestamp': FieldValue.serverTimestamp(),
                                })
                                .then((_) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debt recorded.')));
                                  supplierController.clear();
                                  debtItemController.clear();
                                  debtQtyController.clear();
                                  debtPriceController.clear();
                                });
                          }
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
