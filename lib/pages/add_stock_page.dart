import 'package:flutter/material.dart';
import 'firestore_collections_service.dart';

class AddStockPage extends StatefulWidget {
  const AddStockPage({super.key});

  @override
  State<AddStockPage> createState() => AddStockPageState();
}

class AddStockPageState extends State<AddStockPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _restockAlertController = TextEditingController();
  final TextEditingController _buyingPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  String _selectedUnit = 'kilograms';
  final List<String> _unitOptions = [
    'kilograms',
    'grams',
    'pieces',
    'litres',
    'satchets',
    'packets',
    'crates',
    'bottles',
    'containers',
  ];

  final FirestoreCollectionsService _firestoreService = FirestoreCollectionsService();

  Future<void> _addStockItem() async {
    if (_formKey.currentState!.validate()) {
      final item = _itemController.text;
      final quantity = double.tryParse(_quantityController.text);
      final restockAlert = double.tryParse(_restockAlertController.text);
      final sellingPrice = double.tryParse(_sellingPriceController.text);
      final buyingPrice = double.tryParse(_buyingPriceController.text);

      if (quantity == null || restockAlert == null || sellingPrice == null || buyingPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter valid values for quantity, restock alert, selling price, and buying price.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await _firestoreService.addStockItem(
          item: item,
          quantity: quantity,
          unit: _selectedUnit,
          restockAlert: restockAlert,
          sellingPrice: sellingPrice,
          buyingPrice: buyingPrice,
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$item added successfully!'), backgroundColor: Colors.green));

        _itemController.clear();
        _quantityController.clear();
        _restockAlertController.clear();
        _buyingPriceController.clear();
        _sellingPriceController.clear();
        setState(() {
          _selectedUnit = 'kilograms';
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add item: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Stock Item'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _itemController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                onChanged: (newValue) {
                  setState(() {
                    _selectedUnit = newValue!;
                  });
                },
                items:
                    _unitOptions
                        .map((String unit) => DropdownMenuItem<String>(value: unit, child: Text(unit)))
                        .toList(),
                decoration: InputDecoration(labelText: 'Quantity Type (Unit)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a unit';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _restockAlertController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Restock Alert Quantity'),
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid restock alert quantity';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _buyingPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Buying Price'),
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid buying price';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _sellingPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Selling Price'),
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid selling price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addStockItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: Text('Add Stock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
