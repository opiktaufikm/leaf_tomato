import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';

class AnalyzingScreen extends StatefulWidget {
  final ImageSourceType sourceType;
  final VoidCallback onAnalysisDone;

  const AnalyzingScreen({
    super.key,
    required this.sourceType,
    required this.onAnalysisDone,
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Simulate analysis delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onAnalysisDone();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + _animation.value * 0.1,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.biotech_rounded,
                      size: 60,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Menganalisis Gambar...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Model AI sedang memproses',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.subtleText,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _animation.value,
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}