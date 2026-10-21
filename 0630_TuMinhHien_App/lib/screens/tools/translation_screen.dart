import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../services/fast_translator.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Translation State
  final TextEditingController _textInputController = TextEditingController();
  String _translatedResult = '';
  bool _isTranslating = false;
  Timer? _debounceTimer;
  TranslateLanguage _sourceLang = TranslateLanguage.english;
  TranslateLanguage _targetLang = TranslateLanguage.vietnamese;

  // Speech to Text Translation State (9đ)
  late stt.SpeechToText _speech;
  bool _isVoiceRecording = false;
  String _voiceSpokenText = '';

  // Image OCR Translation State (10đ)
  File? _selectedImage;
  String _ocrRecognizedText = '';
  String _ocrTranslatedText = '';
  bool _isOcrProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final List<Map<String, dynamic>> _languages = [
    {'name': 'Tiếng Việt', 'lang': TranslateLanguage.vietnamese, 'code': 'vi'},
    {'name': 'Tiếng Anh', 'lang': TranslateLanguage.english, 'code': 'en'},
    {'name': 'Tiếng Nhật', 'lang': TranslateLanguage.japanese, 'code': 'ja'},
    {'name': 'Tiếng Hàn', 'lang': TranslateLanguage.korean, 'code': 'ko'},
    {'name': 'Tiếng Pháp', 'lang': TranslateLanguage.french, 'code': 'fr'},
    {'name': 'Tiếng Đức', 'lang': TranslateLanguage.german, 'code': 'de'},
    {'name': 'Tiếng Trung', 'lang': TranslateLanguage.chinese, 'code': 'zh'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _speech = stt.SpeechToText();

    // Khởi tạo trước model ngôn ngữ trong bộ nhớ để dịch tức thì
    FastTranslator.preheat(_sourceLang, _targetLang);

    // Lắng nghe khi người dùng gõ chữ để dịch realtime (debounce 300ms)
    _textInputController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    final text = _textInputController.text.trim();
    if (text.isEmpty) {
      setState(() => _translatedResult = '');
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performTextTranslation();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _textInputController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _performTextTranslation() async {
    final text = _textInputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTranslating = true);
    final res = await FastTranslator.translate(
      text,
      source: _sourceLang,
      target: _targetLang,
    );

    if (mounted) {
      setState(() {
        _translatedResult = res;
        _isTranslating = false;
      });
    }
  }

  // Voice Translation (Dịch giọng nói theo thời gian thực)
  Future<void> _listenVoiceAndTranslate() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) return;

    if (!_isVoiceRecording) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isVoiceRecording = true);
        _speech.listen(
          localeId: 'en_US',
          onResult: (result) async {
            setState(() {
              _voiceSpokenText = result.recognizedWords;
            });

            // Dịch ngay khi nhận diện được từ
            if (_voiceSpokenText.isNotEmpty) {
              final translated = await FastTranslator.translate(
                _voiceSpokenText,
                source: TranslateLanguage.english,
                target: TranslateLanguage.vietnamese,
              );
              if (mounted) {
                setState(() => _translatedResult = translated);
              }
            }

            if (result.finalResult) {
              setState(() => _isVoiceRecording = false);
            }
          },
        );
      }
    } else {
      setState(() => _isVoiceRecording = false);
      _speech.stop();
    }
  }

  // Image OCR & Fast Translation (10đ)
  Future<void> _pickImageAndRecognize(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _isOcrProcessing = true;
        _ocrRecognizedText = 'Đang quét văn bản (Google ML Kit)...';
        _ocrTranslatedText = '';
      });

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final String scanned = recognizedText.text.trim();

      if (scanned.isEmpty) {
        setState(() {
          _ocrRecognizedText = 'Không tìm thấy chữ trong hình ảnh này.';
          _isOcrProcessing = false;
        });
        return;
      }

      // Dịch siêu tốc bằng FastTranslator
      final translated = await FastTranslator.translate(
        scanned,
        source: TranslateLanguage.english,
        target: TranslateLanguage.vietnamese,
      );

      if (mounted) {
        setState(() {
          _ocrRecognizedText = scanned;
          _ocrTranslatedText = translated;
          _isOcrProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ocrRecognizedText = 'Lỗi xử lý OCR: $e';
          _isOcrProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Dịch thuật Google ML Kit', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFEC4899),
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.text_fields), text: 'Dịch Text (7đ)'),
            Tab(icon: Icon(Icons.mic), text: 'Giọng nói (9đ)'),
            Tab(icon: Icon(Icons.image_search), text: 'Ảnh OCR (10đ)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextTranslateTab(),
          _buildVoiceTranslateTab(),
          _buildImageOcrTranslateTab(),
        ],
      ),
    );
  }

  // 1. Text Translation Tab (7đ)
  Widget _buildTextTranslateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLanguageSelectorRow(),
          const SizedBox(height: 16),
          TextField(
            controller: _textInputController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập văn bản tiếng Anh (Gõ là dịch tự động)...',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isTranslating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEC4899)),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isTranslating ? null : _performTextTranslation,
            icon: const Icon(Icons.flash_on, color: Colors.white),
            label: const Text(
              'DỊCH SIÊU TỐC',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          _buildResultCard('BẢN DỊCH TIẾNG VIỆT', _translatedResult),
        ],
      ),
    );
  }

  // 2. Voice Translation Tab (9đ)
  Widget _buildVoiceTranslateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                Icon(
                  _isVoiceRecording ? Icons.mic : Icons.mic_none,
                  size: 64,
                  color: _isVoiceRecording ? Colors.redAccent : const Color(0xFF818CF8),
                ),
                const SizedBox(height: 12),
                Text(
                  _isVoiceRecording ? 'Đang lắng nghe... Nói bằng tiếng Anh' : 'Bấm nút micro để nói bài giảng',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _voiceSpokenText.isEmpty ? 'Ví dụ: "Welcome to mobile programming lecture"' : '"$_voiceSpokenText"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _listenVoiceAndTranslate,
                  icon: Icon(_isVoiceRecording ? Icons.stop : Icons.mic, color: Colors.white),
                  label: Text(
                    _isVoiceRecording ? 'DỪNG THU ÂM' : 'BẮT ĐẦU NÓI (9đ)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVoiceRecording ? Colors.redAccent : const Color(0xFF6366F1),
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildResultCard('BẢN DỊCH TỨC THÌ (TIẾNG VIỆT)', _translatedResult)),
        ],
      ),
    );
  }

  // 3. Image OCR Tab (10đ)
  Widget _buildImageOcrTranslateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImageAndRecognize(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('Chụp ảnh Slide', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImageAndRecognize(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  label: const Text('Chọn từ Gallery', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          if (_isOcrProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFFEC4899)),
            ),
          _buildResultCard('VĂN BẢN QUÉT TỪ ẢNH (OCR)', _ocrRecognizedText),
          const SizedBox(height: 16),
          _buildResultCard('BẢN DỊCH TIẾNG VIỆT (10đ)', _ocrTranslatedText, isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<TranslateLanguage>(
            value: _sourceLang,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            items: _languages.map((l) => DropdownMenuItem<TranslateLanguage>(value: l['lang'], child: Text(l['name']))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _sourceLang = val);
                FastTranslator.preheat(_sourceLang, _targetLang);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Color(0xFFEC4899)),
            onPressed: () {
              setState(() {
                final temp = _sourceLang;
                _sourceLang = _targetLang;
                _targetLang = temp;
              });
              FastTranslator.preheat(_sourceLang, _targetLang);
              _performTextTranslation();
            },
          ),
          DropdownButton<TranslateLanguage>(
            value: _targetLang,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            items: _languages.map((l) => DropdownMenuItem<TranslateLanguage>(value: l['lang'], child: Text(l['name']))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _targetLang = val);
                FastTranslator.preheat(_sourceLang, _targetLang);
                _performTextTranslation();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String content, {bool isHighlight = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF334155),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.isEmpty ? 'Kết quả sẽ hiển thị ở đây...' : content,
            style: TextStyle(
              fontSize: 15,
              color: content.isEmpty ? const Color(0xFF64748B) : Colors.white,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
