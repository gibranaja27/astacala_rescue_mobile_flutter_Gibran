import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'detail_berita_screen.dart';
import 'peta_bencana_screen.dart';

class FullBeritaListScreen extends StatefulWidget {
  const FullBeritaListScreen({super.key});

  @override
  State<FullBeritaListScreen> createState() => _FullBeritaListScreenState();
}

class _FullBeritaListScreenState extends State<FullBeritaListScreen> {
  List<dynamic> _allData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getBeritaBencana();
      setState(() {
        _allData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error berita list: $e");
    }
  }

  // ---------------- POPUP MAP (COPY dari HomeScreen) ------------
  void _showMapPopupForBerita(BuildContext ctx, dynamic berita) {
    final titik = berita['titik_kordinat_lokasi_bencana'];
    if (titik == null || !titik.toString().contains(',')) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
            content: Text('Koordinat tidak tersedia untuk berita ini')),
      );
      return;
    }

    final parts = titik.split(',');
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Koordinat tidak valid.')),
      );
      return;
    }

    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Lokasi Bencana',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xFF7A0909),
              ),
              body: PetaBencanaScreen(
                initialLat: lat,
                initialLon: lon,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- COPY CARD EXACTLY FROM HOME ----------------
  Widget _buildBeritaCard(dynamic berita) {
    final titik = berita['titik_kordinat_lokasi_bencana'];
    double? lat;
    double? lon;
    if (titik != null && titik is String && titik.contains(',')) {
      final parts = titik.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim());
        lon = double.tryParse(parts[1].trim());
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                berita['foto_lokasi_bencana'] ?? '',
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) =>
                    Container(height: 190, color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita['informasi_singkat_bencana'] ?? '-',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        ((berita['lokasi_bencana'] ?? '-') as String).length >
                                45
                            ? "${(berita['lokasi_bencana'] ?? '-').substring(0, 45)}..."
                            : (berita['lokasi_bencana'] ?? '-'),
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (lat != null && lon != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: ApiService.getWeatherByCoordinates(
                          lat: lat, lon: lon),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text("Memuat cuaca…");
                        } else if (!snapshot.hasData) {
                          return const Text("Cuaca tidak tersedia");
                        }

                        final w = snapshot.data!;
                        final temp = w['main']['temp'];
                        final desc = w['weather'][0]['description'];
                        final hum = w['main']['humidity'];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("$temp°C | $desc | RH: $hum%"),
                        );
                      },
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            _showMapPopupForBerita(context, berita),
                        child: const Text(
                          "Lihat Peta",
                          style: TextStyle(color: Color(0xFF9B0E0E)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailBeritaScreen(berita: berita),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A0909),
                        ),
                        child: const Text(
                          "Lihat Detail",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Semua Berita Bencana",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7A0909),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allData.length,
              itemBuilder: (context, index) {
                final berita = _allData[index];
                return _buildBeritaCard(berita);
              },
            ),
    );
  }
}
