import 'dart:async';

import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/auth/authentication_cubit.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  EmailVerificationScreen(
      {super.key,
      required this.email,
      required this.password,
      required this.username});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Timer? timer;(removed as per request)
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocConsumer<AuthenticationCubit, AuthenticationState>(
          listener: (context, state) async {
            if (state is AuthenticationSuccess) {
              // if (state.type == AuthenticationType.email) {
              //   HiveUtils.setUserIsAuthenticated(true);
              //
              //   context.read<AuthCubit>().updateFCM(context);
              //   //GuestChecker.set(isGuest: false);
              //   FirebaseAuth.instance.currentUser?.sendEmailVerification();
              //
              //   Navigator.pushReplacementNamed(context, Routes.login);
              //   /* context.read<LoginCubit>().login(
              //       // phoneNumber: phoneNumber,
              //       credential: state.credential,
              //       firebaseUserId: state.credential.user!.uid,
              //       type: state.type.name);*/
              // }
            }

            if (state is AuthenticationFail) {
              debugPrint("Authentication Failure: ${state.error}");
            }
          },
          builder: (context, state) {
            if (state is AuthenticationInProcess) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is AuthenticationSuccess) {
              return Padding(
                padding: const EdgeInsets.all(18.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                          child: UiUtils.getAdaptiveSvg(
                              context, AppIcons.verificationMail,
                              color: context.color.territoryColor)),
                      Text("youHaveGotEmail".translate(context))
                          .size(context.font.extraLarge)
                          .bold(weight: FontWeight.w600),
                      const SizedBox(
                        height: 14,
                      ),
                      Text("clickLinkInYourEmail".translate(context)),
                      const SizedBox(
                        height: 58,
                      ),
                      MaterialButton(
                        onPressed: () {
                          // Navigate to login screen regardless of verification status
                          Navigator.pushReplacementNamed(context, Routes.login);
                        },
                        elevation: 0,
                        minWidth: double.infinity,
                        height: 46,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: context.color.territoryColor,
                        child: Text("Go To Login".translate(context))
                            .color(context.color.buttonColor)
                            .size(context.font.large),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is AuthenticationFail) {
              return Center(
                child: Text("Verification Failed"),
              );
            }

            return Container();
          },
        ),
      ),
    );
  }

  void openEmailAppToList() async {
    const String customUriScheme = 'email://inbox'; // Example URI
    if (await canLaunchUrlString(customUriScheme)) {
      await launchUrlString(customUriScheme);
    } else {
      // Handle case where custom URI scheme cannot be launched

      // Fallback to opening the email app normally
      await launchUrlString(
          'mailto:'); // Opens the email app without specifying the inbox
    }
  }
}
