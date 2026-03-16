import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import 'analysis_result_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final ImageSourceType sourceType;

  /// imagePath diisi setelah image_picker benar-benar diintegrasikan.
  /// Saat ini null = tampilkan placeholder ilustrasi.
  final String? imagePath;

  const ImagePreviewScreen({
    super.key,
    required this.sourceType,
    this.imagePath,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  bool get _isCamera => widget.sourceType == ImageSourceType.camera;
  String get _sourceLabel => _isCamera ? 'Kamera' : 'Galeri';
  IconData get _sourceIcon =>
      _isCamera ? Icons.camera_alt_rounded : Icons.photo_library_rounded;
  Color get _sourceColor =>
      _isCamera ? AppTheme.primaryGreen : AppTheme.tomatoRed;
  Color get _sourceBg =>
      _isCamera ? AppTheme.accentGreen : AppTheme.lightRed;

  // ── Mulai analisis → navigasi ke result screen ───────────────────────────
  Future<void> _startAnalysis() async {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AnalysisResultScreen(
          sourceType: widget.sourceType,
          imagePath: widget.imagePath,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  void _retake() {
    if (_isCamera) {
      _pickFromCamera(context);
    } else {
      _pickFromGallery(context);
    }
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null || !context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
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
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ImagePreviewScreen(
        sourceType: ImageSourceType.gallery,
        imagePath: file.path,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildImageArea()),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.darkText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCamera ? 'Preview Foto Kamera' : 'Foto dari Galeri',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                Text(
                  'Ketuk Analisis untuk memulai deteksi',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _sourceBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_sourceIcon, size: 12, color: _sourceColor),
                const SizedBox(width: 5),
                Text(
                  _sourceLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _sourceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String title, String subtitle, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.subtleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Area gambar ────────────────────────────────────────────────────────────
  Widget _buildImageArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gambar / placeholder
            widget.imagePath != null
                ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                : _buildPlaceholder(),

            // Overlay analisis
            if (_isAnalyzing) _buildAnalyzingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF111A10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco_rounded,
              size: 52,
              color: AppTheme.primaryGreen.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isCamera ? 'Foto dari Kamera' : 'Foto dari Galeri',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pratinjau gambar akan tampil di sini\nsetelah image_picker diintegrasikan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.35),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Corner accent decorations
          _buildCornerAccent(),
        ],
      ),
    );
  }

  Widget _buildCornerAccent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: Colors.white.withOpacity(0.35),
          ),
          const SizedBox(width: 6),
          Text(
            'Uncomment image_picker di pubspec.yaml',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingRings(),
          const SizedBox(height: 28),
          const Text(
            'Menganalisis Gambar...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Model AI sedang memproses',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 28),
          // Steps indicator
          _buildAnalysisSteps(),
        ],
      ),
    );
  }

  Widget _buildAnalysisSteps() {
    final steps = ['Preprocessing', 'Inferensi Model', 'Membaca Hasil'];
    return Column(
      children: steps.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryGreen.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.55)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _isAnalyzing
          ? _buildAnalyzingButton()
          : Row(
              children: [
                // Retake / pilih ulang
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _retake,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCamera
                                ? Icons.camera_alt_rounded
                                : Icons.photo_library_rounded,
                            size: 18,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCamera ? 'Foto Ulang' : 'Pilih Lain',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Analisis
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _startAnalysis,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.biotech_rounded,
                              size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Analisis Sekarang',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

  Widget _buildAnalyzingButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 10),
          const Text(
            'Model AI sedang berjalan...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing rings animation ────────────────────────────────────────────────────
class _PulsingRings extends StatefulWidget {
  @override
  State<_PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<_PulsingRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scale = Tween<double>(begin: 0.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.9, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryGreen, width: 2.5),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.biotech_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
