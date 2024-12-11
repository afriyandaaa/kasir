import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasir/pages/laporan_page.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Future<DocumentSnapshot> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    } else {
      throw Exception('No user is logged in');
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: FutureBuilder<DocumentSnapshot>(
          future: fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No user data found"));
            }

            var userData = snapshot.data!;
            String userName = userData['name'] ?? 'Nama Tidak Ditemukan';
            String userEmail = userData['email'] ?? 'Email Tidak Ditemukan';
            String userRole = userData['role'] ?? 'Peran Tidak Ditemukan';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: const AssetImage('assets/images/login.png') as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outlined),
                        title: const Text('Jabatan'),
                        subtitle: Text(userRole),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(userEmail),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.print_rounded),
                        title: const Text('Laporan'),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LaporanPage()));
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () {
                          _logout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
