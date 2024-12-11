import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kasir/pages/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import QR code package

class TransactionScreen extends StatefulWidget {
  final List<CartItem> cart;

  TransactionScreen({required this.cart});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  double totalPrice = 0;
  String selectedPaymentMethod = 'Cash'; // Default payment method

  @override
  void initState() {
    super.initState();
    calculateTotalPrice();
  }

  void calculateTotalPrice() {
    setState(() {
      totalPrice = widget.cart.fold(0, (sum, item) => sum + item.totalPrice);
    });
  }

  void increaseQuantity(int index) {
    setState(() {
      widget.cart[index].quantity++; // Menambah jumlah barang
    });
    calculateTotalPrice(); // Menghitung total harga setelah perubahan jumlah barang
  }

  void decreaseQuantity(int index) {
    setState(() {
      if (widget.cart[index].quantity > 1) {
        widget.cart[index].quantity--; // Mengurangi jumlah barang
      }
    });
    calculateTotalPrice(); // Menghitung total harga setelah perubahan jumlah barang
  }

  void removeItem(int index) {
    setState(() {
      widget.cart.removeAt(index);
    });
    calculateTotalPrice();
  }

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
      'paymentMethod': selectedPaymentMethod,
    };

    try {
      await FirebaseFirestore.instance.collection('transactions').add(transactionData);

      // Mengurangi stok berdasarkan quantity yang dipilih
      for (var item in widget.cart) {
        final querySnapshot = await FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: item.categoryId).get();

        if (querySnapshot.docs.isNotEmpty) {
          final productRef = querySnapshot.docs.first.reference;

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(productRef);
            if (snapshot.exists) {
              final currentStock = snapshot.data()?['stock'] ?? 0;
              final newStock = currentStock - item.quantity; // Mengurangi stok sesuai quantity
              transaction.update(productRef, {'stock': newStock < 0 ? 0 : newStock});
            }
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil disimpan dan stok diperbarui!')),
        );
        widget.cart.clear();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  void _showPaymentDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scan QR code di bawah untuk melanjutkan pembayaran dengan Kyris:'),
              const SizedBox(height: 10),
              // Bungkus QrImageView dengan Container agar bisa diberikan ukuran
              Container(
                width: 150.0, // Tentukan ukuran width
                height: 150.0, // Tentukan ukuran height
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 150.0,
                  backgroundColor: Colors.white,
                  // ignore: deprecated_member_use
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPriceFormatted = NumberFormat('#,##0', 'id_ID').format(totalPrice);
    final qrData = 'Total: Rp $totalPriceFormatted, Payment: $selectedPaymentMethod';

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang Transaksi')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final item = widget.cart[index];
                final priceFormatted = NumberFormat('#,##0', 'id_ID').format(item.price);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Harga: Rp $priceFormatted'),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () => decreaseQuantity(index),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () => increaseQuantity(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.black),
                              onPressed: () => removeItem(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Harga: Rp $totalPriceFormatted',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  items: [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Kyris', child: Text('Kyris')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Metode Pembayaran',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (selectedPaymentMethod == 'Kyris') ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _showPaymentDialog(context, qrData);
                    },
                    child: const Text('Tampilkan QR Code'),
                  ),
                ],
              ],
            ),
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
