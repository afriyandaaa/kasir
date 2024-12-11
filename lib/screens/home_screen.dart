import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasir/pages/cart_item.dart';
import 'package:kasir/screens/drawer_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'add_product.dart';
import 'transaction_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<CartItem> cart = [];
  String role = '';
  late TabController _tabController;
  int selectedTabIndex = 0;
  String searchText = '';
  bool isSearching = false;
  String? _directoryPath;
  String scannedBarcode = '';

  final filters = ['makanan', 'minuman', 'sayuran', 'nasi', 'snack'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserRole();
    _tabController = TabController(length: filters.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedTabIndex = _tabController.index;
      });
    });
    _getDocumentDirectory();
  }

  Future<void> _getDocumentDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      setState(() {
        _directoryPath = directory.path;
      });
    } catch (e) {
      setState(() {
        _directoryPath = 'Failed to get directory: $e';
      });
    }
  }

  void fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snapshot.exists && mounted) {
          setState(() {
            role = snapshot.data()?['role'] ?? '';
          });
        }
      } catch (e) {
        print("Error fetching user role: $e");
      }
    }
  }

  Future<void> scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#FF0000', // warna garis pemindai
        'Cancel', // teks tombol cancel
        true, // menggunakan flash
        ScanMode.BARCODE, // mode pemindaian
      );

      if (barcode != '-1') {
        setState(() {
          scannedBarcode = barcode; // Simpan barcode yang dipindai
        });

        // Cek apakah role adalah 'staff'
        if (role == 'staff') {
          // Cari produk berdasarkan barcode dan tambahkan ke keranjang secara otomatis
          final productSnapshot = await FirebaseFirestore.instance.collection('products').where('barcode', isEqualTo: scannedBarcode).limit(1).get();

          if (productSnapshot.docs.isNotEmpty) {
            final product = productSnapshot.docs.first.data();
            final name = product['name'] ?? 'Nama Tidak Tersedia';
            final price = (product['price'] as num?)?.toDouble() ?? 0.0;
            final stock = product['stock'] ?? 0;
            final imagePath = product['imagePath'] ?? '';

            if (stock > 0) {
              final cartItem = CartItem(
                imagePath: imagePath,
                categoryId: product['categoryId'] ?? '',
                name: name,
                price: price,
                quantity: 1,
              );

              setState(() {
                cart.add(cartItem); // Menambahkan produk ke keranjang
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name berhasil ditambahkan ke keranjang')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name saat ini tidak tersedia')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Produk tidak ditemukan untuk barcode tersebut')),
            );
          }
        } else {
          // Jika role adalah 'owner', buka halaman AddProductScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductScreen(barcode: scannedBarcode), // Kirim barcode ke halaman AddProductScreen
            ),
          );
        }
      }
    } catch (e) {
      print('Terjadi kesalahan saat memindai barcode: $e');
    }
  }

  Future<void> _refreshData() async {
    // Simulate a refresh operation, like re-fetching data
    setState(() {
      // You can trigger state changes here if necessary
      fetchUserRole();
    });
  }

  Widget buildProductList(String filter) {
    Stream<QuerySnapshot<Map<String, dynamic>>> stream;
    if (searchText.isNotEmpty) {
      stream = FirebaseFirestore.instance.collection('products').where('name', isGreaterThanOrEqualTo: searchText).where('name', isLessThanOrEqualTo: '$searchText\uf8ff').snapshots();
    } else {
      stream = FirebaseFirestore.instance.collection('products').where('filter', isEqualTo: filter).snapshots();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
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
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.6,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data();
            final name = product['name'] ?? 'Nama Tidak Tersedia';
            final price = (product['price'] as num?)?.toDouble() ?? 0.0;
            final stock = product['stock'] ?? 0;
            final imagePath = product['imagePath'] ?? '';
            final priceFormatted = NumberFormat('#,##0', 'id_ID').format(price);

            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: () {
                  if (stock == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name saat ini tidak tersedia')),
                    );
                  } else {
                    final cartItem = CartItem(
                      imagePath: imagePath,
                      categoryId: product['categoryId'] ?? '',
                      name: name,
                      price: price,
                      quantity: 1,
                    );

                    setState(() {
                      cart.add(cartItem);
                    });
                  }
                },
                child: Column(
                  children: [
                    imagePath.isNotEmpty && _directoryPath != null
                        ? (() {
                            final fullPath = imagePath.startsWith(_directoryPath ?? '') ? imagePath : '$_directoryPath/$imagePath';
                            if (File(fullPath).existsSync()) {
                              return Image.file(
                                File(fullPath),
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Container(
                                height: 120,
                                width: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.red),
                              );
                            }
                          })()
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentFilter = filters[selectedTabIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black45,
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              )
            : const Text("Toko Sembako"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchText = '';
                  _searchController.clear();
                }
                isSearching = !isSearching;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.barcode_reader),
            onPressed: () async {
              scanBarcode();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: filters.map((filter) => Tab(text: filter.capitalize())).toList(),
        ),
      ),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: buildProductList(currentFilter),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (role == 'owner') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductScreen(barcode: scannedBarcode), // Mengirim barcode yang dipindai
              ),
            );
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TransactionScreen(cart: cart)),
            );

            if (result == true) {
              setState(() {
                cart.clear();
              });
            }
          }
        },
        child: Stack(
          children: [
            Icon(role == 'owner' ? Icons.add : Icons.shopping_cart),
            if (cart.isNotEmpty)
              Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(
                    '${cart.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
