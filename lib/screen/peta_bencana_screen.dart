// lib/screens/peta_bencana_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../service/api_service.dart';
import 'detail_berita_screen.dart';

class PetaBencanaScreen extends StatefulWidget {
  final double? initialLat; // ADDED optional fokus
  final double? initialLon; // ADDED optional fokus

  const PetaBencanaScreen({Key? key, this.initialLat, this.initialLon})
      : super(key: key);

  @override
  State<PetaBencanaScreen> createState() => _PetaBencanaScreenState();
}

class _PetaBencanaScreenState extends State<PetaBencanaScreen> {
  List<dynamic> _berita = [];
  bool _loading = true;
  late final MapController _mapController;
  LatLng? _initialCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadData();
    if (widget.initialLat != null && widget.initialLon != null) {
      _initialCenter = LatLng(widget.initialLat!, widget.initialLon!);
    }

    // PAKSA MAP FOKUS SETELAH RENDER
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialCenter != null) {
        _mapController.move(_initialCenter!, 13);
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getBeritaBencana();
      setState(() {
        _berita = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Gagal memuat data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final defaultCenter = _initialCenter ?? LatLng(-6.914744, 107.609810);

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: defaultCenter,
          zoom: 10.5,
          enableScrollWheel: true,
          minZoom: 3,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.mobileastrescue.app",
            tileProvider: NetworkTileProvider(
              headers: {
                "User-Agent": "MobileASTRescue/1.0 (admin@mobileastrescue.com)",
              },
            ),
          ),
          MarkerLayer(
            markers: _berita
                .map((berita) {
                  final titik = berita['titik_kordinat_lokasi_bencana'];
                  if (titik == null || !titik.toString().contains(',')) {
                    return null;
                  }
                  final parts = titik.split(',');
                  final lat = double.tryParse(parts[0].trim());
                  final lon = double.tryParse(parts[1].trim());
                  if (lat == null || lon == null) return null;

                  return Marker(
                    point: LatLng(lat, lon),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showMarkerDialog(context, berita),
                      child: const Icon(
                        Icons.location_on,
                        size: 38,
                        color: Colors.red,
                      ),
                    ),
                  );
                })
                .whereType<Marker>()
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7A0909),
        onPressed: () {
          // center to all markers (fit bounds) - simple approach: animate to first marker if exists
          final first = _berita.firstWhere(
              (b) =>
                  b['titik_kordinat_lokasi_bencana'] != null &&
                  b['titik_kordinat_lokasi_bencana'].toString().contains(','),
              orElse: () => null);
          if (first != null) {
            final parts = first['titik_kordinat_lokasi_bencana'].split(',');
            final lat = double.tryParse(parts[0].trim());
            final lon = double.tryParse(parts[1].trim());
            if (lat != null && lon != null) {
              _mapController.move(LatLng(lat, lon), 12.0);
            }
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showMarkerDialog(BuildContext context, dynamic berita) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          berita['informasi_singkat_bencana'] ?? "Tidak ada informasi",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(berita['lokasi_bencana'] ?? "-"),
            const SizedBox(height: 10),
            if (berita['foto_lokasi_bencana'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  berita['foto_lokasi_bencana'],
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A0909),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailBeritaScreen(berita: berita),
                ),
              );
            },
            child: const Text("Lihat Detail"),
          ),
        ],
      ),
    );
  }
}
