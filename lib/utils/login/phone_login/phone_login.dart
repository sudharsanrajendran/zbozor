
import 'package:Ebozor/utils/login/lib/login_status.dart';
import 'package:Ebozor/utils/login/lib/payloads.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/login/lib/login_system.dart';

class PhoneLogin extends LoginSystem {
  String? verificationId;

  @override
  Future<UserCredential?> login() async {
    try {
      emit(MProgress());
      // (state);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId ?? "",
          smsCode: (payload as PhoneLoginPayload).getOTP()!);

      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      emit(MSuccess());

      return userCredential;
    } catch (e) {
      emit(MFail(e));
    }
    return null;
  }

  @override
  Future<void> requestVerification() async {
    emit(MOtpSendInProgress());
    await FirebaseAuth.instance
        .verifyPhoneNumber(
          timeout: Duration(
            seconds: Constant.otpTimeOutSecond,
          ),
          phoneNumber:
              "+${(payload as PhoneLoginPayload).countryCode}${(payload as PhoneLoginPayload).phoneNumber}",
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            emit(MFail(e));
          },
          codeSent: (String verificationId, int? resendToken) {
            super.requestVerification();
            forceResendingToken = resendToken;
            this.verificationId = verificationId;
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
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
      UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

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
