import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class FastTranslator {
  // Bộ nhớ đệm lưu các instance Translator đang mở để dùng lại tức thì (không tốn thời gian load model)
  static final Map<String, OnDeviceTranslator> _translators = {};

  // Cache kết quả dịch để trả về trong 0ms nếu trùng câu
  static final Map<String, String> _resultCache = {};

  static Future<void> preheat(TranslateLanguage src, TranslateLanguage tgt) async {
    final key = '${src.bcpCode}_${tgt.bcpCode}';
    if (!_translators.containsKey(key)) {
      _translators[key] = OnDeviceTranslator(sourceLanguage: src, targetLanguage: tgt);
    }
  }

  static Future<String> translate(
    String text, {
    TranslateLanguage source = TranslateLanguage.english,
    TranslateLanguage target = TranslateLanguage.vietnamese,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    final cacheKey = '${source.bcpCode}_${target.bcpCode}_$trimmed';
    if (_resultCache.containsKey(cacheKey)) {
      return _resultCache[cacheKey]!;
    }

    final key = '${source.bcpCode}_${target.bcpCode}';
    if (!_translators.containsKey(key)) {
      _translators[key] = OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
    }

    try {
      final translator = _translators[key]!;
      final result = await translator.translateText(trimmed);
      _resultCache[cacheKey] = result;
      return result;
    } catch (e) {
      return 'Lỗi dịch ML Kit: $e';
    }
  }

  static void clear() {
    for (final t in _translators.values) {
      t.close();
    }
    _translators.clear();
    _resultCache.clear();
  }
}
