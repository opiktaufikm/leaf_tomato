import 'package:flutter/material.dart';

/// Tipe sumber gambar
enum ImageSourceType { camera, gallery }

/// Severity level hasil deteksi
enum SeverityLevel { none, low, moderate, high }

/// Model hasil analisis penyakit
class AnalysisResult {
  final String diseaseName;
  final String scientificName;
  final double confidence;
  final SeverityLevel severity;
  final String spreadRisk;
  final Color accentColor;
  final bool isHealthy;
  final String description;
  final List<String> treatments;
  final List<String> symptoms;
  final List<String> preventions;

  const AnalysisResult({
    required this.diseaseName,
    required this.scientificName,
    required this.confidence,
    required this.severity,
    required this.spreadRisk,
    required this.accentColor,
    required this.isHealthy,
    required this.description,
    required this.treatments,
    required this.symptoms,
    required this.preventions,
  });

  String get severityLabel {
    switch (severity) {
      case SeverityLevel.none:
        return 'Tidak Ada';
      case SeverityLevel.low:
        return 'Ringan';
      case SeverityLevel.moderate:
        return 'Sedang';
      case SeverityLevel.high:
        return 'Berat';
    }
  }

  Color get severityColor {
    switch (severity) {
      case SeverityLevel.none:
        return const Color(0xFF2D6B24);
      case SeverityLevel.low:
        return const Color(0xFF5A9E40);
      case SeverityLevel.moderate:
        return const Color(0xFFE8834A);
      case SeverityLevel.high:
        return const Color(0xFFC8442A);
    }
  }

  Color get primaryColor => accentColor;
  Color get lightColor => accentColor.withOpacity(0.2);
}

/// Dummy hasil deteksi — akan diganti inferensi model TFLite sungguhan
final List<AnalysisResult> dummyAnalysisResults = [
  AnalysisResult(
    diseaseName: 'Early Blight',
    scientificName: 'Alternaria solani',
    confidence: 87.3,
    severity: SeverityLevel.moderate,
    spreadRisk: 'Sedang',
    accentColor: const Color(0xFFE8834A),
    isHealthy: false,
    description:
        'Early Blight adalah penyakit jamur yang umum pada tanaman tomat. '
        'Ditandai dengan bercak coklat tua berbentuk cincin konsentris pada daun tua.',
    symptoms: [
      'Bercak coklat tua berbentuk cincin konsentris',
      'Daun tua menguning dan layu',
      'Bercak dapat muncul pada batang dan buah',
    ],
    treatments: [
      'Semprot fungisida berbahan aktif chlorothalonil atau mancozeb',
      'Buang dan musnahkan daun yang terinfeksi',
      'Hindari penyiraman dari atas (gunakan drip irrigation)',
      'Pastikan sirkulasi udara yang baik antar tanaman',
      'Rotasi tanaman setiap musim tanam',
    ],
    preventions: [
      'Rotasi tanaman dengan tanaman non-Solanaceae',
      'Gunakan benih yang sehat dan tahan penyakit',
      'Jaga kebersihan kebun dari gulma',
      'Hindari penyiraman berlebihan',
      'Pastikan drainase yang baik',
    ],
  ),
  AnalysisResult(
    diseaseName: 'Late Blight',
    scientificName: 'Phytophthora infestans',
    confidence: 73.5,
    severity: SeverityLevel.high,
    spreadRisk: 'Tinggi',
    accentColor: const Color(0xFFC8442A),
    isHealthy: false,
    description:
        'Late Blight adalah penyakit serius yang disebabkan oleh jamur air. '
        'Dapat menyebar sangat cepat terutama dalam kondisi lembab dan dingin.',
    symptoms: [
      'Bercak basah berwarna hijau keabu-abuan pada daun',
      'Lapisan putih seperti kapas di bawah daun',
      'Daun layu dan mati dalam beberapa hari',
      'Bercak coklat pada batang dan buah',
    ],
    treatments: [
      'Aplikasikan fungisida sistemik segera setelah gejala muncul',
      'Kurangi kelembaban dengan perbaikan drainase',
      'Buang seluruh bagian tanaman yang terinfeksi',
      'Gunakan varietas tomat tahan Late Blight',
      'Hindari menyiram pada sore/malam hari',
    ],
    preventions: [
      'Gunakan varietas tahan penyakit',
      'Jaga jarak tanam yang cukup untuk sirkulasi udara',
      'Hindari penyiraman berlebihan',
      'Monitor cuaca dan aplikasikan fungisida preventif',
      'Rotasi tanaman dengan tanaman non-host',
    ],
  ),
  AnalysisResult(
    diseaseName: 'Daun Sehat',
    scientificName: 'Solanum lycopersicum',
    confidence: 96.8,
    severity: SeverityLevel.none,
    spreadRisk: 'Tidak ada',
    accentColor: const Color(0xFF2D6B24),
    isHealthy: true,
    description:
        'Daun tomat dalam kondisi sehat. Tidak ditemukan tanda-tanda infeksi '
        'penyakit atau serangan hama pada sampel gambar ini.',
    symptoms: [],
    treatments: [
      'Lanjutkan perawatan rutin yang sudah dilakukan',
      'Pantau secara berkala setiap 3–5 hari',
      'Pastikan nutrisi NPK tercukupi',
      'Jaga kebersihan lahan dari gulma',
    ],
    preventions: [
      'Lanjutkan perawatan rutin yang sudah dilakukan',
      'Pantau secara berkala setiap 3–5 hari',
      'Pastikan nutrisi NPK tercukupi',
      'Jaga kebersihan lahan dari gulma',
    ],
  ),
  AnalysisResult(
    diseaseName: 'Septoria Leaf Spot',
    scientificName: 'Septoria lycopersici',
    confidence: 91.2,
    severity: SeverityLevel.moderate,
    spreadRisk: 'Sedang',
    accentColor: const Color(0xFFB57210),
    isHealthy: false,
    description:
        'Septoria Leaf Spot ditandai dengan bercak kecil melingkar berwarna putih '
        'kecoklatan dengan tepian gelap. Biasanya dimulai dari daun bagian bawah.',
    symptoms: [
      'Bercak kecil melingkar berwarna putih kecoklatan',
      'Tepian bercak gelap',
      'Bercak muncul pertama pada daun bawah',
      'Daun menguning dan rontok',
    ],
    treatments: [
      'Semprot fungisida berbahan copper-based',
      'Buang daun yang terinfeksi dan bakar',
      'Mulsa tanah untuk mencegah percikan air tanah',
      'Sterilkan peralatan berkebun secara rutin',
    ],
    preventions: [
      'Jaga jarak tanam yang cukup',
      'Hindari penyiraman dari atas',
      'Gunakan mulsa untuk mencegah percikan tanah',
      'Rotasi tanaman dengan tanaman non-host',
      'Gunakan varietas tahan penyakit',
    ],
  ),
];

/// Ambil hasil acak untuk simulasi analisis
AnalysisResult getRandomAnalysisResult() {
  final copy = List<AnalysisResult>.from(dummyAnalysisResults);
  copy.shuffle();
  return copy.first;
}
