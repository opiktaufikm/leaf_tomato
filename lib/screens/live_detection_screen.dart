import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/scanner_box.dart';

class LiveDetectionScreen extends StatefulWidget {
  /// Set [showBackButton] to true when pushed as a standalone route from Home.
  final bool showBackButton;

  const LiveDetectionScreen({super.key, this.showBackButton = false});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  // Simulated detection state
  bool _isDetecting = true;
  String _detectedDisease = 'Early Blight';
  String _scientificName = 'Alternaria solani';
  double _confidence = 87.0;
  String _severity = 'Moderate';
  Color _severityColor = const Color(0xFFE8834A);

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // ── Placeholder: camera package initialisation ──────────────────────────
    // TODO: implement with `camera` package
    //
    // Future<void> _initCamera() async {
    //   final cameras = await availableCameras();
    //   final firstCamera = cameras.first;
    //   _cameraController = CameraController(
    //     firstCamera,
    //     ResolutionPreset.high,
    //   );
    //   await _cameraController.initialize();
    //   if (mounted) setState(() {});
    // }
    // _initCamera();
  }

  @override
  void dispose() {
    _scanController.dispose();
    // TODO: _cameraController.dispose();
    super.dispose();
  }

  void _captureAndSave() {
    // TODO: capture frame, run inference, save to history
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Capture & Save — belum diimplementasi'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Color(0xFFC5DCC2),
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'Live Detection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8F5E6),
                      ),
                    ),
                  ),
                  // Live badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulsingDot(),
                        const SizedBox(width: 5),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5DCF4E),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Viewfinder ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera preview placeholder background
                      Container(
                        color: const Color(0xFF0A1409),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 64,
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Camera Preview',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              Text(
                                '(Camera package placeholder)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Radial vignette overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.45),
                            ],
                            radius: 1.0,
                          ),
                        ),
                      ),

                      // Scanner box with animated scan line
                      Center(
                        child: ScannerBox(
                          scanAnimation: _scanController,
                          isDetecting: _isDetecting,
                        ),
                      ),

                      // Disease markers (simulated overlay dots)
                      if (_isDetecting) ...[
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.22,
                          top: MediaQuery.of(context).size.height * 0.18,
                          child: const _DiseaseMarker(),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.48,
                          top: MediaQuery.of(context).size.height * 0.14,
                          child: const _DiseaseMarker(),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.32,
                          top: MediaQuery.of(context).size.height * 0.26,
                          child: const _DiseaseMarker(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Confidence Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detection Confidence',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFC8DCC5).withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${_confidence.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5DCF4E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _confidence / 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: const Color(0xFF5DCF4E),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Detection Result Card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8834A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8834A).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _detectedDisease,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF0A570),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _scientificName,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFF0A570).withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_confidence.toInt()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8834A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Severity Row ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _InfoChip(
                    label: 'Severity',
                    value: _severity,
                    valueColor: _severityColor,
                  ),
                  const SizedBox(width: 8),
                  const _InfoChip(
                    label: 'Spread Risk',
                    value: 'Medium',
                    valueColor: Color(0xFFF5CA6A),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Capture Button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _captureAndSave,
                  icon: const Icon(Icons.camera_rounded, size: 18),
                  label: const Text('Capture & Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing green dot ──────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF5DCF4E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Animated orange disease marker overlay ─────────────────────────────────────
class _DiseaseMarker extends StatefulWidget {
  const _DiseaseMarker();

  @override
  State<_DiseaseMarker> createState() => _DiseaseMarkerState();
}

class _DiseaseMarkerState extends State<_DiseaseMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8834A), width: 1.5),
          color: const Color(0xFFE8834A).withOpacity(0.15),
        ),
      ),
    );
  }
}

// ── Small info chip ────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: const Color(0xFFC5DCC2).withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
