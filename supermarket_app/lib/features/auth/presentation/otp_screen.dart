import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/auth/presentation/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _showNameField = false;

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onVerifyPressed() async {
    final code = _pinController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya 6-digit OTP dalein')),
      );
      return;
    }

    final user = await ref.read(authControllerProvider.notifier).verifyOtp(
      code,
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
    );

    if (user != null && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authControllerProvider);

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppConfig.textPrimary,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppConfig.primaryColor, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? 'OTP सत्यापन' : 'OTP Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('otp_sent_to', lang),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppConfig.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '+91 ${widget.phoneNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.textPrimary,
                ),
              ),
              const SizedBox(height: 28),

              Center(
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (pin) => _onVerifyPressed(),
                ),
              ),
              const SizedBox(height: 20),

              if (_showNameField) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.hi ? 'आपका नाम (वैकल्पिक)' : 'Your Name (Optional)',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                TextButton(
                  onPressed: () => setState(() => _showNameField = true),
                  child: Text(
                    lang == AppLanguage.hi ? '+ नाम जोड़ें' : '+ Add Name',
                    style: const TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConfig.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppConfig.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppConfig.errorColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: authState.isLoading ? null : _onVerifyPressed,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        AppStrings.get('verify_otp', lang),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).sendOtp(widget.phoneNumber);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == AppLanguage.hi ? 'OTP दोबारा भेज दिया गया है' : 'OTP resent successfully',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    AppStrings.get('resend_otp', lang),
                    style: const TextStyle(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
