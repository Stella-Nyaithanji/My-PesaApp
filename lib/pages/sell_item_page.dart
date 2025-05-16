import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pesa_app/pages/cart_page.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  SellItemPageState createState() => SellItemPageState();
}

class SellItemPageState extends State<SellItemPage> {
  List<Map<String, dynamic>> cartItems = [];
  List<DocumentSnapshot> allItems = [];
  List<DocumentSnapshot> filteredItems = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStockItems();
  }

  Future<void> fetchStockItems() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('stock').orderBy('timestamp', descending: true).get();

      setState(() {
        allItems = snapshot.docs;
        filteredItems = allItems;
      });
    } catch (e) {
      print('Error fetching stock items: $e');
    }
  }

  void filterItems(String query) {
    setState(() {
      filteredItems =
          allItems.where((item) {
            final name = item['item'].toString().toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();
    });
  }

  void addToCart(DocumentSnapshot stockDoc, double quantity) {
    final data = stockDoc.data() as Map<String, dynamic>;
    final cartItem = {
      'docId': stockDoc.id,
      'item': data['item'],
      'quantity': quantity,
      'unit': data['unit'],
      'sellingPrice': data['sellingPrice'],
    };
    setState(() {
      cartItems.add({
        'docId': stockDoc.id,
        'item': stockDoc['item'],
        'quantity': quantity,
        'unit': stockDoc['unit'],
        'sellingPrice': stockDoc['sellingPrice'],
      });
    });
  }

  void showQuantityDialog(DocumentSnapshot item) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Quantity'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: 'e.g. 2'),
          ),
          actions: [
            TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600]),
              child: Text('Add to cart'),
              onPressed: () {
                final qty = double.tryParse(controller.text);
                if (qty != null && qty > 0) {
                  addToCart(item, qty);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Items'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green, Colors.teal])),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CartPage(
                            cartItems: cartItems,
                            onSaleCompleted: () {
                              setState(() {
                                cartItems.clear(); // Clear cart when sale completes
                              });
                            },
                          ),
                    ),
                  );
                },
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 10,
                    child: Text(cartItems.length.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: filterItems,
              decoration: InputDecoration(
                hintText: 'Search item...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final itemName = item['item'];
                final quantity = item['quantity'];
                final unit = item['unit'];
                final sellingPrice = item['sellingPrice'];
                final restockAlert = item['restockAlert'];

                final showRestock =
                    double.tryParse(quantity.toString()) != null && double.parse(quantity.toString()) <= restockAlert;

                return GestureDetector(
                  onTap: () => showQuantityDialog(item),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        showRestock ? '$itemName - Restock' : itemName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: showRestock ? Colors.red : Colors.black),
                      ),
                      subtitle: Text('$quantity $unit'),
                      trailing: Text(
                        'KSH $sellingPrice',
                        style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
