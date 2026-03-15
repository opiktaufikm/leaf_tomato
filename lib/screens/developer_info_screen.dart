import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/developer_card.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  static const List<Map<String, dynamic>> _developers = [
    {
      'name': 'Ahmad Rifai',
      'role': 'Lead Developer & ML Engineer',
      'email': 'ahmad.rifai@tomguard.ai',
      'tag': 'ML',
      'avatarColor': AppTheme.primaryGreen,
      'avatarBg': AppTheme.accentGreen,
      'tagBg': AppTheme.accentGreen,
      'tagColor': AppTheme.primaryGreen,
    },
    {
      'name': 'Siti Nurhaliza',
      'role': 'UI/UX Designer',
      'email': 'siti.nurhaliza@tomguard.ai',
      'tag': 'Design',
      'avatarColor': AppTheme.tomatoRed,
      'avatarBg': AppTheme.lightRed,
      'tagBg': AppTheme.lightRed,
      'tagColor': Color(0xFF9A2A18),
    },
    {
      'name': 'Budi Santoso',
      'role': 'Backend & API Developer',
      'email': 'budi.santoso@tomguard.ai',
      'tag': 'API',
      'avatarColor': AppTheme.tealAccent,
      'avatarBg': AppTheme.lightTeal,
      'tagBg': AppTheme.lightTeal,
      'tagColor': Color(0xFF1A5A54),
    },
  ];

  static const List<Map<String, String>> _techStack = [
    {'name': 'TensorFlow', 'type': 'green'},
    {'name': 'ResNet-50', 'type': 'green'},
    {'name': 'Flutter', 'type': 'red'},
    {'name': 'Firebase', 'type': 'blue'},
    {'name': 'OpenCV', 'type': 'green'},
    {'name': 'Dart', 'type': 'red'},
    {'name': 'Python', 'type': 'blue'},
    {'name': 'FastAPI', 'type': 'green'},
  ];

  Color _pillBg(String type) {
    switch (type) {
      case 'red':
        return const Color(0xFFFDEAE5);
      case 'blue':
        return const Color(0xFFE4EEF8);
      default:
        return const Color(0xFFE2EFE0);
    }
  }

  Color _pillFg(String type) {
    switch (type) {
      case 'red':
        return const Color(0xFF9A2A18);
      case 'blue':
        return const Color(0xFF1A4A7A);
      default:
        return const Color(0xFF2D5A28);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Dark header band ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 12,
                20,
                24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C2B1A), Color(0xFF2D4A28)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEVELOPER TEAM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0x99C8DCC5),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'TomGuard AI',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE8F5E6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tomato Leaf Disease Classifier',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0x88C8DCC5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Version pill
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
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7ED86E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'v2.4.1 · Production',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7ED86E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Developer Cards ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dev = _developers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeveloperCard(
                      name: dev['name'] as String,
                      role: dev['role'] as String,
                      email: dev['email'] as String,
                      tag: dev['tag'] as String,
                      avatarColor: dev['avatarColor'] as Color,
                      avatarBg: dev['avatarBg'] as Color,
                      tagBg: dev['tagBg'] as Color,
                      tagColor: dev['tagColor'] as Color,
                    ),
                  );
                },
                childCount: _developers.length,
              ),
            ),
          ),

          // ── Tech Stack ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TECH STACK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.subtleText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _techStack.map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _pillBg(tech['type']!),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tech['name']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _pillFg(tech['type']!),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Model Performance ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
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
                      'MODEL PERFORMANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.subtleText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PerformanceItem(
                            label: 'Accuracy',
                            value: '96.3%',
                            progress: 0.963,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PerformanceItem(
                            label: 'F1 Score',
                            value: '0.942',
                            progress: 0.942,
                            color: AppTheme.lightGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Diseases',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.subtleText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '9',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── App Info ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'APP INFO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.subtleText,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 12),
                    _InfoRow(label: 'App Name', value: 'TomGuard AI'),
                    _InfoRow(label: 'Version', value: '2.4.1'),
                    _InfoRow(label: 'Build', value: '2024.03.14'),
                    _InfoRow(label: 'Platform', value: 'Flutter (iOS & Android)'),
                    _InfoRow(label: 'License', value: 'MIT License'),
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

// ── Performance metric widget ──────────────────────────────────────────────────
class _PerformanceItem extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _PerformanceItem({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.subtleText),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFEDF2EC),
            color: color,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.subtleText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
