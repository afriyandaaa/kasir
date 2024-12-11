import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AddProductScreen extends StatefulWidget {
  final String barcode; // Menambahkan parameter barcode

  AddProductScreen({Key? key, required this.barcode}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  String selectedCategory = 'makanan';
  String? imagePath; // Variable to hold the selected image path

  final List<String> categories = ['makanan', 'minuman', 'sayuran', 'nasi', 'snack']; // List of categories

  @override
  void initState() {
    super.initState();
    barcodeController.text = widget.barcode; // Mengisi controller dengan barcode yang diterima
  }

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

  // Function to pick an image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Use pickImage instead of getImage
    if (pickedFile != null) {
      // Save the image to local storage
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = pickedFile.path.split('/').last;
      final localImagePath = '${directory.path}/$fileName';
      final imageFile = File(pickedFile.path);

      // Copy image to the app's document directory
      await imageFile.copy(localImagePath);

      setState(() {
        imagePath = localImagePath; // Store the local image path
      });

      print('Image saved locally: $localImagePath');
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
      final categoryId = await getNewCategoryId(); // Ambil categoryId baru yang unik

      // Menambahkan produk ke Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text,
        'barcode': barcodeController.text,
        'price': double.parse(priceController.text),
        'stock': int.parse(stockController.text),
        'filter': selectedCategory, // Simpan kategori yang dipilih
        'categoryId': categoryId, // Menggunakan categoryId baru yang unik
        'imagePath': imagePath, // Store the local image path
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode Barang',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
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
              // Pick Image button
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage, // Trigger image picker
                child: Text('Pilih Gambar Produk'),
              ),
              if (imagePath != null) ...[
                SizedBox(height: 10),
                Image.file(File(imagePath!)), // Display selected image
              ],
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await addProduct();
                    Navigator.pop(context); // Close screen after adding product
                  },
                  child: Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
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
