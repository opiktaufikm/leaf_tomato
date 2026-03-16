import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_chip.dart';
import '../widgets/action_button.dart';
import '../widgets/leaf_hero_painter.dart';
import '../models/analysis_result.dart';
import 'live_detection_screen.dart';
import 'guide_screen.dart';
import 'image_preview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickFromCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ImagePreviewScreen(
        sourceType: ImageSourceType.camera,
        imagePath: file.path,
      ),
    ));
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ImagePreviewScreen(
        sourceType: ImageSourceType.gallery,
        imagePath: file.path,
      ),
    ));
  }

  // ── Buka halaman Panduan ────────────────────────────────────────────────────
  void _openGuide(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GuideScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ── Buka halaman Live Detection ─────────────────────────────────────────────
  void _goLive(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            const LiveDetectionScreen(showBackButton: true),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Top Row: Badge + Tombol Panduan (?) ────────────────────────
              Row(
                children: [
                  // Badge TomGuard AI
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.lightGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'TOMATO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Tombol Tanda Tanya / Panduan ─────────────────────────
                  GestureDetector(
                    onTap: () => _openGuide(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.help_outline_rounded,
                              size: 20,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          // Indikator dot merah
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppTheme.tomatoRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Title ──────────────────────────────────────────────────────
              const Text(
                'Pindai &\nDeteksi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Identifikasi penyakit tanaman tomat secara instan',
                style: TextStyle(fontSize: 13, color: AppTheme.subtleText),
              ),

              const SizedBox(height: 20),

              // ── Hero Illustration ──────────────────────────────────────────
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEBF5E8), Color(0xFFF5F9F4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: CustomPaint(
                  painter: LeafHeroPainter(),
                  child: const SizedBox.expand(),
                ),
              ),

              const SizedBox(height: 16),

              // ── Quick Stats ────────────────────────────────────────────────
              const Row(
                children: [
                  StatChip(
                    value: '128',
                    label: 'Total Pindai',
                    valueColor: AppTheme.primaryGreen,
                    backgroundColor: Color(0xFFF2F7F1),
                  ),
                  SizedBox(width: 8),
                  StatChip(
                    value: '74%',
                    label: 'Sehat',
                    valueColor: Color(0xFF5A7A5A),
                    backgroundColor: Color(0xFFF2F7F1),
                  ),
                  SizedBox(width: 8),
                  StatChip(
                    value: '3',
                    label: 'Penyakit',
                    valueColor: AppTheme.tomatoRed,
                    backgroundColor: AppTheme.lightRed,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Tombol Ambil via Kamera ────────────────────────────────────
              ActionButton(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil via Kamera',
                subtitle: 'Foto langsung & analisis',
                backgroundColor: AppTheme.primaryGreen,
                iconBackgroundColor: Colors.white.withOpacity(0.15),
                titleColor: Colors.white,
                subtitleColor: Colors.white.withOpacity(0.65),
                arrowColor: Colors.white,
                arrowBackgroundColor: Colors.white.withOpacity(0.15),
                onTap: () => _pickFromCamera(context),
              ),

              const SizedBox(height: 10),

              // ── Tombol Upload dari Galeri ──────────────────────────────────
              ActionButton(
                icon: Icons.photo_library_rounded,
                title: 'Upload dari Galeri',
                subtitle: 'Analisis foto tersimpan',
                backgroundColor: const Color(0xFFFFF8F6),
                iconBackgroundColor: const Color(0xFFFDEAE5),
                titleColor: const Color(0xFF2D1A18),
                subtitleColor: const Color(0xFF9A7872),
                arrowColor: AppTheme.tomatoRed,
                arrowBackgroundColor: const Color(0xFFEECFC9),
                borderColor: const Color(0xFFEECFC9),
                onTap: () => _pickFromGallery(context),
              ),

              // ── Divider ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                        child: Divider(color: AppTheme.borderColor, height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(color: AppTheme.borderColor, height: 1)),
                  ],
                ),
              ),

              // ── Tombol Deteksi Realtime ────────────────────────────────────
              GestureDetector(
                onTap: () => _goLive(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFB8DED8),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8F0EC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.radar_rounded,
                              color: AppTheme.tealAccent,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5DCF4E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Deteksi Realtime',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A5A52),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD8F0EC),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A5A52),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Kamera langsung deteksi otomatis',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5A8A84),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC0DDD9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF1A5A52),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
