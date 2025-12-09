// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'report_screen.dart';
import 'notifikasi.dart';
import 'detail_berita_screen.dart';
import 'profile_screen.dart';
import 'peta_bencana_screen.dart'; // ADDED (untuk navigation ke peta global)
import 'full_berita_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? profile;
  int _selectedIndex = 0;
  int unreadCount = 0;
  bool isLoadingNotif = false;

  // untuk pencarian
  List<dynamic> _allBerita = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchBerita();
  }

  void _loadProfile() async {
    try {
      final res = await ApiService.getProfile();
      setState(() => profile = res['data']);
      if (profile != null && profile!['id'] != null) {
        _fetchUnreadNotif(profile!['id']);
      }
    } catch (e) {
      debugPrint('Gagal ambil profile: $e');
    }
  }

  Future<void> _fetchUnreadNotif(int penggunaId) async {
    setState(() => isLoadingNotif = true);
    try {
      final notifikasiList = await ApiService.getNotifikasi(penggunaId);
      final unread = notifikasiList
          .where((n) => n['sudah_dibaca'] == false || n['sudah_dibaca'] == null)
          .length;
      setState(() {
        unreadCount = unread;
        isLoadingNotif = false;
      });
    } catch (e) {
      setState(() => isLoadingNotif = false);
      debugPrint('Gagal ambil notifikasi: $e');
    }
  }

  Future<void> _fetchBerita() async {
    try {
      final berita = await ApiService.getBeritaBencana();
      setState(() {
        _allBerita = berita;
      });
    } catch (e) {
      debugPrint('Gagal memuat berita: $e');
    }
  }

  void _logout() async {
    await ApiService.logout();
  }

  List<Widget> get _pages => [
        _buildHomeContent(),
        ReportScreen(),
        ProfileScreen(profile: profile),
      ];

  // --------------------- UI Helpers ---------------------
  Widget _buildHeader() {
    final name = profile != null
        ? (profile!['nama_lengkap_pengguna'] ?? 'Sobat Relawan')
        : 'Sobat Relawan';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF7A0909),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // bar atas: greeting + icon notif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Hai, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // notifikasi icon
              Stack(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (profile != null && profile!['id'] != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NotifikasiPage(penggunaId: profile!['id']),
                          ),
                        );
                        _fetchUnreadNotif(profile!['id']);
                        // ADDED: refresh berita ketika kembali dari halaman notifikasi
                        _fetchBerita();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profil belum dimuat.")),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _smallHeaderCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 183, 98, 98).withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionCard(
              icon: Icons.notifications_active,
              iconColor: Color(0xFF7A0909),
              title: 'Lapor Bencana',
              subtitle: 'Laporkan kejadian darurat',
              onTap: () {},
            ),
            const SizedBox(width: 18),
            _actionCard(
              icon: Icons.map,
              iconColor: Colors.green,
              title: 'Peta Bencana',
              subtitle: 'Lihat peta lokasi bencana',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        _actionCard(
          icon: Icons.emergency,
          iconColor: Colors.red,
          title: 'Darurat',
          subtitle: 'Panggilan mendesak',
          width: 230,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    double width = 160,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // show map popup for a single berita with coordinates
  void _showMapPopupForBerita(BuildContext ctx, dynamic berita) {
    final titik = berita['titik_kordinat_lokasi_bencana'];
    if (titik == null || !titik.toString().contains(',')) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Koordinat tidak tersedia untuk berita ini')));
      return;
    }

    final parts = titik.split(',');
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Koordinat tidak valid.')));
      return;
    }

    // tampilkan dialog besar berisi peta (menggunakan layar penuh dialog)
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Lokasi Bencana',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF7A0909),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.open_in_full),
                    onPressed: () {
                      // buka layar peta penuh (opsional)
                      Navigator.pop(ctx);
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => PetaBencanaScreen(
                            initialLat: lat,
                            initialLon: lon,
                          ),
                        ),
                      );
                    },
                  )
                ],
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
  // ----------------------------------------------------------------

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
              child: Stack(
                children: [
                  Image.network(
                    berita['foto_lokasi_bencana'] ?? '',
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      height: 190,
                      color: Colors.grey[300],
                      child:
                          const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        berita['created_at'] != null ? '2j yang lalu' : '',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                      Text(berita['lokasi_bencana'] ?? '-',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  if (lat != null && lon != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: ApiService.getWeatherByCoordinates(
                          lat: lat, lon: lon),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text("🔄 Memuat data cuaca...");
                        } else if (snapshot.hasError || snapshot.data == null) {
                          return const Text("❌ Gagal memuat cuaca.");
                        } else {
                          final weather = snapshot.data!;
                          final temp = weather['main']['temp'];
                          final desc = weather['weather'][0]['description'];
                          final hum = weather['main']['humidity'].toString();
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.wb_sunny,
                                        color: Colors.orangeAccent),
                                    const SizedBox(width: 6),
                                    Text(
                                        "${temp.toString()}°C | ${desc.toString().toUpperCase()} | RH: $hum%"),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    )
                  else
                    const Text("Koordinat tidak tersedia.",
                        style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              //buka popup peta untuk berita ini
                              _showMapPopupForBerita(context, berita);
                            },
                            child: const Text(
                              'Lihat Peta',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 151, 10, 0)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DetailBeritaScreen(berita: berita)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7A0909),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Lihat Detail',
                                style: TextStyle(
                                    color: Color.fromARGB(179, 255, 255, 255))),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --------------------- Main content ---------------------
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          const SizedBox(height: 10),
          _buildQuickActions(),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Berita Terkini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // Tombol "Lihat Selengkapnya"
              TextButton(
                onPressed: () {
                  // sementara kosong (tidak direct ke mana-mana)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FullBeritaListScreen()),
                  );
                },
                child: Text(
                  'Lihat Selengkapnya',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(
                        255, 192, 0, 0), // bisa diganti sesuai tema
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_allBerita.isEmpty)
            const Center(child: CircularProgressIndicator()),
          Column(
            children:
                _allBerita.take(4).map((b) => _buildBeritaCard(b)).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --------------------- build ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _pages[_selectedIndex]),
            Container(
              color: Colors.white,
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedItemColor: const Color(0xFF7A0909),
                unselectedItemColor: Colors.grey,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.report), label: 'Pelaporan'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person), label: 'Akun'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
