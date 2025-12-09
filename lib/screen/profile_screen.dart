import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const ProfileScreen({Key? key, this.profile}) : super(key: key);

  void _logout(BuildContext context) async {
    await ApiService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String namaLengkap = profile?['nama_lengkap_pengguna'] ?? 'Pengguna';
    final String username = profile?['username_akun_pengguna'] ?? 'username';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Header Profile
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFB70000),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 70, color: Color(0xFFB70000)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      namaLengkap,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "@$username",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Tombol Logout
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Color(0xFFB70000)),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Color(0xFFB70000),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFB70000), width: 2),
                  ),
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
