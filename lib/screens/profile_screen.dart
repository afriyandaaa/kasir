import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Mengecek apakah pengguna sudah login
    checkLoginStatus();
  }

  // Memeriksa status login dan mengarahkan ke halaman login jika belum login
  void checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Jika belum login, arahkan ke halaman login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  // Fetch user data from Firestore
  Future<DocumentSnapshot> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data from Firestore based on user ID (UID)
      return await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    } else {
      throw Exception('No user is logged in');
    }
  }

  // Logout function
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Menggunakan pushReplacement untuk mengganti halaman dan menghindari pengguna kembali
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching user data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data found"));
          }

          // Extracting user data from Firestore document
          var userData = snapshot.data!;
          String userName = userData['name'] ?? 'No Name';
          String userEmail = userData['email'] ?? 'No Email';
          String userRole = userData['role'] ?? 'role';

          return Stack(
            children: [
              Column(
                children: [
                  // Header Section
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(height: 150, color: Colors.blue),
                      Positioned(
                        top: 60,
                        left: MediaQuery.of(context).size.width / 2 - 80,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundImage: const AssetImage('assets/images/login.png') as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 5),
                        Text(userRole, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        buildInfoRow('Nama', userName),
                        buildInfoRow('Email', userEmail),
                        buildInfoRow('Pangkat', userRole),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 30,
                left: MediaQuery.of(context).size.width / 2 - 68,
                child: ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  ),
                  child: const Text('Logout', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
