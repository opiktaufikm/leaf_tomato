import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Data model for each guide section ─────────────────────────────────────────
class _GuideSection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color accentColor;
  final List<_GuideStep> steps;
  final String tip;

  const _GuideSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.accentColor,
    required this.steps,
    required this.tip,
  });
}

class _GuideStep {
  final int number;
  final String title;
  final String description;
  final IconData stepIcon;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
    required this.stepIcon,
  });
}

// ── Guide data ─────────────────────────────────────────────────────────────────
const List<_GuideSection> _guideSections = [
  _GuideSection(
    id: 'gallery',
    title: 'Upload dari Galeri',
    subtitle: 'Analisis foto daun dari penyimpanan',
    icon: Icons.photo_library_rounded,
    iconColor: AppTheme.tomatoRed,
    iconBg: AppTheme.lightRed,
    accentColor: AppTheme.tomatoRed,
    tip:
        'Gunakan foto dengan pencahayaan yang cukup dan daun terlihat jelas tanpa bayangan berlebih untuk hasil terbaik.',
    steps: [
      _GuideStep(
        number: 1,
        title: 'Buka Halaman Home',
        description:
            'Pastikan kamu berada di halaman utama aplikasi. Kamu akan melihat tiga tombol aksi di bagian bawah.',
        stepIcon: Icons.home_rounded,
      ),
      _GuideStep(
        number: 2,
        title: 'Ketuk "Upload dari Galeri"',
        description:
            'Tap tombol merah bertuliskan "Upload dari Galeri". Aplikasi akan meminta izin akses galeri foto jika belum diberikan.',
        stepIcon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        number: 3,
        title: 'Pilih Foto Daun',
        description:
            'Galeri foto akan terbuka. Pilih foto daun tomat yang ingin dianalisis. Pastikan gambar daun terlihat jelas dan tidak buram.',
        stepIcon: Icons.photo_rounded,
      ),
      _GuideStep(
        number: 4,
        title: 'Tunggu Proses Analisis',
        description:
            'Aplikasi akan memproses gambar menggunakan model. Proses ini berlangsung beberapa detik tergantung kualitas gambar.',
        stepIcon: Icons.hourglass_top_rounded,
      ),
      _GuideStep(
        number: 5,
        title: 'Lihat Hasil Deteksi',
        description:
            'Hasil analisis akan ditampilkan beserta nama penyakit, tingkat kepercayaan (confidence), dan deskripsi penyakit.',
        stepIcon: Icons.task_alt_rounded,
      ),
    ],
  ),
  _GuideSection(
    id: 'camera',
    title: 'Ambil via Kamera',
    subtitle: 'Foto langsung & analisis seketika',
    icon: Icons.camera_alt_rounded,
    iconColor: AppTheme.primaryGreen,
    iconBg: AppTheme.accentGreen,
    accentColor: AppTheme.primaryGreen,
    tip:
        'Pastikan daun berada di tengah frame, jarak ideal 15–30 cm dari kamera, dengan cahaya alami yang merata untuk akurasi terbaik.',
    steps: [
      _GuideStep(
        number: 1,
        title: 'Buka Halaman Home',
        description:
            'Pastikan kamu berada di halaman utama. Siapkan daun tomat yang ingin diperiksa kondisinya.',
        stepIcon: Icons.home_rounded,
      ),
      _GuideStep(
        number: 2,
        title: 'Ketuk "Ambil via Kamera"',
        description:
            'Tap tombol hijau bertuliskan "Ambil via Kamera". Izin kamera akan diminta jika belum diberikan sebelumnya.',
        stepIcon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        number: 3,
        title: 'Arahkan Kamera ke Daun',
        description:
            'Arahkan kamera ke daun tomat. Pastikan seluruh daun atau bagian yang dicurigai sakit terlihat jelas dalam frame.',
        stepIcon: Icons.center_focus_strong_rounded,
      ),
      _GuideStep(
        number: 4,
        title: 'Ambil Foto',
        description:
            'Ketuk tombol shutter atau tombol di layar untuk mengambil foto. Tahan kamera dengan stabil agar gambar tidak buram.',
        stepIcon: Icons.camera_rounded,
      ),
      _GuideStep(
        number: 5,
        title: 'Konfirmasi & Analisis',
        description:
            'Tinjau foto yang diambil. Jika sudah bagus, konfirmasi untuk memulai analisis. Hasil akan muncul dalam beberapa detik.',
        stepIcon: Icons.check_circle_rounded,
      ),
    ],
  ),
  _GuideSection(
    id: 'realtime',
    title: 'Deteksi Realtime',
    subtitle: 'Kamera live dengan deteksi otomatis',
    icon: Icons.radar_rounded,
    iconColor: Color(0xFF2A7068),
    iconBg: Color(0xFFE8F4F2),
    accentColor: Color(0xFF2A7068),
    tip:
        'Mode ini membutuhkan cahaya yang baik. Gerakkan kamera perlahan agar dapat memproses setiap frame dengan akurat.',
    steps: [
      _GuideStep(
        number: 1,
        title: 'Buka Halaman Home',
        description:
            'Pergi ke halaman utama. Tombol Deteksi Realtime berada di bagian paling bawah, ditandai badge "LIVE" berwarna hijau.',
        stepIcon: Icons.home_rounded,
      ),
      _GuideStep(
        number: 2,
        title: 'Ketuk "Deteksi Realtime"',
        description:
            'Tap tombol teal berlabel "Deteksi Realtime". Halaman live camera viewfinder akan terbuka secara fullscreen.',
        stepIcon: Icons.touch_app_rounded,
      ),
      _GuideStep(
        number: 3,
        title: 'Arahkan ke Daun Tomat',
        description:
            'Arahkan kamera ke daun tomat. Posisikan daun di dalam kotak scanner yang terlihat di tengah layar.',
        stepIcon: Icons.crop_free_rounded,
      ),
      _GuideStep(
        number: 4,
        title: 'Deteksi Berjalan Otomatis',
        description:
            'Tanda lingkaran oranye akan muncul jika terdeteksi area yang bermasalah. Bar kepercayaan di bawah menunjukkan akurasi deteksi secara live.',
        stepIcon: Icons.auto_awesome_rounded,
      ),
      _GuideStep(
        number: 5,
        title: 'Simpan Hasil',
        description:
            'Saat hasil deteksi sudah stabil, ketuk tombol "Capture & Save" untuk menyimpan hasil ke riwayat scan.',
        stepIcon: Icons.save_alt_rounded,
      ),
    ],
  ),
  _GuideSection(
    id: 'history',
    title: 'Riwayat Deteksi',
    subtitle: 'Lihat & kelola semua hasil scan',
    icon: Icons.history_rounded,
    iconColor: Color(0xFF5A5A8A),
    iconBg: Color(0xFFEEEEF8),
    accentColor: Color(0xFF5A5A8A),
    tip:
        'Riwayat tersimpan secara lokal di perangkatmu. Gunakan filter untuk menemukan scan tertentu dengan lebih cepat.',
    steps: [
      _GuideStep(
        number: 1,
        title: 'Buka Tab History',
        description:
            'Ketuk ikon "History" di navigation bar bawah. Halaman riwayat akan menampilkan semua scan yang pernah dilakukan.',
        stepIcon: Icons.history_rounded,
      ),
      _GuideStep(
        number: 2,
        title: 'Lihat Ringkasan Statistik',
        description:
            'Di bagian atas terdapat kartu ringkasan yang menampilkan jumlah scan sehat vs sakit, beserta grafik tren 7 hari terakhir.',
        stepIcon: Icons.bar_chart_rounded,
      ),
      _GuideStep(
        number: 3,
        title: 'Gunakan Filter',
        description:
            'Ketuk chip filter "All", "Healthy", "Diseased", atau "Suspect" untuk menyaring riwayat berdasarkan status deteksi.',
        stepIcon: Icons.filter_list_rounded,
      ),
      _GuideStep(
        number: 4,
        title: 'Baca Detail Riwayat',
        description:
            'Setiap item menampilkan thumbnail daun berwarna, nama penyakit, tanggal scan, dan tingkat kepercayaan model.',
        stepIcon: Icons.info_outline_rounded,
      ),
      _GuideStep(
        number: 5,
        title: 'Ketuk untuk Detail Lengkap',
        description:
            'Tap salah satu item riwayat untuk melihat detail lengkap: gambar asli, jenis penyakit, tingkat keparahan, dan saran penanganan.',
        stepIcon: Icons.open_in_new_rounded,
      ),
    ],
  ),
];

// ── Main Guide Screen ──────────────────────────────────────────────────────────
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _guideSections.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
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
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panduan Penggunaan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                        Text(
                          'Cara menggunakan semua fitur TomGuard',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.subtleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Help badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.help_rounded,
                            size: 12, color: AppTheme.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Help',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Feature Tab Selector ────────────────────────────────────────
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _guideSections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final section = _guideSections[i];
                  final isActive = _activeTab == i;
                  return GestureDetector(
                    onTap: () {
                      _tabController.animateTo(i);
                      setState(() => _activeTab = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? section.accentColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isActive
                              ? section.accentColor
                              : AppTheme.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            section.icon,
                            size: 22,
                            color: isActive
                                ? Colors.white
                                : section.iconColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            section.title.split(' ').first == 'Upload'
                                ? 'Galeri'
                                : section.title.split(' ').first == 'Ambil'
                                    ? 'Kamera'
                                    : section.title.split(' ').first ==
                                            'Deteksi'
                                        ? 'Realtime'
                                        : 'History',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.subtleText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Content ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: _guideSections.map((section) {
                  return _GuideSectionView(section: section);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── One full section view ──────────────────────────────────────────────────────
class _GuideSectionView extends StatelessWidget {
  final _GuideSection section;

  const _GuideSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  section.accentColor.withOpacity(0.08),
                  section.accentColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: section.accentColor.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: section.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    section.icon,
                    color: section.iconColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: section.accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.subtleText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: section.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${section.steps.length} langkah',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: section.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Steps ────────────────────────────────────────────────────────
          const Text(
            'LANGKAH-LANGKAH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.subtleText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          ...section.steps.asMap().entries.map((entry) {
            final isLast = entry.key == section.steps.length - 1;
            return _StepItem(
              step: entry.value,
              accentColor: section.accentColor,
              isLast: isLast,
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Individual step item with connector line ───────────────────────────────────
class _StepItem extends StatelessWidget {
  final _GuideStep step;
  final Color accentColor;
  final bool isLast;

  const _StepItem({
    required this.step,
    required this.accentColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: number + connector line ──────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Step number circle
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${step.number}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                if (isLast) const SizedBox(height: 16),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Right: content card ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        step.stepIcon,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtleText,
                              height: 1.5,
                            ),
                          ),
                        ],
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
}
