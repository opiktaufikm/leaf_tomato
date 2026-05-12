// ════════════════════════════════════════════════════════════════════════════
// lib/screens/realtime_camera_screen.dart
//
// Fix: hasil deteksi selalu ditampilkan (tidak diblok threshold)
//      warna hijau, badge dihapus, lag dikurangi
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../services/classifier_service.dart';
import '../services/detection_history_service.dart';
import '../models/detection_record.dart';

// ── Isolate entry point ───────────────────────────────────────────────────
void _yuvEncodeIsolate(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) {
    if (message is _YUVEncodeRequest) {
      message.replyPort.send(_encodeYUVStatic(
        message.yBytes, message.uBytes, message.vBytes,
        message.width, message.height,
      ));
    }
  });
}

Uint8List? _encodeYUVStatic(
  Uint8List yBytes, Uint8List uBytes, Uint8List vBytes,
  int width, int height,
) {
  try {
    final int total = yBytes.length + uBytes.length + vBytes.length;
    final out = Uint8List(12 + total);
    out.buffer.asInt32List()
      ..[0] = width
      ..[1] = height
      ..[2] = yBytes.length;
    var off = 12;
    out.setRange(off, off + yBytes.length, yBytes); off += yBytes.length;
    out.setRange(off, off + uBytes.length, uBytes); off += uBytes.length;
    out.setRange(off, off + vBytes.length, vBytes);
    return out;
  } catch (_) {
    return null;
  }
}

class _YUVEncodeRequest {
  final Uint8List yBytes, uBytes, vBytes;
  final int width, height;
  final SendPort replyPort;
  const _YUVEncodeRequest({
    required this.yBytes, required this.uBytes, required this.vBytes,
    required this.width, required this.height, required this.replyPort,
  });
}

// ════════════════════════════════════════════════════════════════════════════

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() => _RealtimeCameraScreenState();
}

enum _InitStage { loadingModel, loadingCamera, error, ready }

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen>
    with WidgetsBindingObserver {

  final ClassifierService _classifier = ClassifierService();
  final DetectionHistoryService _historyService = DetectionHistoryService();

  _InitStage _stage = _InitStage.loadingModel;
  String? _initError;

  CameraController? _cameraController;

  // Detection state — selalu tampilkan hasil apapun label/confidence-nya
  bool _isDetecting = false;
  String _currentLabel = '';
  double _currentConfidence = 0.0;
  bool _hasResult = false;       // true begitu ada hasil pertama kali
  Uint8List? _lastFrameBytes;    // Simpan frame terakhir untuk disimpan saat user klik Save

  // Throttle: 800ms antar inferensi untuk kurangi lag
  static const int _inferenceIntervalMs = 800;

  DateTime _lastInferenceTime = DateTime.now();
  String _prevLabel = '';
  double _prevConfidence = -1.0;

  Isolate? _encoderIsolate;
  SendPort? _encoderSendPort;
  bool _isolateReady = false;

  // ── Warna berdasarkan kondisi daun ───────────────────────────────────────
  // Sehat → hijau, Penyakit → merah, Belum ada hasil → hijau muda (idle)
  static const _gradientIdle    = [Color(0xFF4A8C3F), Color(0xFF2D6B24)];
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
      if (mounted) setState(() { _stage = _InitStage.error; _initError = e.toString(); });
      return;
    }
    if (!mounted) return;
    setState(() => _stage = _InitStage.loadingCamera);
    unawaited(_initEncoderIsolate());
    await _initCamera();
  }

  Future<void> _initEncoderIsolate() async {
    final rp = ReceivePort();
    _encoderIsolate = await Isolate.spawn(_yuvEncodeIsolate, rp.sendPort);
    rp.listen((msg) {
      if (msg is SendPort) { _encoderSendPort = msg; _isolateReady = true; }
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) { _setError('Tidak ada kamera yang tersedia.'); return; }
      _cameraController = CameraController(
        cameras[0], ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _stage = _InitStage.ready);
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      _setError('Kamera error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      ctrl.stopImageStream();
    } else if (state == AppLifecycleState.resumed && _stage == _InitStage.ready) {
      ctrl.startImageStream(_processCameraImage);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _encoderIsolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }

  // ── Frame processing ──────────────────────────────────────────────────────
  Future<void> _processCameraImage(CameraImage frame) async {
    final now = DateTime.now();
    if (now.difference(_lastInferenceTime).inMilliseconds < _inferenceIntervalMs) return;
    if (_isDetecting) return;
    _isDetecting = true;
    _lastInferenceTime = now;

    try {
      final bytes = _isolateReady && _encoderSendPort != null
          ? await _encodeInIsolate(frame)
          : _encodeYUVFallback(frame);
      if (bytes == null) { _isDetecting = false; return; }

      // Simpan frame bytes untuk di-save nanti jika user klik "Simpan Hasil"
      _lastFrameBytes = bytes;

      final result = await _classifier.classifyImageBytes(bytes);

      // ── Selalu tampilkan hasil apapun (tidak diblok threshold) ──────────
      final bool labelChanged = result.label != _prevLabel;
      final bool confChanged  = (result.confidence - _prevConfidence).abs() > 0.01;

      if (mounted && (labelChanged || confChanged)) {
        _prevLabel      = result.label;
        _prevConfidence = result.confidence;
        setState(() {
          _currentLabel      = result.label;
          _currentConfidence = result.confidence;
          _hasResult         = true;
        });
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    }
    _isDetecting = false;
  }

  Future<Uint8List?> _encodeInIsolate(CameraImage frame) async {
    if (frame.format.group != ImageFormatGroup.yuv420) return null;
    final rp = ReceivePort();
    _encoderSendPort!.send(_YUVEncodeRequest(
      yBytes: Uint8List.fromList(frame.planes[0].bytes),
      uBytes: Uint8List.fromList(frame.planes[1].bytes),
      vBytes: Uint8List.fromList(frame.planes[2].bytes),
      width: frame.width, height: frame.height, replyPort: rp.sendPort,
    ));
    final result = await rp.first as Uint8List?;
    rp.close();
    return result;
  }

  Uint8List? _encodeYUVFallback(CameraImage frame) {
    if (frame.format.group != ImageFormatGroup.yuv420) return null;
    return _encodeYUVStatic(
      frame.planes[0].bytes, frame.planes[1].bytes, frame.planes[2].bytes,
      frame.width, frame.height,
    );
  }

  /// Helper untuk simpan frame bytes ke file
  Future<String?> _saveFrameToFile(Uint8List? bytes) async {
    if (bytes == null) return null;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/detection_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${imagesDir.path}/realtime_$timestamp.jpg';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('Error saving frame: $e');
      return null;
    }
  }

  Future<void> _saveCurrentDetection() async {
    if (!_hasResult || _currentLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada hasil deteksi untuk disimpan'),
          backgroundColor: AppTheme.tomatoRed,
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    try {
      // Simpan frame ke file
      final imagePath = await _saveFrameToFile(_lastFrameBytes);
      
      final diseaseInfo = DiseaseInfo.getInfo(_currentLabel);
      final status = _isHealthy ? DetectionStatus.healthy : DetectionStatus.diseased;
      final placeholderColor = _isHealthy ? 'EBF5E8' : 'FEF3F1';

      final record = DetectionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        leafLabel: _currentLabel,
        diseaseName: _currentLabel,
        scientificName: diseaseInfo.scientificName.isEmpty ? _currentLabel : diseaseInfo.scientificName,
        scannedAt: DateTime.now(),
        status: status,
        confidence: _currentConfidence,
        imagePlaceholderColor: placeholderColor,
        imagePath: imagePath,
      );

      await _historyService.saveDetection(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil deteksi telah disimpan ke riwayat'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving detection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppTheme.tomatoRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() { _stage = _InitStage.error; _initError = msg; });
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────
  bool get _isHealthy {
    final l = _currentLabel.toLowerCase();
    return l.contains('healthy') || l.contains('sehat');
  }

  List<Color> _resultGradient() {
    if (!_hasResult) return _gradientIdle;
    return _isHealthy ? _gradientHealthy : _gradientDisease;
  }

  Color get _frameColor {
    if (!_hasResult) return Colors.white.withOpacity(0.30);
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
        _InitStage.loadingModel  => _buildLoading(
            icon: Icons.memory_rounded, message: 'Memuat model AI...',
            sub: 'assets/models/model_daun_tomat.tflite'),
        _InitStage.loadingCamera => _buildLoading(
            icon: Icons.camera_alt_rounded, message: 'Menginisialisasi kamera...',
            sub: 'Model berhasil dimuat ✓', subColor: Colors.greenAccent),
        _InitStage.error  => _buildError(),
        _InitStage.ready  => _buildCamera(),
      },
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading({
    required IconData icon, required String message, String? sub, Color? subColor,
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
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(color: Color(0xFF4A8C3F), strokeWidth: 2.5),
        ),
        const SizedBox(height: 16),
        Text(message,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        if (sub != null) ...[
          const SizedBox(height: 6),
          Text(sub, style: TextStyle(color: subColor ?? Colors.white38, fontSize: 11)),
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
              shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.12)),
            child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Gagal Memuat',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              onPressed: () {
                setState(() { _stage = _InitStage.loadingModel; _initError = null; });
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
        top: 0, left: 0, right: 0,
        child: IgnorePointer(
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
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
            width: 220, height: 220,
            decoration: BoxDecoration(
              border: Border.all(
                color: _frameColor,
                width: _hasResult ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(children: [
              for (final a in [
                Alignment.topLeft, Alignment.topRight,
                Alignment.bottomLeft, Alignment.bottomRight,
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
        bottom: 0, left: 0, right: 0,
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
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.95), Colors.black.withOpacity(0.75), Colors.transparent],
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
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _resultGradient().first.withOpacity(0.4),
                  blurRadius: 18, offset: const Offset(0, 6),
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
        style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.3),
      ),
      const SizedBox(height: 8),
      Text(
        _currentLabel.isEmpty ? 'Memproses...' : _currentLabel,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 10),
      Text(
        '${(_currentConfidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveCurrentDetection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.25),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 18),
              SizedBox(width: 8),
              Text('Simpan Hasil', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildIdleContent() {
    return Column(children: [
      const Text(
        'Objek Tidak Terdeteksi',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final isTop  = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(
        painter: _CornerPainter(isLeft: isLeft, isTop: isTop, color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft, isTop;
  final Color color;
  const _CornerPainter({required this.isLeft, required this.isTop, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 3
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final x  = isLeft ? 0.0 : size.width;
    final y  = isTop  ? 0.0 : size.height;
    final dx = isLeft ? size.width  : -size.width;
    final dy = isTop  ? size.height : -size.height;
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

class _StatusDotState extends State<_StatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 750),
  )..repeat(reverse: true);

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final color = widget.isActive ? AppTheme.lightGreen : Colors.greenAccent;
        return Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: color,
            boxShadow: [BoxShadow(
              color: color.withOpacity(0.5 * _pulse.value),
              blurRadius: 6, spreadRadius: 1,
            )],
          ),
        );
      },
    );
  }
}
