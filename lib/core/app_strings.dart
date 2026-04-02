import 'package:flutter/material.dart';

class AppStrings {
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  static final Map<String, Map<String, String>> _localized =
      <String, Map<String, String>>{
    'en': <String, String>{
      'language': 'Language',
      'choose_language': 'Choose app language',
      'login_tagline':
          'Secure access to your trusted member network with fast, private sign in.',
      'mobile_number': 'Mobile number',
      'mpin_label': '6 digit M-PIN',
      'signing_in': 'Signing in...',
      'sign_in': 'Sign in',
      'checking_biometrics': 'Checking biometrics...',
      'use_biometric_login': 'Use biometric login',
      'new_member_registration': 'New member registration',
      'enter_valid_mobile': 'Enter a valid 10 digit mobile number.',
      'login_failed': 'Login failed.',
      'biometric_login_failed': 'Biometric login failed.',
      'settings': 'Settings',
      'security': 'Security',
      'security_subtitle': 'Set or update your 6 digit M-PIN used for login.',
      'new_6_digit_mpin': 'New 6 digit M-PIN',
      'confirm_mpin': 'Confirm M-PIN',
      'saving': 'Saving...',
      'update_mpin': 'Update M-PIN',
      'preferences': 'Preferences',
      'notifications': 'Device notifications',
      'notifications_subtitle': 'Show emergency and action alerts on your phone.',
      'vibration': 'Vibration',
      'vibration_subtitle': 'Vibrate on emergency actions and alerts.',
      'logout': 'Logout',
      'logout_subtitle': 'Sign out from this device now.',
      'logout_confirm_title': 'Logout',
      'logout_confirm_message': 'Are you sure you want to logout now?',
      'cancel': 'Cancel',
      'profile_admin_verified_message':
          'Profile fields marked as admin verified can only be changed by admin workflows.',
      'notifications_enabled': 'In-app notifications enabled.',
      'notifications_disabled': 'In-app notifications disabled.',
      'vibration_enabled': 'Vibration enabled.',
      'vibration_disabled': 'Vibration disabled.',
      'mpin_exact_6': 'M-PIN must be exactly 6 digits.',
      'mpin_mismatch': 'M-PIN confirmation does not match.',
      'mpin_cloud_retry': 'Unable to update M-PIN in cloud. Please retry.',
      'mpin_updated': 'M-PIN updated successfully.',
    },
    'hi': <String, String>{
      'language': 'भाषा',
      'choose_language': 'ऐप की भाषा चुनें',
      'login_tagline':
          'तेज़ और सुरक्षित साइन इन के साथ अपने विश्वसनीय सदस्य नेटवर्क तक पहुंचें।',
      'mobile_number': 'मोबाइल नंबर',
      'mpin_label': '6 अंकों का M-PIN',
      'signing_in': 'साइन इन हो रहा है...',
      'sign_in': 'साइन इन',
      'checking_biometrics': 'बायोमेट्रिक्स जांच रहे हैं...',
      'use_biometric_login': 'बायोमेट्रिक लॉगिन का उपयोग करें',
      'new_member_registration': 'नए सदस्य का पंजीकरण',
      'enter_valid_mobile': 'कृपया सही 10 अंकों का मोबाइल नंबर दर्ज करें।',
      'login_failed': 'लॉगिन असफल रहा।',
      'biometric_login_failed': 'बायोमेट्रिक लॉगिन असफल रहा।',
      'settings': 'सेटिंग्स',
      'security': 'सुरक्षा',
      'security_subtitle':
          'लॉगिन के लिए उपयोग होने वाला 6 अंकों का M-PIN सेट या अपडेट करें।',
      'new_6_digit_mpin': 'नया 6 अंकों का M-PIN',
      'confirm_mpin': 'M-PIN की पुष्टि करें',
      'saving': 'सहेजा जा रहा है...',
      'update_mpin': 'M-PIN अपडेट करें',
      'preferences': 'प्राथमिकताएं',
      'notifications': 'डिवाइस नोटिफिकेशन',
      'notifications_subtitle': 'फोन पर आपातकालीन और अन्य अलर्ट दिखाएं।',
      'vibration': 'वाइब्रेशन',
      'vibration_subtitle': 'इमरजेंसी कार्यों और अलर्ट पर वाइब्रेट करें।',
      'logout': 'लॉगआउट',
      'logout_subtitle': 'इस डिवाइस से अभी साइन आउट करें।',
      'logout_confirm_title': 'लॉगआउट',
      'logout_confirm_message': 'क्या आप अभी लॉगआउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'profile_admin_verified_message':
          'एडमिन सत्यापित प्रोफाइल फ़ील्ड केवल एडमिन वर्कफ़्लो से बदले जा सकते हैं।',
      'notifications_enabled': 'इन-ऐप सूचनाएं सक्षम की गईं।',
      'notifications_disabled': 'इन-ऐप सूचनाएं अक्षम की गईं।',
      'vibration_enabled': 'वाइब्रेशन सक्षम किया गया।',
      'vibration_disabled': 'वाइब्रेशन अक्षम किया गया।',
      'mpin_exact_6': 'M-PIN ठीक 6 अंकों का होना चाहिए।',
      'mpin_mismatch': 'M-PIN पुष्टि मेल नहीं खाती।',
      'mpin_cloud_retry': 'क्लाउड में M-PIN अपडेट नहीं हो सका। कृपया पुनः प्रयास करें।',
      'mpin_updated': 'M-PIN सफलतापूर्वक अपडेट हो गया।',
    },
  };

  static String tr(String languageCode, String key) {
    final current = _localized[languageCode] ?? _localized['en']!;
    return current[key] ?? _localized['en']![key] ?? key;
  }

  static String languageLabel(String code, String inLanguageCode) {
    if (inLanguageCode == 'hi') {
      return code == 'hi' ? 'हिन्दी' : 'अंग्रेज़ी';
    }
    return code == 'hi' ? 'Hindi' : 'English';
  }
}