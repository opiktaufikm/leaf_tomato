// lib/services/detection_history_service.dart
// Service untuk menyimpan dan memuat riwayat deteksi

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/detection_record.dart';

class DetectionHistoryService {
  static const String _boxName = 'detection_history';
  static const String _recordsKey = 'records';

  Box<String>? _historyBox;
  bool _isInitialized = false;

  // Singleton pattern
  static final DetectionHistoryService _instance = DetectionHistoryService._internal();
  factory DetectionHistoryService() => _instance;
  DetectionHistoryService._internal();

  bool get isInitialized => _isInitialized;

  /// Inisialisasi Hive dan buka box untuk history
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inisialisasi Hive dengan direktori dokumen app
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);

      // Buka box untuk menyimpan history sebagai JSON strings
      _historyBox = await Hive.openBox<String>(_boxName);
      _isInitialized = true;
      debugPrint('[DetectionHistoryService] Inisialisasi selesai');
    } catch (e) {
      debugPrint('[DetectionHistoryService] ERROR saat inisialisasi: $e');
      throw Exception('Gagal menginisialisasi DetectionHistoryService: $e');
    }
  }

  /// Simpan deteksi baru ke history
  Future<void> saveDetection(DetectionRecord record) async {
    if (!_isInitialized) await initialize();

    try {
      // Ambil history yang sudah ada
      List<DetectionRecord> records = await getAllDetections();

      // Tambah record baru ke awal list
      records.insert(0, record);

      // Konversi ke JSON dan simpan
      final jsonList = records.map((r) => jsonEncode(r.toJson())).toList();
      await _historyBox?.put(_recordsKey, jsonEncode(jsonList));

      debugPrint('[DetectionHistoryService] Deteksi disimpan: ${record.diseaseName}');
    } catch (e) {
      debugPrint('[DetectionHistoryService] ERROR menyimpan deteksi: $e');
      throw Exception('Gagal menyimpan deteksi: $e');
    }
  }

  /// Ambil semua deteksi dari history
  Future<List<DetectionRecord>> getAllDetections() async {
    if (!_isInitialized) await initialize();

    try {
      final jsonString = _historyBox?.get(_recordsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => DetectionRecord.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('[DetectionHistoryService] ERROR mengambil deteksi: $e');
      return [];
    }
  }

  /// Hapus deteksi tertentu dari history
  Future<void> deleteDetection(String recordId) async {
    if (!_isInitialized) await initialize();

    try {
      List<DetectionRecord> records = await getAllDetections();
      records.removeWhere((r) => r.id == recordId);

      final jsonList = records.map((r) => jsonEncode(r.toJson())).toList();
      await _historyBox?.put(_recordsKey, jsonEncode(jsonList));

      debugPrint('[DetectionHistoryService] Deteksi dihapus: $recordId');
    } catch (e) {
      debugPrint('[DetectionHistoryService] ERROR menghapus deteksi: $e');
      throw Exception('Gagal menghapus deteksi: $e');
    }
  }

  /// Hapus semua history
  Future<void> clearAllDetections() async {
    if (!_isInitialized) await initialize();

    try {
      await _historyBox?.delete(_recordsKey);
      debugPrint('[DetectionHistoryService] Semua history dihapus');
    } catch (e) {
      debugPrint('[DetectionHistoryService] ERROR menghapus semua: $e');
      throw Exception('Gagal menghapus semua history: $e');
    }
  }

  /// Tutup Hive box
  Future<void> dispose() async {
    try {
      await _historyBox?.close();
      _isInitialized = false;
      debugPrint('[DetectionHistoryService] Ditutup');
    } catch (e) {
      debugPrint('[DetectionHistoryService] ERROR menutup: $e');
    }
  }
}
