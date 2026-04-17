import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('languageCode') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', langCode);
      notifyListeners();
    }
  }

  String getText(String key) {
    return _dictionary[_currentLanguage]?[key] ?? _dictionary['en']?[key] ?? key;
  }

  // Simplified basic dictionary
  static const Map<String, Map<String, String>> _dictionary = {
    'en': {
      'app_title': 'Oi QR Scanner',
      'tab_scan': 'Scan',
      'tab_generate': 'Generate',
      'tab_history': 'History',
      'tab_settings': 'Settings',
      'scan_qr': 'Scan QR',
      'generate_qr': 'Generate QR',
      'history': 'History',
      'settings': 'Settings',
      'no_history': 'No matching scans',
      'scan_now': 'Scan Now',
      'exporting': 'Exporting...',
      'language': 'Language',
      'english': 'English',
      'bengali': 'Bengali',
      'help_guide': 'Feature Guide',
    },
    'bn': {
      'app_title': 'Oi QR Scanner',
      'tab_scan': 'স্ক্যান করুন',
      'tab_generate': 'তৈরি করুন',
      'tab_history': 'ইতিহাস',
      'tab_settings': 'সেটিংস',
      'scan_qr': 'কিউআর স্ক্যান',
      'generate_qr': 'কিউআর তৈরি করুন',
      'history': 'ইতিহাস',
      'settings': 'সেটিংস',
      'no_history': 'কোনো স্ক্যান পাওয়া যায়নি',
      'scan_now': 'এখন স্ক্যান করুন',
      'exporting': 'সেভ করা হচ্ছে...',
      'language': 'ভাষা',
      'english': 'English',
      'bengali': 'বাংলা',
      'help_guide': 'ব্যবহার নির্দেশিকা',
    }
  };
}
