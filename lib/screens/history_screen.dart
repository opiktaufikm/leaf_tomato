import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/detection_record.dart';
import '../widgets/history_list_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DetectionStatus? _activeFilter;

  List<DetectionRecord> get _filteredHistory {
    if (_activeFilter == null) return dummyHistory;
    return dummyHistory.where((r) => r.status == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Deteksi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dummyHistory.length} data terekam · 30 hari terakhir',
                      style: const TextStyle(fontSize: 12, color: AppTheme.subtleText),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(label: 'Semua', isActive: _activeFilter == null, onTap: () => setState(() => _activeFilter = null)),
                          const SizedBox(width: 6),
                          _FilterChip(label: 'Sehat', isActive: _activeFilter == DetectionStatus.healthy, onTap: () => setState(() => _activeFilter = DetectionStatus.healthy)),
                          const SizedBox(width: 6),
                          _FilterChip(label: 'Penyakit', isActive: _activeFilter == DetectionStatus.diseased, onTap: () => setState(() => _activeFilter = DetectionStatus.diseased)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _filteredHistory.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.mutedText.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            const Text('Tidak ada hasil untuk filter ini', style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HistoryListItem(record: _filteredHistory[index]),
                        ),
                        childCount: _filteredHistory.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : const Color(0xFFEDF2EC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primaryGreen : const Color(0xFFD4E4D2), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(0xFF5A7558)),
        ),
      ),
    );
  }
}
