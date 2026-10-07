import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supermarket_app/config/app_config.dart';

class PaymentService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse response)? _onSuccess;
  Function(PaymentFailureResponse response)? _onFailure;
  Function(ExternalWalletResponse response)? _onExternalWallet;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onSuccess != null) _onSuccess!(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onFailure != null) _onFailure!(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_onExternalWallet != null) _onExternalWallet!(response);
  }

  void openCheckout({
    required String razorpayKey,
    required String razorpayOrderId,
    required double amount,
    required String customerPhone,
    required String customerName,
    required Function(PaymentSuccessResponse response) onSuccess,
    required Function(PaymentFailureResponse response) onFailure,
    required Function(ExternalWalletResponse response) onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    final options = {
      'key': razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': AppConfig.storeName,
      'order_id': razorpayOrderId,
      'description': 'Kirana Order Payment',
      'timeout': 180,
      'prefill': {
        'contact': customerPhone,
        'name': customerName,
      },
      'theme': {
        'color': '#0F766E',
      },
      'external': {
        'wallets': ['paytm', 'phonepe']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
