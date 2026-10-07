import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { en, hi }

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.hi); // Hindi default for rural/village accessibility

  void toggleLanguage() {
    state = state == AppLanguage.hi ? AppLanguage.en : AppLanguage.hi;
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

class AppStrings {
  static String get(String key, AppLanguage lang) {
    final localized = _localizedValues[key];
    if (localized == null) return key;
    return lang == AppLanguage.hi ? (localized['hi'] ?? key) : (localized['en'] ?? key);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    // Auth
    'login_title': {'en': 'Enter Mobile Number', 'hi': 'मोबाइल नंबर दर्ज करें'},
    'login_subtitle': {'en': 'We will send a 6-digit OTP for verification', 'hi': 'सत्यापन के लिए 6 अंकों का OTP भेजा जाएगा'},
    'phone_hint': {'en': '10-digit mobile number', 'hi': '10 अंकों का मोबाइल नंबर'},
    'send_otp': {'en': 'Get OTP', 'hi': 'OTP प्राप्त करें'},
    'verify_otp': {'en': 'Verify & Login', 'hi': 'OTP सत्यापित करें'},
    'otp_sent_to': {'en': 'OTP sent to', 'hi': 'OTP भेजा गया है'},
    'resend_otp': {'en': 'Resend OTP', 'hi': 'दोबारा OTP भेजें'},
    'role_customer': {'en': 'Customer', 'hi': 'ग्राहक'},
    'role_owner': {'en': 'Store Owner', 'hi': 'दुकानदार / मालिक'},
    'role_delivery': {'en': 'Delivery Boy', 'hi': 'डिलीवरी बॉय'},

    // Common
    'app_name': {'en': 'Apna Supermarket', 'hi': 'अपना सुपरमार्केट'},
    'delivery_free': {'en': 'Delivery: FREE', 'hi': 'डिलीवरी: बिल्कुल मुफ्त'},
    'min_order_msg': {'en': 'Add items worth ₹{amount} more to place order', 'hi': 'ऑर्डर करने के लिए ₹{amount} का और सामान जोड़ें'},
    'cart': {'en': 'Cart', 'hi': 'कार्ट / थैला'},
    'search_hint': {'en': 'Search dal, rice, sugar, oil...', 'hi': 'दाल, चीनी, तेल, साबुन खोजें...'},
    'voice_search': {'en': 'Speak to Search', 'hi': 'बोलकर खोजें'},
    'store_closed': {'en': 'Store is currently closed', 'hi': 'दुकान अभी बंद है'},
    'open_maps': {'en': 'Open in Google Maps', 'hi': 'गूगल मैप में देखें'},
    'call_customer': {'en': 'Call Customer', 'hi': 'ग्राहक को कॉल करें'},
    'delivery_otp': {'en': 'Enter Delivery OTP', 'hi': 'डिलीवरी OTP दर्ज करें'},
    'mark_delivered': {'en': 'Confirm Delivery', 'hi': 'डिलीवरी कन्फर्म करें'},
    'cash_collected': {'en': 'Cash Collected (COD)', 'hi': 'नकद राशि प्राप्त हुई'},
  };
}
