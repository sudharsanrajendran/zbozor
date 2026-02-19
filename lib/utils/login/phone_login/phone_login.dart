import 'dart:async';
import 'package:Ebozor/utils/login/lib/login_status.dart';
import 'package:Ebozor/utils/login/lib/payloads.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/login/lib/login_system.dart';

class PhoneLogin extends LoginSystem {
  String? verificationId;
  int _currentSession = 0; // Track current verification session

  @override
  void init() {
    verificationId = null;
    _currentSession++; // Increment session to ignore old callbacks
    super.init();
  }

  @override
  Future<UserCredential?> login() async {
    try {
      emit(MProgress());
      // (state);

      String otp = (payload as PhoneLoginPayload).getOTP() ?? "";
      if (verificationId == null || verificationId!.isEmpty) {
        emit(MFail("Verification ID is missing. Please try again."));
        return null;
      }
      if (otp.isEmpty) {
        emit(MFail("OTP is missing."));
        return null;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId!, smsCode: otp);

      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      emit(MSuccess());

      return userCredential;
    } catch (e) {
      emit(MFail(e));
    }
    return null;
  }

  bool _hasError = false;

  Timer? _timer;

  @override
  Future<void> requestVerification() async {
    _currentSession++; // New session for this request
    final int sessionId = _currentSession;

    _hasError = false;
    _timer?.cancel();
    emit(MOtpSendInProgress());

    // Start a timeout timer
    _timer = Timer(Duration(seconds: Constant.otpTimeOutSecond + 10), () {
      if (sessionId != _currentSession) return;
      if (!_hasError) {
        _hasError = true;
        emit(MFail("Verification Timed Out. Please try again."));
      }
    });

    await FirebaseAuth.instance
        .verifyPhoneNumber(
          timeout: Duration(
            seconds: Constant.otpTimeOutSecond,
          ),
          phoneNumber:
              "+${(payload as PhoneLoginPayload).countryCode}${(payload as PhoneLoginPayload).phoneNumber}",
          verificationCompleted: (PhoneAuthCredential credential) async {
            if (sessionId != _currentSession) return;
            _timer?.cancel();
            try {
              await firebaseAuth.signInWithCredential(credential);
              emit(MSuccess());
            } catch (e) {
              emit(MFail(e));
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (sessionId != _currentSession) return;
            _timer?.cancel();
            _hasError = true;
            emit(MFail(e));
          },
          codeSent: (String verificationId, int? resendToken) {
            if (sessionId != _currentSession) return;
            _timer?.cancel();
            if (_hasError) return;
            super.requestVerification();
            forceResendingToken = resendToken;
            this.verificationId = verificationId;
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (sessionId != _currentSession) return;
            _timer?.cancel();
            this.verificationId = verificationId;
            // Ensure we don't emit infinite loading if auto-retrieval times out without code
            // super.requestVerification() typically emits MVerificationPending which might invoke spinner?
            // Let's assume safely handling it here or letting the user input code is fine.
            super.requestVerification();
          },
          forceResendingToken: forceResendingToken,
        )
        .then((value) {});
  }

//verify otp
  Future<void> verifyOtp(String otp) async {
    try {
      // Check if verificationId is set
      if (verificationId == null) {
        throw Exception("Verification ID not found");
      }

      // Create credential using the verification ID and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      // Sign in with the credential
      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // Successfully signed in
      emit(MSuccess());
      print("User signed in successfully: ${userCredential.user?.uid}");
    } catch (e) {
      emit(MFail(e));
      print("Error during OTP verification: $e");
    }
  }

  @override
  void onEvent(MLoginState state) {}
}
