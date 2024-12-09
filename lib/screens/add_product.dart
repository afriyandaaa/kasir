import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  // Function to generate a new categoryId
  Future<String> getNewCategoryId() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      final products = snapshot.docs;

      // If no products exist, assign categoryId as '1'
      return (products.isEmpty) ? '1' : (products.length + 1).toString();
    } catch (e) {
      print('Error fetching products for categoryId: $e');
      rethrow; // Rethrow to be handled by caller
    }
  }

  Future<void> addProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }

    // Ambil data pengguna dari Firestore
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = snapshot.data()?['role'];
    print('User role: $role'); // Log role pengguna

    // Verifikasi jika role adalah 'owner'
    if (role != 'owner') {
      print('User does not have permission to add products');
      return;
    }

    try {
      final categoryId = await getNewCategoryId(); // Ambil categoryId baru

      // Menambahkan produk ke Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'stock': int.parse(stockController.text),
        'categoryId': categoryId,
      });

      print('Product added successfully');
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Harga'),
            ),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Stok'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await addProduct();
                Navigator.pop(context); // Tutup layar setelah produk ditambahkan
              },
              child: Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}
