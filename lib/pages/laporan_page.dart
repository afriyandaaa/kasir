import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat dan NumberFormat

class LaporanPage extends StatefulWidget {
  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String? _selectedMonth;
  final List<String> _months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months[0]; // Set default bulan ke Januari
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Transaksi Bulanan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedMonth,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMonth = newValue;
                  });
                }
              },
              items: _months.map<DropdownMenuItem<String>>((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where(
                      'timestamp',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartOfMonth(_selectedMonth!)),
                    )
                    .where(
                      'timestamp',
                      isLessThan: Timestamp.fromDate(_getEndOfMonth(_selectedMonth!)),
                    )
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Tidak ada transaksi untuk bulan ini.'));
                  }

                  var transaksiData = snapshot.data!.docs;
                  List<Map<String, dynamic>> allItems = [];
                  double totalPendapatan = 0.0;

                  for (var transaksi in transaksiData) {
                    // Ambil metode pembayaran dari level transaksi
                    var paymentMethod = (transaksi['paymentMethod'] as String?) ?? 'Tidak Diketahui';

                    var items = transaksi['items'] as List?;
                    if (items != null && items.isNotEmpty) {
                      for (var item in items) {
                        allItems.add({
                          'name': (item['name'] as String?) ?? 'Nama Tidak Tersedia',
                          'quantity': (item['quantity'] as int?) ?? 0,
                          'totalPrice': (item['totalPrice'] as double?) ?? 0.0,
                          'transactionDate': (transaksi['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                          'paymentMethod': paymentMethod, // Tambahkan paymentMethod ke setiap item
                        });

                        totalPendapatan += (item['totalPrice'] as double?) ?? 0.0;
                      }
                    }
                  }

                  if (allItems.isEmpty) {
                    return Center(child: Text('Tidak ada item untuk bulan ini.'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: allItems.map((item) {
                        var formattedDate = DateFormat('yyyy-MM-dd').format(item['transactionDate']);
                        return DataRow(cells: [
                          DataCell(Text(formattedDate)),
                          DataCell(Text(item['paymentMethod'])), // Ambil metode pembayaran
                          DataCell(Text(item['name'])),
                          DataCell(Text('${item['quantity']}')),
                          DataCell(Text(currencyFormatter.format(item['totalPrice']))),
                        ]);
                      }).toList()
                        ..add(
                          DataRow(
                            cells: [
                              DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('')), // Kolom metode pembayaran untuk total
                              DataCell(Text('')), // Kosong untuk nama barang
                              DataCell(Text(
                                '${allItems.fold(0, (sum, item) => sum + (item['quantity'] as int))}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text(
                                currencyFormatter.format(totalPendapatan),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                            ],
                          ),
                        ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getStartOfMonth(String month) {
    final now = DateTime.now();
    final monthIndex = _months.indexOf(month) + 1;
    return DateTime(now.year, monthIndex, 1);
  }

  DateTime _getEndOfMonth(String month) {
    final startOfMonth = _getStartOfMonth(month);
    return DateTime(startOfMonth.year, startOfMonth.month + 1, 0);
  }
}
