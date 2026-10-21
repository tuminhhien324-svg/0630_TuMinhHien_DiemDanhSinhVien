import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/fast_translator.dart';

class RealtimeTranslateScreen extends StatefulWidget {
  const RealtimeTranslateScreen({super.key});

  @override
  State<RealtimeTranslateScreen> createState() => _RealtimeTranslateScreenState();
}

class _RealtimeTranslateScreenState extends State<RealtimeTranslateScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _autoScan = true;
  Timer? _autoScanTimer;

  String _liveRecognizedText = '';
  String _liveTranslatedText = '';
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Tìm camera sau
    final rearCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      rearCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() => _isCameraInitialized = true);

    // Bắt đầu chu kỳ quét tự động mỗi 1.8 giây (vừa mượt vừa không bị lag máy)
    _startAutoScan();
  }

  void _startAutoScan() {
    _autoScanTimer?.cancel();
    if (!_autoScan) return;

    _autoScanTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted && _autoScan && !_isProcessing && _isCameraInitialized) {
        _captureAndTranslate();
      }
    });
  }

  // Chụp nhanh khung hình và dịch tức thì (ML Kit OCR + FastTranslator)
  Future<void> _captureAndTranslate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final String scanned = recognizedText.text.trim();

      // Xóa file ảnh tạm để giải phóng bộ nhớ
      try {
        await File(photo.path).delete();
      } catch (_) {}

      if (scanned.isNotEmpty) {
        // Dịch siêu tốc bằng bộ nhớ đệm FastTranslator
        final translated = await FastTranslator.translate(scanned);

        if (mounted) {
          setState(() {
            _liveRecognizedText = scanned;
            _liveTranslatedText = translated;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dịch Camera Realtime Siêu Tốc ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          Row(
            children: [
              Text(
                _autoScan ? 'Tự động quét' : 'Quét thủ công',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Switch(
                value: _autoScan,
                activeColor: const Color(0xFFEC4899),
                onChanged: (val) {
                  setState(() => _autoScan = val);
                  if (val) {
                    _startAutoScan();
                  } else {
                    _autoScanTimer?.cancel();
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview Fullscreen
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFEC4899)),
                  SizedBox(height: 16),
                  Text('Đang mở Camera...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // Vùng quét khung ngắm Focus Box
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.center_focus_strong,
                            size: 14,
                            color: _isProcessing ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isProcessing ? 'ĐANG DỊCH...' : 'HƯỚNG CAMERA VÀO CHỮ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isProcessing ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay hiển thị kết quả dịch ở dưới
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KẾT QUẢ DỊCH TIẾNG VIỆT REALTIME',
                        style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      if (_isProcessing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _liveTranslatedText.isEmpty ? 'Đang chờ nhận diện văn bản...' : _liveTranslatedText,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_liveRecognizedText.isNotEmpty) ...[
                    const Divider(color: Colors.white24, height: 12),
                    Text(
                      'Gốc: ${_liveRecognizedText.replaceAll('\n', ' ')}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Nút bấm "QUÉT & DỊCH NGAY (0.3s)" ở góc dưới cùng
          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndTranslate,
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 20),
              label: const Text(
                '⚡ QUÉT & DỊCH NGAY TỨC THÌ (0.3s)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
