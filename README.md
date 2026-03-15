# TomGuard AI 🍅
**Tomato Leaf Disease Classifier — Flutter Mobile App**

Aplikasi mobile untuk mendeteksi penyakit daun tomat menggunakan AI, dibangun dengan Flutter menggunakan gaya flat design minimalis.

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                        # Entry point + MainScaffold + BottomNavigationBar
├── theme/
│   └── app_theme.dart               # Warna, typography, ThemeData global
├── models/
│   └── detection_record.dart        # Model data + dummy history data
├── screens/
│   ├── home_screen.dart             # Halaman utama (kamera, galeri, realtime)
│   ├── live_detection_screen.dart   # Viewfinder + scanner box + hasil deteksi
│   ├── history_screen.dart          # ListView riwayat scan dengan filter
│   └── developer_info_screen.dart   # Info tim & performa model
└── widgets/
    ├── action_button.dart           # Tombol aksi berdesain flat (reusable)
    ├── stat_chip.dart               # Chip statistik di home screen
    ├── leaf_hero_painter.dart       # CustomPainter ilustrasi daun di hero
    ├── scanner_box.dart             # Viewfinder + corner brackets + scan line
    ├── history_list_item.dart       # Item riwayat dengan thumbnail daun
    ├── mini_bar_chart.dart          # Mini bar chart 7-hari di history
    └── developer_card.dart          # Kartu profil developer
```

---

## 🚀 Cara Menjalankan

```bash
# Clone / buka folder proyek
cd tomguard

# Install dependensi
flutter pub get

# Jalankan di emulator atau perangkat fisik
flutter run
```

---

## 📦 Integrasi Paket (Belum Aktif)

Placeholder sudah disiapkan di kode. Aktifkan dengan uncomment di `pubspec.yaml`:

### 1. Camera & Gallery — `image_picker`
```yaml
image_picker: ^1.0.7
```
Di `home_screen.dart`, uncomment blok `_pickFromCamera()` dan `_pickFromGallery()`:
```dart
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.camera);
```

### 2. Live Camera — `camera`
```yaml
camera: ^0.10.5+9
```
Di `live_detection_screen.dart`, uncomment `_initCamera()` dan ganti placeholder background dengan:
```dart
CameraPreview(_cameraController)
```

### 3. On-device Inference — `tflite_flutter`
```yaml
tflite_flutter: ^0.10.4
```
Tambahkan file model ke `assets/models/tomato_classifier.tflite` lalu panggil interpreter saat frame baru tersedia.

### 4. Penyimpanan Lokal — `hive_flutter`
```yaml
hive_flutter: ^1.1.0
```
Ganti `dummyHistory` di `detection_record.dart` dengan data dari Hive box.

---

## 🎨 Palet Warna

| Variabel              | Hex        | Digunakan untuk             |
|-----------------------|------------|-----------------------------|
| `primaryGreen`        | `#2D6B24`  | Tombol utama, teks aktif    |
| `lightGreen`          | `#4A8C3F`  | Icon, aksen                 |
| `accentGreen`         | `#EBF5E8`  | Background badge & tag sehat|
| `tomatoRed`           | `#C8442A`  | Tombol galeri, tag penyakit |
| `background`          | `#FAFAF8`  | Scaffold background         |
| `darkText`            | `#1C2B1A`  | Judul & teks utama          |

---

## 🌿 Fitur per Halaman

| Halaman              | Fitur Utama                                                    |
|----------------------|----------------------------------------------------------------|
| **Home**             | Badge, hero illustration, quick stats, 3 action buttons        |
| **Live Detection**   | Viewfinder dark, scanner box, scan line animation, hasil + confidence bar |
| **History**          | Summary card, filter chip (All/Healthy/Diseased/Suspect), `ListView.builder` |
| **Developer Info**   | Dark header band, developer cards dengan avatar + tag, tech stack pills, model perf |

---

## 📋 Dependencies yang Digunakan

| Paket              | Status      | Kegunaan                      |
|--------------------|-------------|-------------------------------|
| `flutter`          | ✅ Aktif    | Core framework                |
| `cupertino_icons`  | ✅ Aktif    | Icon tambahan                 |
| `image_picker`     | 💤 Placeholder | Kamera & galeri            |
| `camera`           | 💤 Placeholder | Live preview               |
| `tflite_flutter`   | 💤 Placeholder | Inferensi model            |
| `hive_flutter`     | 💤 Placeholder | Penyimpanan lokal          |
# leaf_tomato
# leaf_tomato
# leaf_tomato
