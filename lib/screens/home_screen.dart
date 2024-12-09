import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasir/screens/add_product.dart';
import 'transaction_screen.dart';
import 'package:kasir/pages/cart_item.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CartItem> cart = [];
  String role = ''; // Untuk menyimpan peran pengguna

  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Ambil role saat aplikasi dibuka
  }

  // Fungsi untuk mengambil role pengguna
  void fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          setState(() {
            role = snapshot.data()?['role'] ?? ''; // Role pengguna
          });
        } else {
          setState(() {
            role = '';
          });
        }
      } catch (e) {
        print("Error fetching user role: $e");
        setState(() {
          role = ''; // Jika ada kesalahan saat fetch role, set role ke kosong
        });
      }
    }
  }

  // Fungsi untuk menambahkan produk ke keranjang
  void addToCart(String categoryId, String name, double price) {
    final existingItemIndex = cart.indexWhere((item) => item.categoryId == categoryId);

    if (existingItemIndex != -1) {
      // Jika produk sudah ada di keranjang, tingkatkan quantity-nya
      setState(() {
        cart[existingItemIndex].quantity++;
      });
    } else {
      // Jika produk belum ada di keranjang, tambahkan produk baru
      setState(() {
        cart.add(CartItem(
          categoryId: categoryId,
          name: name,
          price: price,
          quantity: 1,
        ));
      });
    }
  }

  // Widget untuk daftar produk
  Widget buildProductList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Firebase Firestore stream
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada produk'));
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data();

            // Data produk
            final String categoryId = product['categoryId'] ?? 'No ID';
            final String name = product['name'] ?? 'Nama Tidak Tersedia';
            final double price = (product['price'] is int) ? (product['price'] as int).toDouble() : (product['price'] ?? 0.0); // Convert harga ke double jika perlu
            final int stock = product['stock'] ?? 0;

            final priceFormatted = NumberFormat('#,##0', 'id_ID').format(price);

            return ListTile(
              title: Text(name),
              subtitle: Text('Harga: Rp $priceFormatted | Stok: $stock'),
              trailing: role == 'staff'
                  ? IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        if (stock > 0) {
                          addToCart(categoryId, name, price);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ditambahkan ke keranjang')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stok habis')),
                          );
                        }
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  // Widget untuk tombol floating action button (FAB)
  Widget buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        if (role == 'owner') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductScreen()), // Owner bisa menambah produk
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionScreen(cart: cart),
            ), // Staff hanya melakukan transaksi
          );
        }
      },
      child: Icon(role == 'owner' ? Icons.add : Icons.shopping_cart),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) {
      // Tampilkan loading saat role belum diambil
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Produk (${role == "owner" ? "Owner" : "Staff"})'),
      ),
      body: buildProductList(),
      floatingActionButton: buildFloatingActionButton(),
    );
  }
}
