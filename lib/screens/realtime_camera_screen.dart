// ════════════════════════════════════════════════════════════════════════════
// lib/screens/realtime_camera_screen.dart
//
// OPTIMIZATION STRATEGIES:
// ── 1. Frame Skipping: Process hanya setiap (N+1) frame, bukan setiap frame ──
//       Misal _frameSkip=3 → proses setiap 4 frame (skip 3 frame di antaranya)
//       Efek: Kurangi load CPU ~67% untuk frame processing
// ── 2. Inference Throttling: Minimum 650ms antar inference ─────────────────
//       Mencegah inference terlalu sering ketika CPU masih sibuk
// ── 3. Direct YUV→Tensor preprocessing: tidak encode/decode ulang frame ────
// ── 4. TFLite isolate inference: kerja native tidak menahan preview kamera ─
// ── 5. Camera Format: YUV420 (most compatible) + Low resolution ───────────
// ── 6. Status indicator (dot) untuk visual feedback ─────────────────────
//
// JIKA MASIH LAG: Adjust values di atas untuk trade-off quality vs speed
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/classifier_service.dart';

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() => _RealtimeCameraScreenState();
}

enum _InitStage { loadingModel, loadingCamera, error, ready }

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen>
    with WidgetsBindingObserver {
  final ClassifierService _classifier = ClassifierService();

  _InitStage _stage = _InitStage.loadingModel;
  String? _initError;

  CameraController? _cameraController;

  bool _isDetecting = false;
  String _currentLabel = '';
  double _currentConfidence = 0.0;
  bool _isValidDetection = false;
  bool _hasResult = false; // true begitu ada hasil pertama kali
  static const String _noObjectLabel = 'Objek Tidak Terdeteksi';

  // ── PERFORMANCE OPTIMIZATION KNOBS ────────────────────────────────────────
  // Kurangi frequency processing dengan:
  // - _frameSkip: Proses setiap (N+1) frame. Contoh _frameSkip=3 → proses setiap 4 frame
  // - _inferenceIntervalMs: Minimum millisecond antar inference attempt
  // Tweak nilai ini jika masih lag:
  static const int _frameSkip = 3; // Process every 4th frame (0 = process all)
  static const int _inferenceIntervalMs = 650; // Minimum ms between inferences

  int _frameCounter = 0; // Frame skip counter
  DateTime _lastInferenceTime = DateTime.now();
  DateTime _lastUiResultTime = DateTime.now();
  String _prevLabel = '';
  double _prevConfidence = -1.0;

  // ── Warna berdasarkan kondisi daun ───────────────────────────────────────
  // Sehat → hijau, Penyakit → merah, Belum ada hasil → hijau muda (idle)
  static const _gradientIdle = [Color(0xFF4A8C3F), Color(0xFF2D6B24)];
  static const _gradientHealthy = [Color(0xFF2D6B24), Color(0xFF1A4F15)];
  static const _gradientDisease = [Color(0xFFC8442A), Color(0xFF8B1A08)];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _classifier.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _InitStage.error;
          _initError = e.toString();
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _stage = _InitStage.loadingCamera);
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('Tidak ada kamera yang tersedia.');
        return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      if (!mounted) {
        return;
      }
      setState(() => _stage = _InitStage.ready);
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      _setError('Kamera error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ctrl.stopImageStream();
    } else if (state == AppLifecycleState.resumed &&
        _stage == _InitStage.ready) {
      ctrl.startImageStream(_processCameraImage);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Frame processing ──────────────────────────────────────────────────────
  Future<void> _processCameraImage(CameraImage frame) async {
    if (_isDetecting) {
      return;
    }

    _frameCounter++;
    if (_frameCounter % (_frameSkip + 1) != 0) {
      return;
    }

    final now = DateTime.now();
    if (_hasResult && now.difference(_lastUiResultTime).inMilliseconds > 1500) {
      _showObjectNotDetected(force: true);
    }

    if (now.difference(_lastInferenceTime).inMilliseconds <
        _inferenceIntervalMs) {
      return;
    }

    _isDetecting = true;
    _lastInferenceTime = now;

    try {
      final result = await _classifier.classifyCameraImage(frame);

      final isValidDetection = _classifier.isValidLeafResult(result);
      if (isValidDetection) {
        _applyDetectionResult(
          label: result.label,
          confidence: result.confidence,
          isValidDetection: true,
        );
      } else {
        _showObjectNotDetected(force: _isValidDetection);
      }
    } catch (e) {
      debugPrint('Detection error: $e');
      _showObjectNotDetected(force: true);
    } finally {
      _isDetecting = false;
    }
  }

  void _showObjectNotDetected({bool force = false}) {
    _applyDetectionResult(
      label: _noObjectLabel,
      confidence: 0.0,
      isValidDetection: false,
      force: force,
    );
  }

  void _applyDetectionResult({
    required String label,
    required double confidence,
    required bool isValidDetection,
    bool force = false,
  }) {
    if (!mounted) return;

    final bool labelChanged = label != _prevLabel;
    final bool confChanged = (confidence - _prevConfidence).abs() > 0.01;
    final bool validityChanged = isValidDetection != _isValidDetection;

    if (!force && !labelChanged && !confChanged && !validityChanged) {
      return;
    }

    _prevLabel = label;
    _prevConfidence = confidence;
    _lastUiResultTime = DateTime.now();
    setState(() {
      _currentLabel = label;
      _currentConfidence = confidence;
      _isValidDetection = isValidDetection;
      _hasResult = true;
    });
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _stage = _InitStage.error;
      _initError = msg;
    });
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  bool get _isHealthy {
    final l = _currentLabel.toLowerCase();
    return l.contains('healthy') || l.contains('sehat');
  }

  List<Color> _resultGradient() {
    if (!_hasResult || !_isValidDetection) return _gradientIdle;
    return _isHealthy ? _gradientHealthy : _gradientDisease;
  }

  Color get _frameColor {
    if (!_hasResult || !_isValidDetection) {
      return Colors.white.withOpacity(0.30);
    }
    return _isHealthy
        ? AppTheme.primaryGreen.withOpacity(0.9)
        : AppTheme.tomatoRed.withOpacity(0.9);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (_stage) {
        _InitStage.loadingModel => _buildLoading(
            icon: Icons.memory_rounded,
            message: 'Memuat model AI...',
            sub: 'assets/models/model_daun_tomat.tflite'),
        _InitStage.loadingCamera => _buildLoading(
            icon: Icons.camera_alt_rounded,
            message: 'Menginisialisasi kamera...',
            sub: 'Model berhasil dimuat ✓',
            subColor: Colors.greenAccent),
        _InitStage.error => _buildError(),
        _InitStage.ready => _buildCamera(),
      },
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading({
    required IconData icon,
    required String message,
    String? sub,
    Color? subColor,
  }) {
    return SafeArea(
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.lightGreen, AppTheme.primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              color: Color(0xFF4A8C3F), strokeWidth: 2.5),
        ),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(sub,
              style:
                  TextStyle(color: subColor ?? Colors.white38, fontSize: 11)),
        ],
        const Spacer(),
      ]),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.12)),
            child: const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Gagal Memuat',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_initError ?? 'Kesalahan tidak diketahui.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Text(
              'Pastikan file berikut ada di pubspec.yaml:\n'
              '  assets/models/model_daun_tomat.tflite\n'
              '  assets/labels/labels.txt',
              style: TextStyle(color: Colors.amber, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Kembali'),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              onPressed: () {
                setState(() {
                  _stage = _InitStage.loadingModel;
                  _initError = null;
                });
                _bootstrap();
              },
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Camera (ready) ────────────────────────────────────────────────────────
  Widget _buildCamera() {
    return Stack(children: [
      // Preview
      RepaintBoundary(child: Center(child: CameraPreview(_cameraController!))),

      // Top vignette
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
          ),
        ),
      ),

      // Back button
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black45, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),

      // Scan frame dengan corner markers
      Center(
        child: IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(
                color: _frameColor,
                width: _hasResult ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(children: [
              for (final a in [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ])
                Align(
                  alignment: a,
                  child: _CornerMark(alignment: a, color: _frameColor),
                ),
            ]),
          ),
        ),
      ),

      // Result card
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: RepaintBoundary(child: _buildResultCard()),
      ),
    ]);
  }

  // ── Result card ───────────────────────────────────────────────────────────
  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.75),
            Colors.transparent
          ],
        ),
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _resultGradient(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _resultGradient().first.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _hasResult ? _buildDetectedContent() : _buildIdleContent(),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _StatusDot(isActive: _isDetecting),
            const SizedBox(width: 7),
            Text(
              _isDetecting ? 'Menganalisis...' : 'Siap mendeteksi',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ]),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  // ── Hasil deteksi (selalu tampil setelah ada hasil pertama) ───────────────
  Widget _buildDetectedContent() {
    return Column(children: [
      const Text(
        'Hasil Deteksi',
        style:
            TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.3),
      ),
      const SizedBox(height: 8),
      Text(
        _currentLabel.isEmpty ? 'Memproses...' : _currentLabel,
        style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      if (_isValidDetection) ...[
        const SizedBox(height: 10),
        Text(
          '${(_currentConfidence * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    ]);
  }

  Widget _buildIdleContent() {
    return Column(children: [
      const Text(
        'Objek Tidak Terdeteksi',
        style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 6),
      const Text(
        'Arahkan kamera ke daun tomat',
        style: TextStyle(color: Colors.white70, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    ]);
  }
}

// ── Corner markers ────────────────────────────────────────────────────────────
class _CornerMark extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  const _CornerMark({required this.alignment, required this.color});

  @override
  Widget build(BuildContext context) {
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _CornerPainter(isLeft: isLeft, isTop: isTop, color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft, isTop;
  final Color color;
  const _CornerPainter(
      {required this.isLeft, required this.isTop, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? size.width : -size.width;
    final dy = isTop ? size.height : -size.height;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.isLeft != isLeft || old.isTop != isTop;
}

// ── Status dot ────────────────────────────────────────────────────────────────
class _StatusDot extends StatefulWidget {
  final bool isActive;
  const _StatusDot({required this.isActive});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final color =
            widget.isActive ? AppTheme.lightGreen : Colors.greenAccent;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5 * _pulse.value),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ],
          ),
        );
      },
    );
  }
}
