import 'package:flutter/material.dart';

/// Single source of truth for Store branding, Legal Details, and Business parameters.
/// Non-technical store owners can edit these or override via Firestore Admin Settings / Remote Config.
class AppConfig {
  // Store Identity
  static const String storeName = "Apna Kirana & Supermarket";
  static const String storeTagline = "Aapke Gaon Ki Apni Dukan";
  static const String supportPhone = "+919876543210";
  static const String supportWhatsApp = "919876543210";
  static const String storeAddress = "Main Market Road, Near Post Office";
  
  // Legal & Invoicing (Mandatory for Food Businesses in India)
  static const String fssaiLicenseNo = "12345678901234";
  static const String gstinNumber = "07AAAAA0000A1Z5"; // Optional

  // Brand Theme Colors
  static const Color primaryColor = Color(0xFF0F766E); // Rich Kirana Green
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color secondaryColor = Color(0xFFF97316); // Warm Saffron / Offer Orange
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);

  // Business Rules (Defaults - Overridden dynamically in Cloud Functions & Firestore)
  static const double defaultDeliveryFee = 0.0; // Delivery is FREE by default
  static const double defaultMinOrderValue = 300.0; // Minimum order value
  static const int orderCancelWindowMinutes = 5; // 5 minute cancel window
  static const bool allowLooseWeightAdjustment = true; // For loose items (chini, dal, etc.)
}
