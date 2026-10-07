import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supermarket_app/features/auth/data/auth_repository.dart';
import 'package:supermarket_app/core/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileStreamProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateStreamProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).streamUserProfile(authUser.uid);
});

class AuthState {
  final bool isLoading;
  final String? verificationId;
  final int? resendToken;
  final String? errorMessage;
  final String? phoneNumber;
  final bool isCodeSent;

  AuthState({
    this.isLoading = false,
    this.verificationId,
    this.resendToken,
    this.errorMessage,
    this.phoneNumber,
    this.isCodeSent = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? verificationId,
    int? resendToken,
    String? errorMessage,
    String? phoneNumber,
    bool? isCodeSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isCodeSent: isCodeSent ?? this.isCodeSent,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(AuthState());

  void sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null, phoneNumber: phone);
    
    await _repo.sendOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        state = state.copyWith(
          isLoading: false,
          verificationId: verificationId,
          resendToken: resendToken,
          isCodeSent: true,
        );
      },
      onVerificationFailed: (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message ?? "OTP verification failed. Please try again.",
        );
      },
      onVerificationCompleted: (credential) async {
        if (credential.smsCode != null && state.verificationId != null) {
          verifyOtp(credential.smsCode!);
        }
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        state = state.copyWith(verificationId: verificationId);
      },
    );
  }

  Future<UserModel?> verifyOtp(String code, {String? name}) async {
    if (state.verificationId == null) {
      state = state.copyWith(errorMessage: "Please request OTP first");
      return null;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final user = await _repo.verifyOtpAndGetUser(
        verificationId: state.verificationId!,
        smsCode: code,
        initialName: name,
      );
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Galat OTP! Kripya sahi OTP dalein (${e.toString()})",
      );
      return null;
    }
  }

  void resetState() {
    state = AuthState();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    resetState();
  }
}
