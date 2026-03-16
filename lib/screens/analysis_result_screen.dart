import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';

/// Halaman hasil analisis lengkap setelah AI memproses gambar.
class AnalysisResultScreen extends StatefulWidget {
  final ImageSourceType sourceType;
  final AnalysisResult? result;
  final String? imagePath;

  const AnalysisResultScreen({
    super.key,
    required this.sourceType,
    this.result,
    this.imagePath,
  });

  @override
  State<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late AnalysisResult _result;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    if (widget.result != null) {
      _result = widget.result!;
    } else {
      _result = getRandomAnalysisResult();
    }
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ResultView(
      result: _result,
      fadeAnim: _fadeAnim,
      slideAnim: _slideAnim,
      sourceType: widget.sourceType,
    );
  }
}

// ── Result View (shown after analysis) ────────────────────────────────────────
class _ResultView extends StatefulWidget {
  final AnalysisResult result;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final ImageSourceType sourceType;

  const _ResultView({
    required this.result,
    required this.fadeAnim,
    required this.slideAnim,
    required this.sourceType,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  int _activeTab = 0; // 0=Info, 1=Gejala, 2=Penanganan, 3=Pencegahan

  void _saveToHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Hasil disimpan ke riwayat'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: widget.fadeAnim,
        child: SlideTransition(
          position: widget.slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SliverAppBar with image ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color(0xFF0D1A0C),
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => _saveToHistory(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.save_alt_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Leaf scene (placeholder for real image)
                      CustomPaint(
                        painter: _ResultLeafPainter(
                            isHealthy: result.isHealthy),
                      ),
                      // Bottom gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0A1A09).withOpacity(0.8),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      // Source badge
                      Positioned(
                        top: 56,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.sourceType == ImageSourceType.camera
                                    ? Icons.camera_alt_rounded
                                    : Icons.photo_library_rounded,
                                size: 11,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.sourceType == ImageSourceType.camera
                                    ? 'Kamera'
                                    : 'Galeri',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Result content ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Primary result card ─────────────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge + share button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: result.lightColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: result.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      result.isHealthy
                                          ? 'SEHAT'
                                          : 'TERDETEKSI',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: result.primaryColor,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: const Icon(
                                    Icons.share_rounded,
                                    size: 16,
                                    color: AppTheme.subtleText,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Disease name
                          Text(
                            result.diseaseName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: result.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.scientificName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.subtleText,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Confidence + severity row
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  label: 'Kepercayaan',
                                  value:
                                      '${result.confidence.toStringAsFixed(1)}%',
                                  icon: Icons.verified_rounded,
                                  color: result.primaryColor,
                                  bgColor: result.lightColor,
                                  subtitle: _confidenceLabel(result.confidence),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  label: 'Tingkat Keparahan',
                                  value: result.severityLabel,
                                  icon: Icons.warning_amber_rounded,
                                  color: result.severityColor,
                                  bgColor:
                                      result.severityColor.withOpacity(0.1),
                                  subtitle: _severityHint(result.severity),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Confidence bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Akurasi Model',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.subtleText,
                                    ),
                                  ),
                                  Text(
                                    '${result.confidence.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: result.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: result.confidence / 100,
                                  backgroundColor:
                                      result.lightColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      result.primaryColor),
                                  minHeight: 7,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Competing diseases (alternative predictions) ─────────
                    if (!result.isHealthy) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PREDIKSI LAIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.subtleText,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _AlternativePrediction(
                              name: 'Healthy',
                              confidence: 100 - result.confidence - 5,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(height: 8),
                            _AlternativePrediction(
                              name: 'Septoria Leaf Spot',
                              confidence: 5.2,
                              color: const Color(0xFF5A5A8A),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Detail Tab Bar ───────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _DetailTab(
                            label: 'Info',
                            icon: Icons.info_outline_rounded,
                            isActive: _activeTab == 0,
                            onTap: () =>
                                setState(() => _activeTab = 0),
                          ),
                          _DetailTab(
                            label: 'Gejala',
                            icon: Icons.search_rounded,
                            isActive: _activeTab == 1,
                            onTap: () =>
                                setState(() => _activeTab = 1),
                          ),
                          _DetailTab(
                            label: 'Penanganan',
                            icon: Icons.healing_rounded,
                            isActive: _activeTab == 2,
                            onTap: () =>
                                setState(() => _activeTab = 2),
                          ),
                          _DetailTab(
                            label: 'Pencegahan',
                            icon: Icons.shield_rounded,
                            isActive: _activeTab == 3,
                            onTap: () =>
                                setState(() => _activeTab = 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Tab content ──────────────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildTabContent(result),
                    ),

                    const SizedBox(height: 16),

                    // ── Action buttons ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _saveToHistory(context),
                              icon: const Icon(Icons.save_alt_rounded,
                                  size: 18),
                              label: const Text('Simpan ke Riwayat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                              icon: const Icon(Icons.camera_alt_rounded,
                                  size: 18),
                              label: const Text('Scan Gambar Lain'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AnalysisResult result) {
    switch (_activeTab) {
      case 0:
        return _InfoTab(result: result, key: const ValueKey(0));
      case 1:
        return _ListTab(
          key: const ValueKey(1),
          items: result.symptoms,
          icon: Icons.search_rounded,
          color: const Color(0xFF5A5A8A),
          emptyLabel: 'Tidak ada gejala yang dicatat',
        );
      case 2:
        return _ListTab(
          key: const ValueKey(2),
          items: result.treatments,
          icon: Icons.healing_rounded,
          color: AppTheme.tomatoRed,
          emptyLabel: 'Tidak diperlukan penanganan',
        );
      case 3:
        return _ListTab(
          key: const ValueKey(3),
          items: result.preventions,
          icon: Icons.shield_rounded,
          color: AppTheme.primaryGreen,
          emptyLabel: 'Tidak ada data pencegahan',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _confidenceLabel(double c) {
    if (c >= 90) return 'Sangat Yakin';
    if (c >= 75) return 'Cukup Yakin';
    if (c >= 60) return 'Kurang Yakin';
    return 'Tidak Pasti';
  }

  String _severityHint(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.none:
        return 'Tidak perlu tindakan';
      case SeverityLevel.low:
        return 'Pantau secara rutin';
      case SeverityLevel.moderate:
        return 'Segera tangani';
      case SeverityLevel.high:
        return 'Darurat!';
    }
  }
}

// ── Info tab ───────────────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final AnalysisResult result;

  const _InfoTab({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESKRIPSI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.subtleText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.darkText,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: 'Tipe',
                  value: result.isHealthy ? 'Normal' : 'Jamur',
                  icon: Icons.category_rounded,
                ),
              ),
              Expanded(
                child: _QuickStat(
                  label: 'Menyebar',
                  value: result.isHealthy ? 'Tidak' : 'Ya',
                  icon: Icons.share_location_rounded,
                ),
              ),
              Expanded(
                child: _QuickStat(
                  label: 'Musim',
                  value: 'Hujan',
                  icon: Icons.cloud_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.subtleText),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.mutedText)),
      ],
    );
  }
}

// ── List tab (symptoms / treatments / preventions) ─────────────────────────────
class _ListTab extends StatelessWidget {
  final List<String> items;
  final IconData icon;
  final Color color;
  final String emptyLabel;

  const _ListTab({
    super.key,
    required this.items,
    required this.icon,
    required this.color,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Center(
            child: Text(emptyLabel,
                style: const TextStyle(
                    color: AppTheme.mutedText, fontSize: 13)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: e.key < items.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Metric card ────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String subtitle;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppTheme.subtleText)),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

// ── Alternative prediction row ─────────────────────────────────────────────────
class _AlternativePrediction extends StatelessWidget {
  final String name;
  final double confidence;
  final Color color;

  const _AlternativePrediction({
    required this.name,
    required this.confidence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeConf = confidence.clamp(0.0, 100.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.darkText)),
            ),
            Text('${safeConf.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: safeConf / 100,
            backgroundColor: AppTheme.background,
            valueColor: AlwaysStoppedAnimation<Color>(
                color.withOpacity(0.5)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ── Detail tab button ──────────────────────────────────────────────────────────
class _DetailTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DetailTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryGreen
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : AppTheme.subtleText),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color:
                      isActive ? Colors.white : AppTheme.subtleText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Leaf painter for result screen header ──────────────────────────────────────
class _ResultLeafPainter extends CustomPainter {
  final bool isHealthy;

  const _ResultLeafPainter({required this.isHealthy});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0A1509);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final hw = size.width * 0.38;
    final hh = size.height * 0.72;

    final leaf = Path()
      ..moveTo(cx, cy - hh * 0.5)
      ..cubicTo(cx + hw, cy - hh * 0.4, cx + hw * 0.9, cy + hh * 0.35,
          cx, cy + hh * 0.5)
      ..cubicTo(cx - hw * 0.9, cy + hh * 0.35, cx - hw, cy - hh * 0.4,
          cx, cy - hh * 0.5);

    canvas.drawPath(
        leaf, Paint()..color = const Color(0xFF3A7030).withOpacity(0.9));

    // Vein
    canvas.drawLine(
      Offset(cx, cy - hh * 0.42),
      Offset(cx, cy + hh * 0.45),
      Paint()
        ..color = const Color(0xFF5AA84E).withOpacity(0.4)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx - hw * 0.6, cy - 30),
        Paint()
          ..color = const Color(0xFF5AA84E).withOpacity(0.3)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(cx, cy + 15), Offset(cx + hw * 0.65, cy),
        Paint()
          ..color = const Color(0xFF5AA84E).withOpacity(0.3)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round);

    if (!isHealthy) {
      canvas.drawCircle(Offset(cx - 28, cy + 12), 20,
          Paint()..color = const Color(0xFFC8442A).withOpacity(0.75));
      canvas.drawCircle(Offset(cx + 32, cy - 18), 16,
          Paint()..color = const Color(0xFFD4692A).withOpacity(0.6));
      canvas.drawCircle(Offset(cx - 5, cy + 40), 12,
          Paint()..color = const Color(0xFFC8442A).withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
