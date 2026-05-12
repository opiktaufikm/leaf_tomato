// lib/screens/result_screen.dart
// Halaman hasil klasifikasi — hanya menampilkan Info dan Gejala

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/classifier_service.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final ClassificationResult result;

  const ResultScreen({super.key, required this.imageFile, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Hanya 2 tab: Info dan Gejala
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.result.isHealthy ? AppTheme.primaryGreen : AppTheme.tomatoRed;
  Color get _lightColor => widget.result.isHealthy ? AppTheme.accentGreen : AppTheme.lightRed;

  Color _severityColor(int level) {
    switch (level) {
      case 0: return AppTheme.primaryGreen;
      case 1: return AppTheme.warningAmber;
      case 2: return Colors.orange;
      case 3: return AppTheme.tomatoRed;
      default: return AppTheme.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final info = DiseaseInfo.getInfo(result.label);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App Bar dengan gambar ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: Colors.black87,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(widget.imageFile, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black26, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Konten ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Kartu hasil utama ──────────────────────────────
                      _buildResultCard(result, info),
                      const SizedBox(height: 12),

                      // ── Tab navigasi (hanya Info & Gejala) ────────────
                      _buildTabBar(),
                      const SizedBox(height: 12),

                      // ── Konten tab ─────────────────────────────────────
                      _buildTabContent(info),
                      const SizedBox(height: 12),

                      // ── Metadata ───────────────────────────────────────
                      _buildMetaRow(info),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kartu hasil utama ─────────────────────────────────────────────────────
  Widget _buildResultCard(ClassificationResult result, Info info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _lightColor, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(
                      result.isHealthy ? 'SEHAT' : 'TERDETEKSI PENYAKIT',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _primaryColor, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nama penyakit
          Text(
            info.indonesianName,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _primaryColor, height: 1.1),
          ),
          if (info.scientificName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(info.scientificName, style: const TextStyle(fontSize: 13, color: AppTheme.subtleText, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 16),

          // Confidence + Keparahan
          Row(
            children: [
              Expanded(child: _buildInfoBox(
                icon: Icons.verified_rounded,
                iconColor: _primaryColor,
                value: result.confidencePercent,
                subLabel: 'Kepercayaan',
                detail: result.confidenceLabel,
                bgColor: _lightColor,
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoBox(
                icon: Icons.warning_amber_rounded,
                iconColor: _severityColor(info.severityLevel),
                value: info.severity,
                subLabel: 'Tingkat Keparahan',
                detail: result.isHealthy ? 'Tidak perlu tindakan' : 'Perlu penanganan',
                bgColor: result.isHealthy ? AppTheme.accentGreen : AppTheme.lightAmber,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subLabel,
    required String detail,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: iconColor)),
          Text(subLabel, style: const TextStyle(fontSize: 10, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(fontSize: 10, color: AppTheme.mutedText)),
        ],
      ),
    );
  }

  // ── Tab navigasi: hanya Info & Gejala ────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Info', 'Gejala'];
    final icons = [Icons.info_outline_rounded, Icons.search_rounded];

    return Row(
      children: tabs.asMap().entries.map((entry) {
        final i = entry.key;
        final isActive = _activeTab == i;
        return GestureDetector(
          onTap: () => setState(() => _activeTab = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? _primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? _primaryColor : AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Icon(icons[i], size: 14, color: isActive ? Colors.white : AppTheme.subtleText),
                const SizedBox(width: 6),
                Text(
                  entry.value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppTheme.subtleText),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Konten tab ────────────────────────────────────────────────────────────
  Widget _buildTabContent(Info info) {
    Widget content;
    switch (_activeTab) {
      case 0: // Info
        content = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DESKRIPSI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.mutedText, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(info.description, style: const TextStyle(fontSize: 13, color: AppTheme.darkText, height: 1.6)),
            ],
          ),
        );
        break;
      case 1: // Gejala
        content = _buildListCard(
          title: 'GEJALA YANG TERLIHAT',
          items: info.symptoms.isEmpty ? ['Tidak ada gejala yang perlu diperhatikan'] : info.symptoms,
          iconColor: Colors.orange,
          icon: Icons.circle,
        );
        break;
      default:
        content = const SizedBox();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(_activeTab), child: content),
    );
  }

  Widget _buildListCard({
    required String title,
    required List<String> items,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.mutedText, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 4, right: 2), child: Icon(icon, size: 12, color: iconColor)),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: AppTheme.darkText, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Metadata ──────────────────────────────────────────────────────────────
  Widget _buildMetaRow(Info info) {
    return Row(
      children: [
        _buildMetaChip(icon: Icons.people_alt_outlined, label: info.spreadType, sublabel: 'Cara Menyebar'),
        const SizedBox(width: 8),
        _buildMetaChip(icon: Icons.wb_sunny_outlined, label: info.season, sublabel: 'Musim'),
      ],
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label, required String sublabel}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderColor)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.subtleText),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkText)),
                  Text(sublabel, style: const TextStyle(fontSize: 10, color: AppTheme.mutedText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DiseaseInfoExt on DiseaseInfo {
  static List<String> get labels => ['Leaf Spot', 'Leaf Blight', 'Powdery Mildew', 'Healthy'];
}
