import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';
import '../service/api_service.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _teamController = TextEditingController();
  final TextEditingController _jumlahPersonelController =
      TextEditingController();
  final TextEditingController _infoSingkatController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _titikKordinatController =
      TextEditingController();
  final TextEditingController _skalaController = TextEditingController();
  final TextEditingController _jumlahKorbanController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  File? _pickedImage;
  File? _pickedPdf;
  bool _loading = false;
  double _progress = 0.0;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? xfile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (xfile != null) setState(() => _pickedImage = File(xfile.path));
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedPdf = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _progress = 0.0;
    });

    try {
      final token = await ApiService.getToken();
      final dio = Dio();

      final formMap = <String, dynamic>{
        'nama_team_pelapor': _teamController.text.trim(),
        'jumlah_personel': _jumlahPersonelController.text.trim(),
        'informasi_singkat_bencana': _infoSingkatController.text.trim(),
        'lokasi_bencana': _lokasiController.text.trim(),
        'titik_kordinat_lokasi_bencana': _titikKordinatController.text.trim(),
        'skala_bencana': _skalaController.text.trim(),
        'jumlah_korban': _jumlahKorbanController.text.trim(),
        'deskripsi_terkait_data_lainya': _deskripsiController.text.trim(),
      };

      if (_pickedImage != null) {
        final filename = p.basename(_pickedImage!.path);
        formMap['foto_lokasi_bencana'] = await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: filename);
      }

      if (_pickedPdf != null) {
        final filename = p.basename(_pickedPdf!.path);
        formMap['bukti_surat_perintah_tugas'] = await MultipartFile.fromFile(
            _pickedPdf!.path,
            filename: filename,
            contentType: MediaType('application', 'pdf'));
      }

      final formData = FormData.fromMap(formMap);

      final response = await dio.post(
        '${ApiService.baseUrl}/pelaporans',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          contentType: 'multipart/form-data',
        ),
        onSendProgress: (count, total) {
          setState(() {
            _progress = total > 0 ? count / total : 0;
          });
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pelaporan berhasil dikirim')));
        _formKey.currentState!.reset();
        setState(() {
          _pickedImage = null;
          _pickedPdf = null;
          _loading = false;
          _progress = 0.0;
        });
      } else {
        final msg = response.data?['message'] ?? 'Gagal mengirim';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _loading = false);
      }
    } on DioError catch (e) {
      String msg = e.response?.data?['message'] ?? e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _loading = false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _loading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("GPS tidak aktif, aktifkan terlebih dahulu")));
      return;
    }

    // Cek permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Izin lokasi ditolak")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Izin lokasi ditolak permanen. Aktifkan via Settings.")));
      return;
    }

    // Ambil lokasi
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _titikKordinatController.text =
          "${position.latitude}, ${position.longitude}";
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Lokasi berhasil diambil")));
  }

  @override
  Widget build(BuildContext context) {
    final maroon =
        Color.fromARGB(255, 167, 28, 26); // warna branding maroon/coklat tua

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: maroon,
        title: const Text(
          "Pelaporan Bencana",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Input fields
                  _buildTextField(_teamController, 'Nama Team Pelapor'),
                  _buildTextField(_jumlahPersonelController, 'Jumlah Personel',
                      type: TextInputType.number),
                  _buildTextField(
                      _infoSingkatController, 'Informasi Singkat Bencana'),
                  _buildTextField(_lokasiController, 'Nama Lokasi Bencana'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: _titikKordinatController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Titik Koordinat Lokasi Yang Terdampak',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.my_location, color: maroon),
                          onPressed: _getCurrentLocation,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: maroon, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DropdownButtonFormField<String>(
                      value: _skalaController.text.isEmpty
                          ? null
                          : _skalaController.text,
                      decoration: InputDecoration(
                        labelText: "Skala Bencana",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 167, 28, 26),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Kecil", child: Text("Kecil")),
                        DropdownMenuItem(
                            value: "Sedang", child: Text("Sedang")),
                        DropdownMenuItem(value: "Besar", child: Text("Besar")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _skalaController.text = value!;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? "Wajib dipilih"
                          : null,
                    ),
                  ),
                  _buildTextField(_jumlahKorbanController, 'Jumlah Korban',
                      type: TextInputType.number),
                  _buildTextField(_deskripsiController, 'Deskripsi (opsional)',
                      maxLines: 3, required: false),
                  const SizedBox(height: 16),

                  // Tombol Pilih Gambar
                  _buildUploadButton(
                    label: _pickedImage == null
                        ? 'Pilih Foto Lokasi Bencana'
                        : 'Ganti Foto',
                    icon: Icons.photo,
                    onPressed: _pickImage,
                    filename: _pickedImage != null
                        ? p.basename(_pickedImage!.path)
                        : null,
                    color: maroon,
                  ),

                  const SizedBox(height: 10),

                  // Tombol Pilih PDF
                  _buildUploadButton(
                    label: _pickedPdf == null
                        ? 'Pilih File Bukti Surat Tugas (PDF)'
                        : 'Ganti PDF',
                    icon: Icons.picture_as_pdf,
                    onPressed: _pickPdf,
                    filename: _pickedPdf != null
                        ? p.basename(_pickedPdf!.path)
                        : null,
                    color: maroon,
                  ),

                  const SizedBox(height: 24),

                  _loading
                      ? Column(children: [
                          LinearProgressIndicator(
                            value: _progress,
                            color: maroon,
                            backgroundColor: maroon.withOpacity(0.2),
                          ),
                          const SizedBox(height: 8),
                          Text('${(_progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: maroon)),
                        ])
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroon,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Kirim Pelaporan',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text,
      int maxLines = 1,
      bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Color.fromARGB(255, 167, 28, 26), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    String? filename,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            label: Text(label, style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (filename != null)
          Expanded(
            child: Text(
              filename,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
