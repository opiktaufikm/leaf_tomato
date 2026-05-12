enum DetectionStatus { healthy, diseased, suspect }

class DetectionRecord {
  final String id;
  final String leafLabel;
  final String diseaseName;
  final String scientificName;
  final DateTime scannedAt;
  final DetectionStatus status;
  final double confidence;
  final String imagePlaceholderColor; // hex for placeholder
  final String? imagePath; // path ke file gambar yang diklasifikasi

  const DetectionRecord({
    required this.id,
    required this.leafLabel,
    required this.diseaseName,
    required this.scientificName,
    required this.scannedAt,
    required this.status,
    required this.confidence,
    required this.imagePlaceholderColor,
    this.imagePath,
  });

  String get statusLabel {
    switch (status) {
      case DetectionStatus.healthy:
        return 'Sehat';
      case DetectionStatus.diseased:
        return 'Penyakit';
      case DetectionStatus.suspect:
        return 'Suspek';
    }
  }

  /// Konversi DetectionRecord ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leafLabel': leafLabel,
      'diseaseName': diseaseName,
      'scientificName': scientificName,
      'scannedAt': scannedAt.toIso8601String(),
      'status': status.name,
      'confidence': confidence,
      'imagePlaceholderColor': imagePlaceholderColor,
      'imagePath': imagePath,
    };
  }

  /// Buat DetectionRecord dari JSON
  factory DetectionRecord.fromJson(Map<String, dynamic> json) {
    return DetectionRecord(
      id: json['id'] as String? ?? '',
      leafLabel: json['leafLabel'] as String? ?? '',
      diseaseName: json['diseaseName'] as String? ?? '',
      scientificName: json['scientificName'] as String? ?? '',
      scannedAt: DateTime.tryParse(json['scannedAt'] as String? ?? '') ?? DateTime.now(),
      status: _statusFromString(json['status'] as String? ?? 'suspect'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePlaceholderColor: json['imagePlaceholderColor'] as String? ?? 'FFFFFF',
      imagePath: json['imagePath'] as String?,
    );
  }

  /// Helper untuk konversi string ke DetectionStatus
  static DetectionStatus _statusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'healthy':
        return DetectionStatus.healthy;
      case 'diseased':
        return DetectionStatus.diseased;
      case 'suspect':
      default:
        return DetectionStatus.suspect;
    }
  }
}

// Dummy data for history screen
final List<DetectionRecord> dummyHistory = [
  DetectionRecord(
    id: '128',
    leafLabel: 'Leaf Sample #128',
    diseaseName: 'Sehat',
    scientificName: 'No disease detected',
    scannedAt: DateTime.now().subtract(const Duration(minutes: 3)),
    status: DetectionStatus.healthy,
    confidence: 97.2,
    imagePlaceholderColor: 'EBF5E8',
  ),
  DetectionRecord(
    id: '127',
    leafLabel: 'Early Blight #127',
    diseaseName: 'Early Blight',
    scientificName: 'Alternaria solani',
    scannedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 29)),
    status: DetectionStatus.diseased,
    confidence: 87.0,
    imagePlaceholderColor: 'FEF3F1',
  ),
  DetectionRecord(
    id: '126',
    leafLabel: 'Late Blight #126',
    diseaseName: 'Late Blight',
    scientificName: 'Phytophthora infestans',
    scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 46)),
    status: DetectionStatus.suspect,
    confidence: 73.5,
    imagePlaceholderColor: 'FEF8EE',
  ),
  DetectionRecord(
    id: '125',
    leafLabel: 'Leaf Sample #125',
    diseaseName: 'Sehat',
    scientificName: 'No disease detected',
    scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 6, minutes: 21)),
    status: DetectionStatus.healthy,
    confidence: 95.8,
    imagePlaceholderColor: 'EBF5E8',
  ),
  DetectionRecord(
    id: '124',
    leafLabel: 'Septoria #124',
    diseaseName: 'Septoria Leaf Spot',
    scientificName: 'Septoria lycopersici',
    scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 23, minutes: 36)),
    status: DetectionStatus.diseased,
    confidence: 91.3,
    imagePlaceholderColor: 'FEF3F1',
  ),
  DetectionRecord(
    id: '123',
    leafLabel: 'Leaf Sample #123',
    diseaseName: 'Sehat',
    scientificName: 'No disease detected',
    scannedAt: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
    status: DetectionStatus.healthy,
    confidence: 99.1,
    imagePlaceholderColor: 'EBF5E8',
  ),
  DetectionRecord(
    id: '122',
    leafLabel: 'Mosaic Virus #122',
    diseaseName: 'Tomato Mosaic Virus',
    scientificName: 'ToMV',
    scannedAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
    status: DetectionStatus.diseased,
    confidence: 84.7,
    imagePlaceholderColor: 'FEF3F1',
  ),
  DetectionRecord(
    id: '121',
    leafLabel: 'Yellow Curl #121',
    diseaseName: 'Yellow Leaf Curl',
    scientificName: 'TYLCV',
    scannedAt: DateTime.now().subtract(const Duration(days: 4)),
    status: DetectionStatus.suspect,
    confidence: 68.2,
    imagePlaceholderColor: 'FEF8EE',
  ),
];
