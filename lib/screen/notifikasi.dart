import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';

class NotifikasiPage extends StatefulWidget {
  final int penggunaId;
  const NotifikasiPage({super.key, required this.penggunaId});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List notifikasi = [];
  List<int> deletedNotifikasiIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initNotifikasi();
  }

  /// 🔴 INI YANG PENTING
  Future<void> _initNotifikasi() async {
    await ApiService.markAllAsRead(widget.penggunaId); // tandai dibaca DULU
    await fetchNotifikasi(); // baru ambil data
  }

  Future<void> fetchNotifikasi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_notifikasi') ?? [];
      deletedNotifikasiIds =
          deletedIds.map((id) => int.tryParse(id) ?? 0).toList();

      final data = await ApiService.getNotifikasi(widget.penggunaId);

      final filtered = data
          .where((item) => !deletedNotifikasiIds.contains(item['id']))
          .toList();

      setState(() {
        notifikasi = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat notifikasi: $e')),
      );
    }
  }

  Future<void> deleteNotifikasi(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList('deleted_notifikasi') ?? [];

    if (!deletedIds.contains(id.toString())) {
      deletedIds.add(id.toString());
      await prefs.setStringList('deleted_notifikasi', deletedIds);
    }

    setState(() {
      notifikasi.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Verifikasi'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifikasi.isEmpty
              ? const Center(child: Text('Belum ada notifikasi'))
              : ListView.builder(
                  itemCount: notifikasi.length,
                  itemBuilder: (context, index) {
                    final item = notifikasi[index];
                    final status = item['status_verifikasi'];
                    final sudahDibaca = item['sudah_dibaca'] ?? false;

                    final warna = status == 'DITERIMA'
                        ? Colors.green
                        : (status == 'DITOLAK' ? Colors.red : Colors.grey);

                    return Card(
                      color: sudahDibaca ? Colors.grey.shade200 : Colors.white,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          status == 'DITERIMA'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: warna,
                        ),
                        title: Text(
                          item['informasi_singkat_bencana'] ?? 'Tidak ada data',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sudahDibaca ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Status Pelaporan Anda: $status',
                          style: TextStyle(color: warna),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteNotifikasi(item['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
