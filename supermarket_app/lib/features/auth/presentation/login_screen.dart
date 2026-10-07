import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/auth/presentation/auth_controller.dart';
import 'package:supermarket_app/features/auth/presentation/otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onGetOtpPressed() {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      ref.read(authControllerProvider.notifier).sendOtp(phone);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpScreen(phoneNumber: phone),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.storeName),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            icon: const Icon(Icons.language, color: Colors.white, size: 20),
            label: Text(
              lang == AppLanguage.hi ? 'English' : 'हिंदी',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConfig.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: AppConfig.primaryColor, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              AppConfig.storeName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.primaryColor,
                              ),
                            ),
                            Text(
                              AppConfig.storeTagline,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppConfig.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                Text(
                  AppStrings.get('login_title', lang),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppConfig.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('login_subtitle', lang),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConfig.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      child: const Text(
                        '+91',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.textPrimary,
                        ),
                      ),
                    ),
                    hintText: AppStrings.get('phone_hint', lang),
                    hintStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 10) {
                      return lang == AppLanguage.hi 
                          ? 'कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें' 
                          : 'Please enter valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: authState.isLoading ? null : _onGetOtpPressed,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          AppStrings.get('send_otp', lang),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppConfig.successColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.get('delivery_free', lang),
                        style: const TextStyle(
                          color: AppConfig.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
