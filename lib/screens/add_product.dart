import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  String selectedCategory = 'makanan';

  final List<String> categories = ['makanan', 'minuman', 'sayuran', 'nasi', 'snack']; // List of categories

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
        'filter': selectedCategory, // Simpan kategori yang dipilih
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
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // This ensures the screen is scrollable on small devices
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Ensures alignment starts from left
            children: [
              // Name input field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Price input field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Stock input field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Stok',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Category dropdown
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  onChanged: (String? newCategory) {
                    setState(() {
                      selectedCategory = newCategory!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              // Add product button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await addProduct();
                    Navigator.pop(context); // Close screen after adding product
                  },
                  child: Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Makes the button wider
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
