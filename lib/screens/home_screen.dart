import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/classifier_service.dart';
import '../services/detection_history_service.dart';
import '../models/detection_record.dart';
import '../widgets/action_button.dart';
import '../widgets/invalid_object_dialog.dart';
import 'result_screen.dart';
import 'guide_screen.dart';
import 'realtime_camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ClassifierService _classifier = ClassifierService();
  final DetectionHistoryService _historyService = DetectionHistoryService();
  bool _isAnalyzing = false;

  Future<void> _pickFromCamera() async {
    if (_isAnalyzing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024, maxHeight: 1024, imageQuality: 90,
      );
      if (image != null && mounted) await _analyzeImage(File(image.path));
    } catch (e) {
      if (mounted) _showError('Tidak dapat membuka kamera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, maxHeight: 1024, imageQuality: 90,
      );
      if (image != null && mounted) await _analyzeImage(File(image.path));
    } catch (e) {
      if (mounted) _showError('Tidak dapat membuka galeri: $e');
    }
  }

  /// Copy image ke app documents directory dan return path
  Future<String?> _copyImageToAppDir(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/detection_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${imagesDir.path}/detection_$timestamp.jpg';
      final copiedFile = await imageFile.copy(newPath);
      return copiedFile.path;
    } catch (e) {
      debugPrint('Error copying image: $e');
      return null;
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await _classifier.classifyImageFile(imageFile);
      if (mounted) {
        // ── Cek apakah hasil adalah daun tomat yang valid ─────────────────
        if (!result.isValidTomatoLeaf) {
          // Tampilkan dialog objek asing
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => InvalidObjectDialog(
              onRetry: _pickFromCamera,
            ),
          );
          return;
        }

        // ── Simpan hasil deteksi ke history ──────────────────────────────
        try {
          // Copy image ke app directory
          final imagePath = await _copyImageToAppDir(imageFile);
          
          final diseaseInfo = DiseaseInfo.getInfo(result.label);
          final status = result.isHealthy ? DetectionStatus.healthy : DetectionStatus.diseased;
          
          // Tentukan warna placeholder berdasarkan status
          final placeholderColor = result.isHealthy ? 'EBF5E8' : 'FEF3F1';
          
          final record = DetectionRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            leafLabel: result.label,
            diseaseName: result.label,
            scientificName: diseaseInfo.scientificName.isEmpty ? result.label : diseaseInfo.scientificName,
            scannedAt: DateTime.now(),
            status: status,
            confidence: result.confidence,
            imagePlaceholderColor: placeholderColor,
            imagePath: imagePath,
          );
          
          await _historyService.saveDetection(record);
        } catch (e) {
          debugPrint('Gagal menyimpan ke history: $e');
          // Lanjut meski gagal menyimpan
        }

        // ── Jika valid, tampilkan hasil analisis ─────────────────────────
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ResultScreen(imageFile: imageFile, result: result),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Gagal menganalisis: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }


  void _openGuide() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const GuideScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  Future<void> _openRealtimeCamera() async {
    try {
      // Inisialisasi classifier jika belum
      if (!_classifier.isInitialized) {
        await _classifier.initialize();
      }

      // Inisialisasi kamera
      final availableCams = await availableCameras();
      if (availableCams.isEmpty) {
        if (mounted) _showError('Tidak ada kamera yang tersedia');
        return;
      }

      if (mounted) {
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RealtimeCameraScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Gagal membuka kamera: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.tomatoRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Top row: Logo Universitas + FKOM + Help button ─────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo Universitas Kuningan
                      Image.asset(
                        'assets/images/logo_uniku.png',
                        height: 46,
                        width: 46,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EDD0),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          child: const Icon(Icons.school_rounded, size: 24, color: Color(0xFF8B7340)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Logo FKOM
                      Image.asset(
                        'assets/images/logo_fkom.png',
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
                          'FKOM',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A3A8A)),
                        ),
                      ),
                      const Spacer(),
                      // Tombol Help
                      GestureDetector(
                        onTap: _openGuide,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(Icons.help_outline_rounded, size: 20, color: AppTheme.primaryGreen),
                              ),
                              Positioned(
                                top: 7, right: 7,
                                child: Container(
                                  width: 7, height: 7,
                                  decoration: const BoxDecoration(color: AppTheme.tomatoRed, shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Judul ──────────────────────────────────────────────────
                  const Text(
                    'Pindai &\nDeteksi',
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: AppTheme.darkText, height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Identifikasi penyakit tanaman tomat secara instan',
                    style: TextStyle(fontSize: 13, color: AppTheme.subtleText),
                  ),

                  const SizedBox(height: 20),

                  // ── Hero Image — Foto Nyata Tanaman Tomat ─────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/tomato_hero.jpg',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEBF5E8), Color(0xFFF5F9F4)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.eco_rounded, size: 64, color: AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tombol Ambil via Kamera ────────────────────────────────
                  ActionButton(
                    icon: Icons.camera_alt_rounded,
                    title: 'Ambil via Kamera',
                    subtitle: 'Foto langsung & analisis',
                    backgroundColor: Colors.white,
                    iconBackgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                    titleColor: AppTheme.primaryGreen,
                    subtitleColor: AppTheme.primaryGreen.withOpacity(0.65),
                    arrowColor: AppTheme.primaryGreen,
                    arrowBackgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                    borderColor: AppTheme.primaryGreen.withOpacity(0.2),
                    onTap: _pickFromCamera,
                  ),

                  const SizedBox(height: 10),

                  // ── Tombol Upload dari Galeri ──────────────────────────────
                  ActionButton(
                    icon: Icons.photo_library_rounded,
                    title: 'Upload dari Galeri',
                    subtitle: 'Analisis foto tersimpan',
                    backgroundColor: Colors.white,
                    iconBackgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                    titleColor: AppTheme.primaryGreen,
                    subtitleColor: AppTheme.primaryGreen.withOpacity(0.65),
                    arrowColor: AppTheme.primaryGreen,
                    arrowBackgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                    borderColor: AppTheme.primaryGreen.withOpacity(0.2),
                    onTap: _pickFromGallery,
                  ),

                  // ── Divider "atau" ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderColor, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('atau',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedText),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderColor, height: 1)),
                      ],
                    ),
                  ),

                  // ── Tombol Real-time Camera ────────────────────────────────
                  ActionButton(
                    icon: Icons.videocam_rounded,
                    title: 'Deteksi Real-time',
                    subtitle: 'Analisis langsung tanpa foto',
                    backgroundColor: AppTheme.primaryGreen,
                    iconBackgroundColor: Colors.white.withOpacity(0.15),
                    titleColor: Colors.white,
                    subtitleColor: Colors.white.withOpacity(0.65),
                    arrowColor: Colors.white,
                    arrowBackgroundColor: Colors.white.withOpacity(0.15),
                    onTap: _openRealtimeCamera,
                  ),

                ],
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_isAnalyzing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48, height: 48,
                        child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3),
                      ),
                      const SizedBox(height: 16),
                      const Text('Menganalisis...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkText),
                      ),
                      const SizedBox(height: 4),
                      const Text('Model sedang memproses gambar',
                        style: TextStyle(fontSize: 12, color: AppTheme.subtleText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
