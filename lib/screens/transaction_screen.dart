import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kasir/pages/cart_item.dart';
import 'package:intl/intl.dart'; // Import intl package for formatting

class TransactionScreen extends StatefulWidget {
  final List<CartItem> cart;
  TransactionScreen({required this.cart});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  double totalPrice = 0;

  // Function to recalculate total price based on updated cart
  void calculateTotalPrice() {
    setState(() {
      totalPrice = widget.cart.fold(0, (sum, item) => sum + item.totalPrice);
    });
  }

  // Function to save the transaction
  Future<void> saveTransaction() async {
    final transactionData = {
      'items': widget.cart
          .map((item) => {
                'categoryId': item.categoryId,
                'quantity': item.quantity,
                'price': item.price,
                'totalPrice': item.totalPrice,
              })
          .toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'totalPrice': totalPrice,
    };

    try {
      // Save the transaction to Firestore
      await FirebaseFirestore.instance.collection('transactions').add(transactionData);

      // Reduce stock for each product in the transaction
      for (var item in widget.cart) {
        final querySnapshot = await FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: item.categoryId).get();

        if (querySnapshot.docs.isNotEmpty) {
          final productRef = querySnapshot.docs.first.reference;

          // Using a transaction to update product stock atomically
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(productRef);

            if (snapshot.exists) {
              final currentStock = snapshot.data()?['stock'] ?? 0;
              final newStock = currentStock - item.quantity;

              // Ensure stock doesn't go negative
              transaction.update(productRef, {'stock': newStock < 0 ? 0 : newStock});
            }
          });
        }
      }

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan dan stok diperbarui!')),
      );
    } catch (e) {
      print('Error saving transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    }

    // Clear the cart after the transaction is completed
    setState(() {
      widget.cart.clear();
      totalPrice = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    calculateTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    // Format the total price using NumberFormat
    final totalPriceFormatted = NumberFormat('#,##0', 'id_ID').format(totalPrice);

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Transaksi')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final item = widget.cart[index];
                // Format the item price and total price
                final priceFormatted = NumberFormat('#,##0', 'id_ID').format(item.price);
                final itemTotalFormatted = NumberFormat('#,##0', 'id_ID').format(item.totalPrice);

                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Harga: Rp $priceFormatted | Jumlah: ${item.quantity}'),
                  trailing: Text('Total: Rp $itemTotalFormatted'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Total Harga: Rp $totalPriceFormatted'),
          ),
          ElevatedButton(
            onPressed: saveTransaction,
            child: const Text('Simpan Transaksi'),
          ),
        ],
      ),
    );
  }
}
