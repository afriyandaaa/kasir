import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasir/pages/cart_item.dart';
import 'package:kasir/screens/profile_screen.dart';
import 'add_product.dart';
import 'transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<CartItem> cart = [];
  String role = ''; // Untuk menyimpan peran pengguna
  late TabController _tabController;
  int selectedTabIndex = 0;
  Timer? _timer;

  final filters = ['semua', 'makanan', 'minuman', 'sayuran', 'nasi', 'snack']; // Daftar filter

  @override
  void initState() {
    super.initState();
    fetchUserRole(); // Ambil role saat aplikasi dibuka
    _tabController = TabController(length: filters.length, vsync: this); // TabBar dengan jumlah tab berdasarkan filters
    _tabController.addListener(() {
      setState(() {
        selectedTabIndex = _tabController.index; // Update selected tab index
      });
    });
  }

  // Fungsi untuk mengambil role pengguna
  void fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (snapshot.exists) {
          if (mounted) {
            setState(() {
              role = snapshot.data()?['role'] ?? ''; // Role pengguna
            });
          }
        } else {
          if (mounted) {
            setState(() {
              role = '';
            });
          }
        }
      } catch (e) {
        print("Error fetching user role: $e");
        if (mounted) {
          setState(() {
            role = ''; // Jika ada kesalahan saat fetch role, set role ke kosong
          });
        }
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

  // Widget untuk daftar produk dengan kategori filter
  Widget buildProductList(String filter) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: filter == 'semua' ? FirebaseFirestore.instance.collection('products').snapshots() : FirebaseFirestore.instance.collection('products').where('filter', isEqualTo: filter).snapshots(),
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

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Menambah jumlah kolom menjadi 3
            crossAxisSpacing: 8.0, // Jarak horizontal antar item
            mainAxisSpacing: 8.0, // Jarak vertikal antar item
            childAspectRatio: 0.6, // Menyesuaikan proporsi grid
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data();
            final String name = product['name'] ?? 'Nama Tidak Tersedia';
            final double price = (product['price'] is int) ? (product['price'] as int).toDouble() : (product['price'] ?? 0.0);
            final int stock = product['stock'] ?? 0;
            final String imageUrl = product['imageUrl'] ?? '';

            final priceFormatted = NumberFormat('#,##0', 'id_ID').format(price);

            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: () {
                  addToCart(product['categoryId'], name, price);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(imageUrl, height: 120, width: 120, fit: BoxFit.cover)
                        : Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.white),
                          ),
                    const SizedBox(height: 8),
                    Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rp $priceFormatted', style: const TextStyle(color: Colors.green)),
                    Text('Stok: $stock'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentFilter = filters[selectedTabIndex]; // Ambil filter berdasarkan tab yang dipilih

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black45,
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // Menambahkan padding jika diperlukan
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 20, // Ukuran lingkaran
              backgroundImage: AssetImage('assets/images/login.png'), // Ganti dengan gambar profil pengguna
            ),
          ),
        ),
        title: Text("Toko Sembako"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Tindakan saat ikon search diklik (misal, buka halaman pencarian)
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: filters.map((filter) => Tab(text: filter.capitalize())).toList(),
        ),
      ),

      body: buildProductList(currentFilter), // Kirim filter ke widget produk
      floatingActionButton: FloatingActionButton(
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
      ),
    );
  }

  @override
  void dispose() {
    // Membatalkan timer jika ada
    _timer?.cancel();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
