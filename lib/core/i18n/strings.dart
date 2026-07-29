/// Lightweight i18n. Adding a language = adding one map below and one
/// entry in [AppLanguage] — no other code changes needed.
enum AppLanguage { english, kannada, hindi }

extension AppLanguageX on AppLanguage {
  String get code => switch (this) {
    AppLanguage.english => 'en',
    AppLanguage.kannada => 'kn',
    AppLanguage.hindi => 'hi',
  };

  /// Name shown in the picker, written in that language itself.
  String get nativeName => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.kannada => 'ಕನ್ನಡ',
    AppLanguage.hindi => 'हिन्दी',
  };

  String get englishName => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.kannada => 'Kannada',
    AppLanguage.hindi => 'Hindi',
  };

  static AppLanguage fromCode(String code) => AppLanguage.values
      .firstWhere((e) => e.code == code, orElse: () => AppLanguage.english);
}

class S {
  S._();

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app_tagline': 'One market for every harvest',
      'welcome_title': 'Welcome to BLOB',
      'welcome_body':
          'Connect landowners, buyers, laborers and exporters — all in one place.',
      'get_started': 'Get Started',
      'choose_language': 'Choose your language',
      'language_hint': 'You can change this later in Settings',
      'continue_label': 'Continue',
      'login_title': 'Enter your phone number',
      'login_body': 'We will send you a 6-digit verification code',
      'phone_number': 'Phone number',
      'send_code': 'Send Code',
      'otp_title': 'Verify your number',
      'otp_body': 'Enter the 6-digit code sent to',
      'verify': 'Verify',
      'resend_code': 'Resend code',
      'change_number': 'Change number',
      'choose_role': 'Choose your account type',
      'role_hint': 'This decides what you can do on BLOB',
      'your_name': 'Your name',
      'district': 'District',
      'create_account': 'Create Account',
      'home': 'Home',
      'market': 'Market',
      'jobs': 'Jobs',
      'payments': 'Payments',
      'profile': 'Profile',
      'cleared': 'Cleared',
      'pending': 'Pending',
      'logout': 'Log out',
    },
    'kn': {
      'app_tagline': 'ಪ್ರತಿ ಬೆಳೆಗೂ ಒಂದೇ ಮಾರುಕಟ್ಟೆ',
      'welcome_title': 'BLOB ಗೆ ಸ್ವಾಗತ',
      'welcome_body':
          'ಭೂಮಾಲೀಕರು, ಖರೀದಿದಾರರು, ಕಾರ್ಮಿಕರು ಮತ್ತು ರಫ್ತುದಾರರನ್ನು ಒಂದೇ ಕಡೆ ಸಂಪರ್ಕಿಸಿ.',
      'get_started': 'ಪ್ರಾರಂಭಿಸಿ',
      'choose_language': 'ನಿಮ್ಮ ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
      'language_hint': 'ಇದನ್ನು ನಂತರ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಬದಲಾಯಿಸಬಹುದು',
      'continue_label': 'ಮುಂದುವರಿಸಿ',
      'login_title': 'ನಿಮ್ಮ ಫೋನ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ',
      'login_body': 'ನಾವು 6-ಅಂಕಿಯ ಪರಿಶೀಲನಾ ಕೋಡ್ ಕಳುಹಿಸುತ್ತೇವೆ',
      'phone_number': 'ಫೋನ್ ಸಂಖ್ಯೆ',
      'send_code': 'ಕೋಡ್ ಕಳುಹಿಸಿ',
      'otp_title': 'ನಿಮ್ಮ ಸಂಖ್ಯೆ ಪರಿಶೀಲಿಸಿ',
      'otp_body': 'ಕಳುಹಿಸಲಾದ 6-ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ',
      'verify': 'ಪರಿಶೀಲಿಸಿ',
      'resend_code': 'ಕೋಡ್ ಮರುಕಳುಹಿಸಿ',
      'change_number': 'ಸಂಖ್ಯೆ ಬದಲಾಯಿಸಿ',
      'choose_role': 'ನಿಮ್ಮ ಖಾತೆ ಪ್ರಕಾರ ಆಯ್ಕೆಮಾಡಿ',
      'role_hint': 'ಇದು BLOB ನಲ್ಲಿ ನಿಮ್ಮ ಕೆಲಸವನ್ನು ನಿರ್ಧರಿಸುತ್ತದೆ',
      'your_name': 'ನಿಮ್ಮ ಹೆಸರು',
      'district': 'ಜಿಲ್ಲೆ',
      'create_account': 'ಖಾತೆ ರಚಿಸಿ',
      'home': 'ಮುಖಪುಟ',
      'market': 'ಮಾರುಕಟ್ಟೆ',
      'jobs': 'ಕೆಲಸಗಳು',
      'payments': 'ಪಾವತಿಗಳು',
      'profile': 'ಪ್ರೊಫೈಲ್',
      'cleared': 'ಪಾವತಿಸಲಾಗಿದೆ',
      'pending': 'ಬಾಕಿ',
      'logout': 'ಲಾಗ್ ಔಟ್',
    },
    'hi': {
      'app_tagline': 'हर फसल के लिए एक बाज़ार',
      'welcome_title': 'BLOB में आपका स्वागत है',
      'welcome_body':
          'भूमि मालिक, खरीदार, मज़दूर और निर्यातक — सब एक ही जगह।',
      'get_started': 'शुरू करें',
      'choose_language': 'अपनी भाषा चुनें',
      'language_hint': 'इसे बाद में सेटिंग्स में बदल सकते हैं',
      'continue_label': 'आगे बढ़ें',
      'login_title': 'अपना फ़ोन नंबर दर्ज करें',
      'login_body': 'हम आपको 6 अंकों का सत्यापन कोड भेजेंगे',
      'phone_number': 'फ़ोन नंबर',
      'send_code': 'कोड भेजें',
      'otp_title': 'अपना नंबर सत्यापित करें',
      'otp_body': 'भेजा गया 6 अंकों का कोड दर्ज करें',
      'verify': 'सत्यापित करें',
      'resend_code': 'कोड दोबारा भेजें',
      'change_number': 'नंबर बदलें',
      'choose_role': 'अपना खाता प्रकार चुनें',
      'role_hint': 'इससे तय होगा कि आप BLOB पर क्या कर सकते हैं',
      'your_name': 'आपका नाम',
      'district': 'जिला',
      'create_account': 'खाता बनाएं',
      'home': 'होम',
      'market': 'बाज़ार',
      'jobs': 'काम',
      'payments': 'भुगतान',
      'profile': 'प्रोफ़ाइल',
      'cleared': 'भुगतान हुआ',
      'pending': 'बाकी',
      'logout': 'लॉग आउट',
    },
  };

  static String t(AppLanguage lang, String key) =>
      _values[lang.code]?[key] ?? _values['en']?[key] ?? key;
}
