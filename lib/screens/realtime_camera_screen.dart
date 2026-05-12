// ════════════════════════════════════════════════════════════════════════════
// lib/screens/realtime_camera_screen.dart
//
// Real-time tomato leaf classification using live camera feed
// ════════════════════════════════════════════════════════════════════════════

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/classifier_service.dart';

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() => _RealtimeCameraScreenState();
}

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  String _currentLabel = "Scanning...";
  double _currentConfidence = 0.0;
  final ClassifierService _classifier = ClassifierService();
  
  // ── Performance optimization ─────────────────────────────────────────────
  int _frameCount = 0;
  final int _frameSkip = 2; // Process every 3rd frame (skip 2)
  DateTime _lastInferenceTime = DateTime.now();
  final int _inferenceIntervalMs = 500; // Minimum 500ms between inferences

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// ── Inisialisasi kamera ───────────────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final cameraList = await availableCameras();
      if (cameraList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No cameras available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _cameraController = CameraController(
        cameraList[0],
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {});

      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Camera error: $e'),
            backgroundColor: AppTheme.tomatoRed,
          ),
        );
      }
    }
  }

  /// ── Proses setiap frame dari camera stream ──────────────────────────────
  Future<void> _processCameraImage(CameraImage cameraImage) async {
    _frameCount++;
    
    // ── Skip frames untuk performance ────────────────────────────────────
    if (_frameCount % (_frameSkip + 1) != 0) {
      return;
    }

    // ── Throttle inference frequency ─────────────────────────────────────
    final now = DateTime.now();
    if (now.difference(_lastInferenceTime).inMilliseconds < _inferenceIntervalMs) {
      return;
    }

    if (_isDetecting) return;
    _isDetecting = true;
    _lastInferenceTime = now;

    try {
      // ── Bypass full image conversion, gunakan raw bytes langsung ──────
      // Encode hanya YUV planes yang diperlukan untuk model
      final imageBytes = _encodeYUVDirect(cameraImage);
      
      if (imageBytes == null) {
        _isDetecting = false;
        return;
      }

      // ── Gunakan ClassifierService untuk klasifikasi ──────────────────
      final result = await _classifier.classifyImageBytes(imageBytes);

      if (mounted) {
        setState(() {
          _currentLabel = result.label;
          _currentConfidence = result.confidence;
        });
      }
    } catch (e) {
      debugPrint('❌ Detection error: $e');
    }

    _isDetecting = false;
  }

  /// ── Encode YUV planes langsung tanpa full image conversion ────────────────
  Uint8List? _encodeYUVDirect(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group != ImageFormatGroup.yuv420) {
        return null;
      }

      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];

      // Combine YUV planes into single byte array (minimal allocation)
      final int totalSize = yPlane.bytes.length + 
                            uPlane.bytes.length + 
                            vPlane.bytes.length;
      
      final yuvBytes = Uint8List(totalSize);
      var offset = 0;

      // Copy Y plane
      yuvBytes.setRange(offset, offset + yPlane.bytes.length, yPlane.bytes);
      offset += yPlane.bytes.length;

      // Copy U plane
      yuvBytes.setRange(offset, offset + uPlane.bytes.length, uPlane.bytes);
      offset += uPlane.bytes.length;

      // Copy V plane
      yuvBytes.setRange(offset, offset + vPlane.bytes.length, vPlane.bytes);

      // Wrap dengan YUV420 header untuk ClassifierService
      // Format: [width:4 bytes][height:4 bytes][yPlaneSize:4][YUV data...]
      final header = Uint8List(12);
      header.buffer.asInt32List()[0] = cameraImage.width;
      header.buffer.asInt32List()[1] = cameraImage.height;
      header.buffer.asInt32List()[2] = yPlane.bytes.length;

      final fullData = Uint8List(12 + totalSize);
      fullData.setRange(0, 12, header);
      fullData.setRange(12, 12 + totalSize, yuvBytes);

      return fullData;
    } catch (e) {
      debugPrint('⚠️  YUV encoding failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ───────────────────────────────────────────────
          Center(child: CameraPreview(_cameraController!)),

          // ── Gradient overlay di atas ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Back button ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Hasil deteksi di bawah ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Card hasil deteksi ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.primaryGreen.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // ── Label ────────────────────────────────────────
                          Text(
                            "Detection Result",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Nama penyakit/kesehatan ──────────────────────
                          Text(
                            _currentLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // ── Confidence percentage ────────────────────────
                          Text(
                            "${(_currentConfidence * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // ── Confidence level text ────────────────────────
                          const SizedBox(height: 6),
                          Text(
                            _getConfidenceLabel(_currentConfidence),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Info hint ────────────────────────────────────────
                    Text(
                      'Point camera at tomato leaf for real-time analysis',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),

                    // ── Status indicator ─────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isDetecting
                                ? Colors.amber
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isDetecting ? 'Analyzing...' : 'Ready',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
