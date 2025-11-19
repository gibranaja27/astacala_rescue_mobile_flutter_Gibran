import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static const String webBase = "http://10.0.2.2:8000";

  // ===== AUTH =====
  static Future<Map<String, dynamic>> register(Map<String, String> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registersss'),
      headers: {"Accept": "application/json"},
      body: body,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Accept": "application/json"},
      body: {
        "username_akun_pengguna": username,
        "password_akun_pengguna": password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token']);
    }

    return data;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> logout() async {
    String? token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }

    return jsonDecode(response.body);
  }

  // ===== PELAPORAN =====
  static Future<Map<String, dynamic>> createPelaporan({
    required String namaTeam,
    required int jumlahPersonel,
    required String informasiSingkat,
    required String lokasiBencana,
    String? titikKordinat,
    required String skalaBencana,
    required int jumlahKorban,
    String? deskripsiLainnya,
    File? fotoBencana,
    File? buktiSurat,
  }) async {
    String? token = await getToken();
    var uri = Uri.parse('$baseUrl/pelaporans');
    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });

    request.fields['nama_team_pelapor'] = namaTeam;
    request.fields['jumlah_personel'] = jumlahPersonel.toString();
    request.fields['informasi_singkat_bencana'] = informasiSingkat;
    request.fields['lokasi_bencana'] = lokasiBencana;
    if (titikKordinat != null)
      request.fields['titik_kordinat_lokasi_bencana'] = titikKordinat;
    request.fields['skala_bencana'] = skalaBencana;
    request.fields['jumlah_korban'] = jumlahKorban.toString();
    if (deskripsiLainnya != null)
      request.fields['deskripsi_terkait_data_lainya'] = deskripsiLainnya;

    if (fotoBencana != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'foto_lokasi_bencana',
        fotoBencana.path,
      ));
    }

    if (buktiSurat != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_surat_perintah_tugas',
        buktiSurat.path,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getBeritaBencana() async {
    String? token = await getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/pelaporans/diterima'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat berita bencana');
    }
  }

  // ===== CUACA =====
  static Future<Map<String, dynamic>?> getWeatherByCoordinates({
    required double lat,
    required double lon,
  }) async {
    const String apiKey = "bcd48071368d61dde75e10b298ff6c0e";
    final String url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Gagal memuat data cuaca: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error saat memuat cuaca: $e");
      return null;
    }
  }

  // ===== NOTIFIKASI =====
  static Future<List<dynamic>> getNotifikasi(int penggunaId) async {
    final response = await http.get(
      Uri.parse('$webBase/notifikasi/$penggunaId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat notifikasi');
    }
  }

  static Future<void> markAllAsRead(int penggunaId) async {
    await http.post(
      Uri.parse('$webBase/notifikasi/mark-as-read/$penggunaId'),
    );
  }
}
