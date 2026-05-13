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

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // ← FIX: diperlukan untuk debugPrint
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

const Set<String> _validTomatoLeafLabels = {
  'healthy',
  'sehat',
  'leaf spot',
  'bercak daun',
  'leaf blight',
  'busuk daun',
  'powdery mildew',
  'jamur daun',
};

// ── Model hasil prediksi ──────────────────────────────────────────────────────
class ClassificationResult {
  final String label; // Nama penyakit
  final double confidence; // 0.0 – 1.0
  final int classIndex; // Index kelas di labels.txt
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
    return _validTomatoLeafLabels.contains(label.toLowerCase().trim()) &&
        confidence >= 0.40;
  }

  /// Confidence dalam persen (misal: "94.7%")
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

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
  IsolateInterpreter? _isolateInterpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isRunningInference = false;

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

  /// Minimum confidence realtime agar objek asing tidak mudah masuk 4 kelas.
  static const double _minConfidence = 0.55;

  /// Validasi hasil klasifikasi realtime:
  ///   true  → label berasal dari 4 kelas daun tomat & confidence cukup tinggi
  ///   false → label adalah kelas non-daun / background / confidence rendah
  bool isValidLeafResult(ClassificationResult result) {
    if (result.confidence < _minConfidence) return false;
    final lbl = result.label.toLowerCase().trim();
    if (_excludedLabels.contains(lbl)) return false;
    return _validTomatoLeafLabels.contains(lbl);
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

      try {
        _isolateInterpreter = await IsolateInterpreter.create(
          address: _interpreter!.address,
        );
        debugPrint('[ClassifierService] Isolate inferensi berhasil dibuat');
      } catch (e) {
        debugPrint('[ClassifierService] Isolate inferensi tidak tersedia: $e');
      }

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

  // ── Klasifikasi frame kamera live tanpa encode/decode ulang ──────────────
  Future<ClassificationResult> classifyCameraImage(CameraImage frame) async {
    if (!_isInitialized) await initialize();
    if (frame.format.group != ImageFormatGroup.yuv420 ||
        frame.planes.length < 3) {
      throw Exception('Format frame kamera tidak didukung.');
    }

    final inputBytes = _cameraYuv420ToInputBytes(frame);
    return _runInputBytes(inputBytes);
  }

  /// ── Decode YUV420 bytes langsung tanpa library (OPTIMIZED) ──────────────────
  /// Menggunakan batch conversion daripada pixel-by-pixel untuk performa lebih baik
  img.Image _decodeYUV420Direct(
      Uint8List data, int width, int height, int ySize) {
    final image = img.Image(width: width, height: height);

    try {
      final yPlane = data.sublist(12, 12 + ySize);
      final uvSize = ySize ~/ 4;
      final uPlane = data.sublist(12 + ySize, 12 + ySize + uvSize);
      final vPlane = data.sublist(12 + ySize + uvSize);

      final int halfWidth = width ~/ 2;

      // ── Optimized: Batch processing dengan caching constants ──────────
      for (int y = 0; y < height; y++) {
        final yRowOffset = y * width;
        final uvRowOffset = (y ~/ 2) * halfWidth;

        for (int x = 0; x < width; x++) {
          final yIndex = yRowOffset + x;
          final uvIndex = uvRowOffset + (x ~/ 2);

          // Cached lookups
          final yVal = yPlane[yIndex].toDouble();
          final uVal = uPlane[uvIndex].toDouble() - 128.0;
          final vVal = vPlane[uvIndex].toDouble() - 128.0;

          // YUV to RGB conversion
          final r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
          final g =
              (yVal - 0.344136 * uVal - 0.714136 * vVal).clamp(0, 255).toInt();
          final b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    } catch (e) {
      debugPrint('⚠️  YUV420 decode failed: $e');
      return image;
    }

    return image;
  }

  Uint8List _cameraYuv420ToInputBytes(CameraImage frame) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw Exception('Model belum diinisialisasi.');
    }

    final inputType = interpreter.getInputTensor(0).type;
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    if (inputType == TensorType.uint8) {
      final input = Uint8List(_inputSize * _inputSize * 3);
      var offset = 0;
      for (int y = 0; y < _inputSize; y++) {
        final sourceY = y * frame.height ~/ _inputSize;
        final yRow = sourceY * yRowStride;
        final uvRow = (sourceY >> 1) * uvRowStride;
        for (int x = 0; x < _inputSize; x++) {
          final sourceX = x * frame.width ~/ _inputSize;
          final yIndex = yRow + sourceX * yPixelStride;
          final uvIndex = uvRow + (sourceX >> 1) * uvPixelStride;
          final rgb = _yuvToRgb(
            yBytes[_safeIndex(yIndex, yBytes.length)],
            uBytes[_safeIndex(uvIndex, uBytes.length)],
            vBytes[_safeIndex(uvIndex, vBytes.length)],
          );
          input[offset++] = (rgb >> 16) & 0xFF;
          input[offset++] = (rgb >> 8) & 0xFF;
          input[offset++] = rgb & 0xFF;
        }
      }
      return input;
    }

    if (inputType != TensorType.float32) {
      throw UnsupportedError('Tipe input model $inputType belum didukung.');
    }

    final input = Float32List(_inputSize * _inputSize * 3);
    var offset = 0;
    for (int y = 0; y < _inputSize; y++) {
      final sourceY = y * frame.height ~/ _inputSize;
      final yRow = sourceY * yRowStride;
      final uvRow = (sourceY >> 1) * uvRowStride;
      for (int x = 0; x < _inputSize; x++) {
        final sourceX = x * frame.width ~/ _inputSize;
        final yIndex = yRow + sourceX * yPixelStride;
        final uvIndex = uvRow + (sourceX >> 1) * uvPixelStride;
        final rgb = _yuvToRgb(
          yBytes[_safeIndex(yIndex, yBytes.length)],
          uBytes[_safeIndex(uvIndex, uBytes.length)],
          vBytes[_safeIndex(uvIndex, vBytes.length)],
        );
        input[offset++] = (((rgb >> 16) & 0xFF) / 127.5) - 1.0;
        input[offset++] = (((rgb >> 8) & 0xFF) / 127.5) - 1.0;
        input[offset++] = ((rgb & 0xFF) / 127.5) - 1.0;
      }
    }
    return input.buffer.asUint8List();
  }

  Uint8List _imageToInputBytes(img.Image rawImage) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw Exception('Model belum diinisialisasi.');
    }

    final resized = img.copyResize(
      rawImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );
    final inputType = interpreter.getInputTensor(0).type;

    if (inputType == TensorType.uint8) {
      final input = Uint8List(_inputSize * _inputSize * 3);
      var offset = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          input[offset++] = pixel.r.toInt();
          input[offset++] = pixel.g.toInt();
          input[offset++] = pixel.b.toInt();
        }
      }
      return input;
    }

    if (inputType != TensorType.float32) {
      throw UnsupportedError('Tipe input model $inputType belum didukung.');
    }

    final input = Float32List(_inputSize * _inputSize * 3);
    var offset = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[offset++] = (pixel.r / 127.5) - 1.0;
        input[offset++] = (pixel.g / 127.5) - 1.0;
        input[offset++] = (pixel.b / 127.5) - 1.0;
      }
    }
    return input.buffer.asUint8List();
  }

  // ── Core inference pipeline ──────────────────────────────────────────────
  Future<ClassificationResult> _runInference(img.Image rawImage) {
    return _runInputBytes(_imageToInputBytes(rawImage));
  }

  Future<ClassificationResult> _runInputBytes(Uint8List inputBytes) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw Exception(
          'Model belum diinisialisasi. Pastikan initialize() dipanggil terlebih dahulu.');
    }

    while (_isRunningInference) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    _isRunningInference = true;
    try {
      final outputTensor = interpreter.getOutputTensor(0);
      final outputBytes = Uint8List(outputTensor.numBytes());
      final isolate = _isolateInterpreter;
      if (isolate != null) {
        await isolate.run(inputBytes, outputBytes);
      } else {
        interpreter.run(inputBytes, outputBytes);
      }

      return _classificationFromScores(
        _readOutputScores(outputBytes, outputTensor),
      );
    } finally {
      _isRunningInference = false;
    }
  }

  List<double> _readOutputScores(Uint8List outputBytes, Tensor outputTensor) {
    final count = outputTensor.numElements();
    if (outputTensor.type == TensorType.float32) {
      final data = ByteData.sublistView(outputBytes);
      return List<double>.generate(
        count,
        (i) => data.getFloat32(i * 4, Endian.little),
        growable: false,
      );
    }

    if (outputTensor.type == TensorType.uint8) {
      final params = outputTensor.params;
      return List<double>.generate(
        count,
        (i) => (outputBytes[i] - params.zeroPoint) * params.scale,
        growable: false,
      );
    }

    if (outputTensor.type == TensorType.int8) {
      final params = outputTensor.params;
      final data = ByteData.sublistView(outputBytes);
      return List<double>.generate(
        count,
        (i) => (data.getInt8(i) - params.zeroPoint) * params.scale,
        growable: false,
      );
    }

    throw UnsupportedError(
        'Tipe output model ${outputTensor.type} belum didukung.');
  }

  ClassificationResult _classificationFromScores(List<double> scores) {
    final usableCount = min(scores.length, _labels.length);
    if (usableCount == 0) {
      throw Exception('Model tidak menghasilkan skor klasifikasi.');
    }

    final normalizedScores = _normalizeScores(scores.take(usableCount));
    final maxIndex = _argmax(normalizedScores);
    return ClassificationResult(
      label: _labels[maxIndex],
      confidence: normalizedScores[maxIndex],
      classIndex: maxIndex,
      allScores: normalizedScores,
    );
  }

  int _yuvToRgb(int y, int u, int v) {
    final c = y - 16;
    final d = u - 128;
    final e = v - 128;
    final r = _clampByte((298 * c + 409 * e + 128) >> 8);
    final g = _clampByte((298 * c - 100 * d - 208 * e + 128) >> 8);
    final b = _clampByte((298 * c + 516 * d + 128) >> 8);
    return (r << 16) | (g << 8) | b;
  }

  int _safeIndex(int index, int length) {
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }

  int _clampByte(int value) {
    if (value < 0) return 0;
    if (value > 255) return 255;
    return value;
  }

  // ── Helper: Softmax normalization ─────────────────────────────────────────
  List<double> _normalizeScores(Iterable<double> rawScores) {
    final scores = List<double>.from(rawScores);
    final sum = scores.fold<double>(0, (total, value) => total + value);
    final alreadyProbabilities =
        scores.every((value) => value >= 0 && value <= 1) &&
            sum > 0.98 &&
            sum < 1.02;

    return alreadyProbabilities ? scores : _softmax(scores);
  }

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
    final isolate = _isolateInterpreter;
    if (isolate != null) {
      unawaited(isolate.close());
    }
    _isolateInterpreter = null;
    _interpreter?.close();
    _interpreter = null;
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
