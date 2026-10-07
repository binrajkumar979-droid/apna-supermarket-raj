import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supermarket_app/core/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    final formattedNumber = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserModel> verifyOtpAndGetUser({
    required String verificationId,
    required String smsCode,
    String? initialName,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception("User login failed");
    }

    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        phone: firebaseUser.phoneNumber ?? '',
        name: initialName ?? 'Customer',
        role: UserRole.customer,
      );

      await userDocRef.set(newUser.toMap());
      return newUser;
    } else {
      return UserModel.fromMap(docSnapshot.data()!, firebaseUser.uid);
    }
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromMap(snapshot.data()!, uid);
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
