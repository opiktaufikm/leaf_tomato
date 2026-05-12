import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InvalidObjectDialog extends StatefulWidget {
  final VoidCallback onRetry;

  const InvalidObjectDialog({super.key, required this.onRetry});

  @override
  State<InvalidObjectDialog> createState() => _InvalidObjectDialogState();
}

class _InvalidObjectDialogState extends State<InvalidObjectDialog> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic));
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header dengan ikon ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    // Animated icon dengan circular background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.lightRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.tomatoRed,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Judul
                    const Text(
                      'Gambar Objek Tidak Terdeteksi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pesan ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Gambar yang Anda ambil bukan daun tomat yang dapat dianalisis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkText.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tips
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightRed.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 Tips:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tomatoRed,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Ambil gambar daun tomat yang jelas\n'
                            '• Pastikan latar belakang tidak terlalu rumit\n'
                            '• Hindari bayangan yang terlalu gelap\n'
                            '• Gunakan pencahayaan yang cukup',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkText.withOpacity(0.6),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Buttons ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Tombol Coba Lagi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onRetry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tomatoRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tombol Tutup
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.darkText,
                          side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
