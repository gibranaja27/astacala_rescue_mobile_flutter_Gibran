import 'package:flutter/material.dart';

class DetailBeritaScreen extends StatelessWidget {
  final Map<String, dynamic> berita;

  const DetailBeritaScreen({Key? key, required this.berita}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Berita Bencana",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul berita
            Text(
              berita['informasi_singkat_bencana'] ?? 'Judul tidak tersedia',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Foto bencana
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                berita['foto_lokasi_bencana'] ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Subjudul: Informasi Data Bencana
            Row(
              children: const [
                Icon(Icons.insert_chart, color: Color.fromARGB(255, 183, 0, 0)),
                SizedBox(width: 8),
                Text(
                  "Informasi Data Bencana",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Data Bencana
            _buildInfoRow("Lokasi Bencana", berita['lokasi_bencana']),
            _buildInfoRow(
                "Titik Koordinat", berita['titik_kordinat_lokasi_bencana']),
            _buildInfoRow("Skala Bencana", berita['skala_bencana']),
            _buildInfoRow("Jumlah Korban", berita['jumlah_korban'].toString()),
            _buildInfoRow("Deskripsi", berita['deskripsi_terkait_data_lainya']),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Fungsi bantu bikin baris info
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value ?? "-",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
