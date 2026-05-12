// ════════════════════════════════════════════════════════════════════════════
// lib/services/classifier_service.dart
//
// CARA PENGGUNAAN:
//   1. Latih model MobileNetV2 di Python/TensorFlow
//   2. Konversi ke .tflite: converter = tf.lite.TFLiteConverter.from_saved_model(...)
//   3. Letakkan file di: assets/models/model_daun_tomat_versi1.tflite
//   4. Pastikan assets/labels/labels.txt berisi kelas model (satu per baris)
//   5. Panggil ClassifierService.initialize() saat app startup
// ════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // ← FIX: diperlukan untuk debugPrint
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ── Model hasil prediksi ──────────────────────────────────────────────────────
class ClassificationResult {
  final String label;           // Nama penyakit
  final double confidence;      // 0.0 – 1.0
  final int classIndex;         // Index kelas di labels.txt
  final List<double> allScores; // Semua skor untuk visualisasi

  const ClassificationResult({
    required this.label,
    required this.confidence,
    required this.classIndex,
    required this.allScores,
  });

  /// Apakah daun sehat?
  bool get isHealthy {
    final normalized = label.toLowerCase();
    return normalized == 'healthy' || normalized == 'sehat';
  }

  /// Apakah ini daun tomat yang valid (bukan objek asing)?
  bool get isValidTomatoLeaf {
    final validLabels = {
      'healthy', 'sehat',
      'leaf spot', 'bercak daun',
      'leaf blight', 'busuk daun',
      'powdery mildew', 'jamur daun'
    };
    return validLabels.contains(label.toLowerCase()) && confidence >= 0.40;
  }

  /// Confidence dalam persen (misal: "94.7%")
  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// Status kepercayaan berdasarkan nilai confidence
  String get confidenceLabel {
    if (confidence >= 0.90) return 'Sangat Yakin';
    if (confidence >= 0.75) return 'Yakin';
    if (confidence >= 0.60) return 'Cukup Yakin';
    return 'Tidak Yakin';
  }
}

// ── Service klasifikasi utama ─────────────────────────────────────────────────
class ClassifierService {
  // ── Konfigurasi model ─────────────────────────────────────────────────────
  /// ⚠️ Sesuaikan path jika nama file berbeda
  static const String _modelPath = 'assets/models/model_daun_tomat.tflite';
  static const String _labelsPath = 'assets/labels/labels.txt';

  /// Ukuran input model MobileNetV2 (224x224 adalah standar)
  static const int _inputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Singleton pattern agar hanya ada 1 instance
  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  bool get isInitialized => _isInitialized;
  int get numClasses => _labels.length;
  List<String> get labels => List.unmodifiable(_labels);

  // ── Label kelas non-daun yang harus diabaikan ─────────────────────────────
  // Tambahkan nama kelas dari labels.txt yang merupakan latar belakang
  // atau objek asing (bukan penyakit/kondisi daun tomat).
  static const Set<String> _excludedLabels = {
    'kotak',
    'background',
    'latar belakang',
    'unknown',
    'tidak diketahui',
    'other',
    'lainnya',
  };

  /// Minimum confidence agar hasil dianggap valid.
  static const double _minConfidence = 0.60;

  /// Validasi hasil klasifikasi secara dinamis:
  ///   true  → label berasal dari kelas daun tomat & confidence cukup tinggi
  ///   false → label adalah kelas non-daun / background / confidence rendah
  ///
  /// Berbeda dengan [ClassificationResult.isValidTomatoLeaf] yang hardcoded,
  /// method ini memakai [_labels] dari labels.txt → otomatis sesuai model.
  bool isValidLeafResult(ClassificationResult result) {
    if (result.confidence < _minConfidence) return false;
    final lbl = result.label.toLowerCase().trim();
    if (_excludedLabels.contains(lbl)) return false;
    return _labels.any((l) => l.toLowerCase().trim() == lbl);
  }


  // ── Inisialisasi: muat model + label ─────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[ClassifierService] Memuat model dari: $_modelPath');
      final interpreterOptions = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: interpreterOptions,
      );
      debugPrint('[ClassifierService] Model berhasil dimuat');

      debugPrint('[ClassifierService] Memuat label dari: $_labelsPath');
      final labelData = await rootBundle.loadString(_labelsPath);
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      debugPrint('[ClassifierService] Label berhasil dimuat: $_labels');

      _isInitialized = true;
      debugPrint('[ClassifierService] Inisialisasi selesai');
    } catch (e) {
      debugPrint('[ClassifierService] ERROR saat inisialisasi: $e');
      // Lempar error agar app tidak lanjut tanpa model
      throw Exception('Gagal memuat model atau label: $e');
    }
  }

  // ── Klasifikasi gambar dari File ─────────────────────────────────────────
  Future<ClassificationResult> classifyImageFile(File imageFile) async {
    if (!_isInitialized) await initialize();

    // Decode gambar
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Gagal membaca gambar. Coba gunakan gambar lain.');
    }

    return _runInference(decodedImage);
  }

  // ── Klasifikasi gambar dari bytes (untuk live camera) ────────────────────
  Future<ClassificationResult> classifyImageBytes(Uint8List bytes) async {
    if (!_isInitialized) await initialize();

    // ── Deteksi format: YUV420 (dengan header) atau image (JPEG/PNG) ──────
    img.Image? image;

    if (bytes.length > 12) {
      try {
        // Try to decode as YUV420 format (custom)
        final header = bytes.buffer.asInt32List(0, 3);
        final width = header[0];
        final height = header[1];

        if (width > 0 && height > 0 && width < 4000 && height < 4000) {
          // YUV420 format detected
          final yPlaneSize = header[2];
          image = _decodeYUV420Direct(bytes, width, height, yPlaneSize);
        } else {
          // Fallback ke standard image decode
          image = img.decodeImage(bytes);
        }
      } catch (e) {
        // Fallback
        image = img.decodeImage(bytes);
      }
    } else {
      image = img.decodeImage(bytes);
    }

    if (image == null) {
      throw Exception('Gagal membaca frame kamera.');
    }

    return _runInference(image);
  }

  /// ── Decode YUV420 bytes langsung tanpa library ────────────────────────────
  img.Image _decodeYUV420Direct(
      Uint8List data, int width, int height, int ySize) {
    final image = img.Image(width: width, height: height);

    try {
      final yPlane = data.sublist(12, 12 + ySize);
      final uPlane = data.sublist(12 + ySize, 12 + ySize + (ySize ~/ 4));
      final vPlane = data.sublist(12 + ySize + (ySize ~/ 4));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * width + x;
          final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

          final yVal = yPlane[yIndex].toDouble();
          final uVal = uPlane[uvIndex].toDouble() - 128.0;
          final vVal = vPlane[uvIndex].toDouble() - 128.0;

          final r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
          final g = (yVal - 0.344136 * uVal - 0.714136 * vVal)
              .clamp(0, 255)
              .toInt();
          final b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    } catch (e) {
      debugPrint('⚠️  YUV420 decode failed: $e'); // ← sekarang bisa dikenali
      // Return dummy image jika decode gagal
      return image;
    }

    return image;
  }

  // ── Core inference pipeline ──────────────────────────────────────────────
  ClassificationResult _runInference(img.Image rawImage) {
    // STEP 1: Resize ke 224x224 (input MobileNetV2)
    final resized = img.copyResize(
      rawImage,
      width: _inputSize,
      height: _inputSize,
    );

    // STEP 2: Buat normalized input tensor dengan Float32List (efficient)
    // Reshape dari flat array ke [1, 224, 224, 3] tanpa allocation extra
    final inputTensor = List<List<List<List<double>>>>.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) {
          final row = <List<double>>[];
          for (int x = 0; x < _inputSize; x++) {
            final pixel = resized.getPixel(x, y);
            row.add([
              (pixel.r / 127.5) - 1.0, // R
              (pixel.g / 127.5) - 1.0, // G
              (pixel.b / 127.5) - 1.0, // B
            ]);
          }
          return row;
        },
      ),
    );

    // STEP 3: Siapkan output tensor
    final outputTensor = List.generate(
      1,
      (_) => List.filled(_labels.length, 0.0),
    );

    // STEP 4: Jalankan inferensi
    if (_interpreter != null) {
      _interpreter!.run(inputTensor, outputTensor);
    } else {
      throw Exception(
          'Model belum diinisialisasi. Pastikan initialize() dipanggil terlebih dahulu.');
    }

    // STEP 5: Post-processing
    final scores = outputTensor[0];
    final allScores = List<double>.from(scores);
    final softmaxScores = _softmax(allScores);
    final maxIndex = _argmax(softmaxScores);
    final maxScore = softmaxScores[maxIndex];

    return ClassificationResult(
      label: _labels[maxIndex],
      confidence: maxScore,
      classIndex: maxIndex,
      allScores: softmaxScores,
    );
  }

  // ── Helper: Softmax normalization ─────────────────────────────────────────
  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(max);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }

  // ── Helper: Argmax ────────────────────────────────────────────────────────
  int _argmax(List<double> values) {
    int maxIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }
    return maxIdx;
  }

  // ── Bersihkan resource ───────────────────────────────────────────────────
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

// ── Informasi penyakit berdasarkan kelas ─────────────────────────────────────
// ⚠️ Sesuaikan deskripsi ini dengan penyakit yang ada di dataset Anda
class DiseaseInfo {
  static Map<String, Info> get _data => {
        'Healthy': Info(
          indonesianName: 'Daun Sehat',
          scientificName: 'Solanum lycopersicum',
          severity: 'Tidak Ada',
          severityLevel: 0,
          description: 'Daun tomat dalam kondisi sehat. Tidak ditemukan '
              'tanda-tanda infeksi penyakit atau serangan hama pada sampel ini.',
          symptoms: [
            'Warna daun hijau merata',
            'Tidak ada bercak',
            'Bentuk normal'
          ],
          treatment: [
            'Pertahankan kondisi pertumbuhan optimal',
            'Siram secara teratur',
            'Beri pupuk sesuai jadwal'
          ],
          prevention: [
            'Rotasi tanaman tahunan',
            'Jaga kebersihan kebun',
            'Gunakan varietas tahan penyakit'
          ],
          spreadType: 'Tidak Menyebar',
          season: 'Sepanjang Tahun',
        ),
        'Sehat': Info(
          indonesianName: 'Daun Sehat',
          scientificName: 'Solanum lycopersicum',
          severity: 'Tidak Ada',
          severityLevel: 0,
          description: 'Daun tomat dalam kondisi sehat. Tidak ditemukan '
              'tanda-tanda infeksi penyakit atau serangan hama pada sampel ini.',
          symptoms: [
            'Warna daun hijau merata',
            'Tidak ada bercak',
            'Bentuk normal'
          ],
          treatment: [
            'Pertahankan kondisi pertumbuhan optimal',
            'Siram secara teratur',
            'Beri pupuk sesuai jadwal'
          ],
          prevention: [
            'Rotasi tanaman tahunan',
            'Jaga kebersihan kebun',
            'Gunakan varietas tahan penyakit'
          ],
          spreadType: 'Tidak Menyebar',
          season: 'Sepanjang Tahun',
        ),
        'Leaf Spot': Info(
          indonesianName: 'Bercak Daun',
          scientificName: 'Alternaria solani',
          severity: 'Sedang',
          severityLevel: 2,
          description:
              'Gejala ini terjadi pada tanaman tomat karena jamur atau bakteri '
              'menghisap nutrisi dan merusak jaringan di permukaan bawah daun. '
              'Tanda serangan adalah bercak cokelat kecil berbentuk cincin '
              'konsentris dengan halo kuning.',
          symptoms: [
            'Bercak coklat tua dengan pola cincin konsentris',
            'Tepi bercak berwarna kuning',
            'Daun bawah terserang lebih awal',
            'Daun menguning dan rontok',
          ],
          treatment: [
            'Aplikasikan fungisida berbahan aktif mancozeb atau klorotalonil',
            'Pangkas dan buang daun yang terinfeksi',
            'Semprot setiap 7-10 hari sekali saat cuaca lembab',
            'Gunakan fungisida sistemik jika serangan berat',
          ],
          prevention: [
            'Hindari penyiraman dari atas',
            'Jaga jarak tanam untuk sirkulasi udara',
            'Mulching untuk mencegah percikan tanah',
            'Benih yang sehat dan bersertifikat',
          ],
          spreadType: 'Melalui Air & Angin',
          season: 'Musim Hujan',
        ),
        'Bercak Daun': Info(
          indonesianName: 'Bercak Daun',
          scientificName: 'Alternaria solani',
          severity: 'Sedang',
          severityLevel: 2,
          description:
              'Gejala ini terjadi pada tanaman tomat karena jamur atau bakteri '
              'menghisap nutrisi dan merusak jaringan di permukaan bawah daun. '
              'Tanda serangan adalah bercak cokelat kecil berbentuk cincin '
              'konsentris dengan halo kuning.',
          symptoms: [
            'Bercak coklat tua dengan pola cincin konsentris',
            'Tepi bercak berwarna kuning',
            'Daun bawah terserang lebih awal',
            'Daun menguning dan rontok',
          ],
          treatment: [
            'Aplikasikan fungisida berbahan aktif mancozeb atau klorotalonil',
            'Pangkas dan buang daun yang terinfeksi',
            'Semprot setiap 7-10 hari sekali saat cuaca lembab',
            'Gunakan fungisida sistemik jika serangan berat',
          ],
          prevention: [
            'Hindari penyiraman dari atas',
            'Jaga jarak tanam untuk sirkulasi udara',
            'Mulching untuk mencegah percikan tanah',
            'Benih yang sehat dan bersertifikat',
          ],
          spreadType: 'Melalui Air & Angin',
          season: 'Musim Hujan',
        ),
        'Leaf Blight': Info(
          indonesianName: 'Busuk Daun',
          scientificName: 'Phytophthora infestans',
          severity: 'Tinggi',
          severityLevel: 3,
          description:
              'Gejala ini terjadi pada tanaman tomat karena jamur Phytophthora '
              'infestans merusak jaringan di permukaan bawah daun. Tanda serangan '
              'adalah bercak basah kehitaman dengan lapisan putih.',
          symptoms: [
            'Bercak besar coklat kehitaman tidak beraturan',
            'Permukaan daun bawah terdapat lapisan putih seperti kapas',
            'Daun mengering dan mati dengan cepat',
            'Menyebar ke batang dan buah',
          ],
          treatment: [
            'Gunakan fungisida berbahan tembaga (Copper hydroxide)',
            'Metalaxyl atau propamocarb untuk infeksi berat',
            'Cabut dan bakar tanaman yang sangat terinfeksi',
            'Hindari kelembaban berlebih di sekitar tanaman',
          ],
          prevention: [
            'Pilih varietas tahan blight',
            'Sanitasi lahan setelah panen',
            'Semprot preventif saat musim hujan',
            'Perbaiki drainase tanah',
          ],
          spreadType: 'Menyebar Cepat',
          season: 'Musim Dingin/Hujan',
        ),
        'Busuk Daun': Info(
          indonesianName: 'Busuk Daun',
          scientificName: 'Phytophthora infestans',
          severity: 'Tinggi',
          severityLevel: 3,
          description:
              'Gejala ini terjadi pada tanaman tomat karena jamur Phytophthora '
              'infestans merusak jaringan di permukaan bawah daun. Tanda serangan '
              'adalah bercak basah kehitaman dengan lapisan putih.',
          symptoms: [
            'Bercak besar coklat kehitaman tidak beraturan',
            'Permukaan daun bawah terdapat lapisan putih seperti kapas',
            'Daun mengering dan mati dengan cepat',
            'Menyebar ke batang dan buah',
          ],
          treatment: [
            'Gunakan fungisida berbahan tembaga (Copper hydroxide)',
            'Metalaxyl atau propamocarb untuk infeksi berat',
            'Cabut dan bakar tanaman yang sangat terinfeksi',
            'Hindari kelembaban berlebih di sekitar tanaman',
          ],
          prevention: [
            'Pilih varietas tahan blight',
            'Sanitasi lahan setelah panen',
            'Semprot preventif saat musim hujan',
            'Perbaiki drainase tanah',
          ],
          spreadType: 'Menyebar Cepat',
          season: 'Musim Dingin/Hujan',
        ),
        'Powdery Mildew': Info(
          indonesianName: 'Jamur Daun',
          scientificName: 'Oidium neolycopersici',
          severity: 'Ringan–Sedang',
          severityLevel: 1,
          description:
              'Gejala ini terjadi pada tanaman tomat karena jamur Oidium '
              'neolycopersici membentuk lapisan spora di permukaan atas daun. '
              'Tanda serangan adalah lapisan tepung putih keabu-abuan seperti bedak.',
          symptoms: [
            'Lapisan putih seperti tepung pada permukaan daun',
            'Bercak kuning tidak beraturan di atas daun',
            'Daun menggulung ke atas',
            'Pertumbuhan terhambat',
          ],
          treatment: [
            'Sulfur wettable powder atau fungisida berbahan sulfur',
            'Neem oil (minyak mimba) sebagai alternatif organik',
            'Bicarbonate of soda 0.5% sebagai kontrol ringan',
            'Kalium bikarbonat untuk serangan awal',
          ],
          prevention: [
            'Pastikan sirkulasi udara baik',
            'Hindari pemupukan nitrogen berlebihan',
            'Jaga kelembaban relatif di bawah 70%',
            'Pangkas daun tua di bagian bawah',
          ],
          spreadType: 'Melalui Angin',
          season: 'Musim Kering',
        ),
        'Jamur Daun': Info(
          indonesianName: 'Jamur Daun',
          scientificName: 'Oidium neolycopersici',
          severity: 'Ringan–Sedang',
          severityLevel: 1,
          description:
              'Gejala ini terjadi pada tanaman tomat karena jamur Oidium '
              'neolycopersici membentuk lapisan spora di permukaan atas daun. '
              'Tanda serangan adalah lapisan tepung putih keabu-abuan seperti bedak.',
          symptoms: [
            'Lapisan putih seperti tepung pada permukaan daun',
            'Bercak kuning tidak beraturan di atas daun',
            'Daun menggulung ke atas',
            'Pertumbuhan terhambat',
          ],
          treatment: [
            'Sulfur wettable powder atau fungisida berbahan sulfur',
            'Neem oil (minyak mimba) sebagai alternatif organik',
            'Bicarbonate of soda 0.5% sebagai kontrol ringan',
            'Kalium bikarbonat untuk serangan awal',
          ],
          prevention: [
            'Pastikan sirkulasi udara baik',
            'Hindari pemupukan nitrogen berlebihan',
            'Jaga kelembaban relatif di bawah 70%',
            'Pangkas daun tua di bagian bawah',
          ],
          spreadType: 'Melalui Angin',
          season: 'Musim Kering',
        ),
      };

  static Info getInfo(String label) {
    return _data[label] ??
        Info(
          indonesianName: label,
          scientificName: '',
          severity: 'Tidak Diketahui',
          severityLevel: 0,
          description: 'Informasi tidak tersedia.',
          symptoms: [],
          treatment: [],
          prevention: [],
          spreadType: '-',
          season: '-',
        );
  }

  static String indonesianName(String label) => getInfo(label).indonesianName;
  static String scientificName(String label) => getInfo(label).scientificName;
  static String severity(String label) => getInfo(label).severity;
  static int severityLevel(String label) => getInfo(label).severityLevel;
  static String description(String label) => getInfo(label).description;
  static List<String> symptoms(String label) => getInfo(label).symptoms;
  static List<String> treatment(String label) => getInfo(label).treatment;
  static List<String> prevention(String label) => getInfo(label).prevention;
  static String spreadType(String label) => getInfo(label).spreadType;
  static String season(String label) => getInfo(label).season;
}

class Info {
  final String indonesianName;
  final String scientificName;
  final String severity;
  final int severityLevel; // 0=none, 1=low, 2=medium, 3=high
  final String description;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;
  final String spreadType;
  final String season;

  const Info({
    required this.indonesianName,
    required this.scientificName,
    required this.severity,
    required this.severityLevel,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.spreadType,
    required this.season,
  });
}
