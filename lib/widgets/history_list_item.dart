import 'dart:io';
import 'package:flutter/material.dart';
import '../models/detection_record.dart';
import '../theme/app_theme.dart';

class HistoryListItem extends StatelessWidget {
  final DetectionRecord record;

  const HistoryListItem({super.key, required this.record});

  Color get _statusBg {
    switch (record.status) {
      case DetectionStatus.healthy:
        return AppTheme.accentGreen;
      case DetectionStatus.diseased:
        return AppTheme.lightRed;
      case DetectionStatus.suspect:
        return AppTheme.lightAmber;
    }
  }

  Color get _statusFg {
    switch (record.status) {
      case DetectionStatus.healthy:
        return AppTheme.primaryGreen;
      case DetectionStatus.diseased:
        return AppTheme.tomatoRed;
      case DetectionStatus.suspect:
        return AppTheme.warningAmber;
    }
  }

  Color get _thumbBg {
    switch (record.status) {
      case DetectionStatus.healthy:
        return AppTheme.accentGreen;
      case DetectionStatus.diseased:
        return AppTheme.lightRed;
      case DetectionStatus.suspect:
        return AppTheme.lightAmber;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return 'Hari ini, ${_timeStr(dt)}';
    if (diff.inHours < 24) return 'Hari ini, ${_timeStr(dt)}';
    if (diff.inHours < 48) return 'Kemarin, ${_timeStr(dt)}';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${_timeStr(dt)}';
  }

  String _timeStr(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // ── Thumbnail ───────────────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _thumbBg,
              borderRadius: BorderRadius.circular(12),
              border: record.imagePath != null ? Border.all(color: Colors.transparent) : null,
            ),
            child: _buildThumbnail(),
          ),

          const SizedBox(width: 12),

          // ── Info ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.diseaseName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(record.scannedAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Status tag ───────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.statusLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _statusFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build thumbnail: tampilkan gambar jika ada, atau gunakan leaf painter
  Widget _buildThumbnail() {
    // Jika ada imagePath dan file ada, tampilkan gambar
    if (record.imagePath != null && record.imagePath!.isNotEmpty) {
      final file = File(record.imagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CustomPaint(
              painter: _ThumbnailLeafPainter(status: record.status),
            ),
          ),
        );
      }
    }
    // Fallback ke leaf painter jika tidak ada gambar
    return CustomPaint(
      painter: _ThumbnailLeafPainter(status: record.status),
    );
  }
}

// ── Mini leaf CustomPainter for thumbnail ─────────────────────────────────────
class _ThumbnailLeafPainter extends CustomPainter {
  final DetectionStatus status;

  const _ThumbnailLeafPainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.3;

    final leafPath = Path()
      ..moveTo(cx, cy - r * 1.4)
      ..cubicTo(
          cx + r * 0.9, cy - r * 1.3, cx + r, cy, cx, cy + r * 1.4)
      ..cubicTo(
          cx - r, cy, cx - r * 0.9, cy - r * 1.3, cx, cy - r * 1.4);

    canvas.drawPath(
      leafPath,
      Paint()
        ..color = const Color(0xFF5AA84E).withOpacity(
            status == DetectionStatus.healthy ? 0.9 : 0.7)
        ..style = PaintingStyle.fill,
    );

    // vein
    canvas.drawLine(
      Offset(cx, cy - r * 1.2),
      Offset(cx, cy + r * 1.2),
      Paint()
        ..color = const Color(0xFF3A7030).withOpacity(0.4)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // disease spots
    if (status == DetectionStatus.diseased) {
      canvas.drawCircle(Offset(cx - 6, cy + 2), 4.5,
          Paint()..color = const Color(0xFFC8442A).withOpacity(0.7));
      canvas.drawCircle(Offset(cx + 7, cy - 5), 4,
          Paint()..color = const Color(0xFFC8442A).withOpacity(0.5));
    } else if (status == DetectionStatus.suspect) {
      canvas.drawCircle(Offset(cx, cy + 3), 4,
          Paint()..color = const Color(0xFFD4922A).withOpacity(0.6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
