import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/detection_record.dart';
import '../services/detection_history_service.dart';
import '../widgets/history_list_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with WidgetsBindingObserver {
  final DetectionHistoryService _historyService = DetectionHistoryService();
  DetectionStatus? _activeFilter;
  List<DetectionRecord> _allHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data ketika app resume (kembali ke foreground)
    if (state == AppLifecycleState.resumed) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final records = await _historyService.getAllDetections();
      if (mounted) {
        setState(() {
          _allHistory = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() {
          _allHistory = [];
          _isLoading = false;
        });
      }
    }
  }

  List<DetectionRecord> get _filteredHistory {
    if (_activeFilter == null) return _allHistory;
    return _allHistory.where((r) => r.status == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        child: SafeArea(
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
                        '${_allHistory.length} data terekam · 30 hari terakhir',
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
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Memuat riwayat...', style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredHistory.isEmpty)
                SliverToBoxAdapter(
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
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = _filteredHistory[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(record.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.tomatoRed,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                            ),
                            confirmDismiss: (direction) => _showDeleteConfirmation(context, record),
                            onDismissed: (direction) {
                              _deleteRecord(record);
                            },
                            child: HistoryListItem(record: record),
                          ),
                        );
                      },
                      childCount: _filteredHistory.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilkan dialog konfirmasi sebelum hapus
  Future<bool?> _showDeleteConfirmation(BuildContext context, DetectionRecord record) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: Text('Apakah Anda yakin ingin menghapus data "${record.diseaseName}"?\nTindakan ini tidak dapat dibatalkan.'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppTheme.tomatoRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Hapus record dari history
  Future<void> _deleteRecord(DetectionRecord record) async {
    try {
      await _historyService.deleteDetection(record.id);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Riwayat dihapus'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppTheme.tomatoRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
