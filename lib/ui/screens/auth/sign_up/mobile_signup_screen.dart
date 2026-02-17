import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:device_region/device_region.dart';
import 'package:Ebozor/app/app_theme.dart';
import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/system/app_theme_cubit.dart';
import 'package:Ebozor/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Ebozor/data/helper/widgets.dart';
import 'package:Ebozor/ui/screens/home/home_screen.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/helper_utils.dart';

import 'package:Ebozor/utils/login/lib/login_status.dart';
import 'package:Ebozor/utils/ApiService/api.dart';
import 'package:Ebozor/data/cubits/auth/authentication_cubit.dart';
import 'package:Ebozor/data/cubits/auth/login_cubit.dart';
import 'package:Ebozor/data/cubits/system/user_details.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:Ebozor/utils/login/lib/payloads.dart';
import 'package:Ebozor/utils/ui_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Ebozor/ui/screens/widgets/otp_field_widget.dart';

class MobileSignUpScreen extends StatefulWidget {
  final String? mobile;
  final String? countryCode;

  const MobileSignUpScreen({super.key, this.mobile, this.countryCode});

  @override
  State<MobileSignUpScreen> createState() => MobileSignUpScreenState();

  static CupertinoPageRoute route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
        builder: (_) => MobileSignUpScreen(
              mobile: args?['mobile'],
              countryCode: args?['countryCode'],
            ));
  }
}

class MobileSignUpScreenState extends State<MobileSignUpScreen> {
  final TextEditingController mobileTextController = TextEditingController();
  bool isOtpSent = false;
  String? phone, otp, countryName, flagEmoji;

  Timer? timer;
  late Size size;
  CountryService countryCodeService = CountryService();
  bool isLoginButtonDisabled = true;
  final _formKey = GlobalKey<FormState>();

  bool isObscure = true;
  late PhoneLoginPayload phoneLoginPayload =
      PhoneLoginPayload(widget.mobile!, widget.countryCode!);
  bool isBack = false;
  String signature = "";

  bool hasErrorOccurred = false;
  VoidCallback? _authListenerCancel;

  @override
  void initState() {
    super.initState();
    getSignature();
    //mobileTextController.text = widget.mobile!;

    context.read<AuthenticationCubit>().init();
    context.read<FetchSystemSettingsCubit>().fetchSettings();
    _authListenerCancel =
        context.read<AuthenticationCubit>().listen((MLoginState state) {
      if (state is MFail) {
        hasErrorOccurred = true;
        Widgets.hideLoder(context);
        String errorMessage = state.error.toString();
        if (state.error is FirebaseAuthException) {
          if ((state.error as FirebaseAuthException).code ==
              'too-many-requests') {
            errorMessage = "Too many attempts. Please try again in some time.";
          } else if ((state.error as FirebaseAuthException)
                  .message
                  ?.contains("blocked all requests") ==
              true) {
            errorMessage = "Too many attempts. Please try again in some time.";
          }
        }
        HelperUtils.showSnackBarMessage(context, errorMessage,
            type: MessageType.error);
      }
      if (state is MVerificationPending) {
        if (hasErrorOccurred) return;
        Widgets.hideLoder(context);
        isOtpSent = true;
        HelperUtils.showSnackBarMessage(context, "otpSent".translate(context),
            type: MessageType.success);
        setState(() {});
      }
      if (state is MSuccess) {
        Widgets.hideLoder(context);
        Navigator.pushNamed(
          context,
          Routes.main,
          arguments: {
            "from": "login",
            "isSkipped": false,
          },
        );
      }
    });
  }

  Future<void> getSignature() async {
    signature = await SmsAutoFill().getAppSignature;
    await SmsAutoFill().listenForCode;
    setState(() {});
  }

  /// it will return user's sim cards country code
  Future<Country> getSimCountry() async {
    List<Country> countryList = countryCodeService.getAll();
    String? simCountryCode;

    try {
      simCountryCode = await DeviceRegion.getSIMCountryCode();
    } catch (e) {}

    Country simCountry = countryList.firstWhere(
      (element) {
        if (Constant.isDemoModeOn) {
          return countryList.any(
            (element) => element.phoneCode == Constant.defaultCountryCode,
          );
        } else {
          return element.phoneCode == simCountryCode;
        }
      },
      orElse: () {
        return countryList
            .where(
              (element) => element.phoneCode == Constant.defaultCountryCode,
            )
            .first;
      },
    );

    if (Constant.isDemoModeOn) {
      simCountry = countryList
          .where((element) => element.phoneCode == Constant.demoCountryCode)
          .first;
    }

    return simCountry;
  }

  @override
  void dispose() {
    _authListenerCancel?.call();
    if (timer != null) {
      timer!.cancel();
    }

    //mobileTextController.dispose();
    SmsAutoFill().unregisterListener();

    super.dispose();
  }

  void _onTapContinue() {
    hasErrorOccurred = false;
    phoneLoginPayload = PhoneLoginPayload(widget.mobile!, widget.countryCode!);
    context
        .read<AuthenticationCubit>()
        .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
    context.read<AuthenticationCubit>().verify();

    setState(() {});
  }

  Future<void> sendVerificationCode() async {
    final form = _formKey.currentState;

    if (form == null) return;
    form.save();

    //checkbox value should be 1 before Login/SignUp
    if (form.validate()) {
      Widgets.showLoader(context);
      _onTapContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: PopScope(
            canPop: isBack,
            onPopInvoked: (didPop) {
              if (isOtpSent) {
                setState(() {
                  isOtpSent = false;
                  otp = null;
                });
              } else {
                setState(() {
                  isBack = true;
                });
                return;
              }

              setState(() {
                isBack = false;
              });
              return;
            },
            child: AnnotatedRegion(
              value: SystemUiOverlayStyle(
                statusBarColor: context.color.backgroundColor,
              ),
              child: Scaffold(
                backgroundColor: context.color.backgroundColor,
                bottomNavigationBar:
                    !isOtpSent ? termAndPolicyTxt() : SizedBox.shrink(),
                body: BlocListener<LoginCubit, LoginState>(
                  listener: (context, state) {
                    if (state is LoginSuccess) {
                      HiveUtils.setUserIsAuthenticated(true);
                      context
                          .read<UserDetailsCubit>()
                          .fill(HiveUtils.getUserDetails());

                      if (HiveUtils.getCityName() != null &&
                          HiveUtils.getCityName() != "") {
                        HelperUtils.killPreviousPages(
                            context, Routes.main, {"from": "login"});
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.main, (route) => false,
                            arguments: {"from": "login"});
                      }
                    } else if (state is LoginFailure) {
                      Widgets.hideLoder(context);
                      HelperUtils.showSnackBarMessage(
                          context, state.errorMessage.toString(),
                          type: MessageType.error);
                    }
                  },
                  child: BlocListener<AuthenticationCubit, AuthenticationState>(
                    listener: (context, state) {
                      if (state is AuthenticationSuccess) {
                        // Widgets.hideLoder(context); // Keep loader visible for seamless transition
                        context.read<LoginCubit>().login(
                              phoneNumber: (state.payload as PhoneLoginPayload)
                                  .phoneNumber,
                              firebaseUserId: state.credential.user!.uid,
                              type: state.type.name,
                              credential: state.credential,
                              countryCode:
                                  "+${(state.payload as PhoneLoginPayload).countryCode}",
                              name: ' ', // Default name as space
                            );
                      }
                      if (state is AuthenticationFail) {
                        Widgets.hideLoder(context);
                        if (state.error is FirebaseAuthException) {
                          if ((state.error as FirebaseAuthException).code ==
                              'invalid-verification-code') {
                            HelperUtils.showSnackBarMessage(
                                context, "Entered otp is invalid",
                                type: MessageType.error);
                          } else {
                            HelperUtils.showSnackBarMessage(
                                context, state.error.toString(),
                                type: MessageType.error);
                          }
                        }
                      }
                    },
                    child: Builder(builder: (context) {
                      return Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: isOtpSent
                              ? KeyedSubtree(
                                  key: const ValueKey("otp"),
                                  child: verifyOTPWidget())
                              : KeyedSubtree(
                                  key: const ValueKey("signup"),
                                  child: buildLoginWidget()),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emailSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 36,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("signupWithLbl".translate(context))
                .color(context.color.textColorDark.brighten(50)),
            const SizedBox(
              width: 5,
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, Routes.signupMainScreen);
              },
              child: Text("emailLbl".translate(context))
                  .underline()
                  .color(context.color.territoryColor),
            )
          ],
        ),
      ],
    );
  }

  Widget buildLoginWidget() {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: context.screenHeight - 50,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: FittedBox(
                  fit: BoxFit.none,
                  child: MaterialButton(
                    onPressed: () {
                      //HiveUtils.setUserIsNotNew();

                      Navigator.pushNamed(
                        context,
                        Routes.main,
                        arguments: {
                          "from": "login",
                          "isSkipped": true,
                        },
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: context.color.territoryColor,
                    elevation: 0,
                    height: 28,
                    minWidth: 64,
                    child: Text("skip".translate(context))
                        .color(context.color.buttonColor),
                  ),
                ),
              ),
              const SizedBox(
                height: 66,
              ),
              Text("welcome".translate(context))
                  .size(context.font.extraLarge)
                  .color(context.color.textDefaultColor),
              const SizedBox(
                height: 8,
              ),
              Text("signUpToeClassify".translate(context))
                  .size(context.font.large)
                  .color(
                    context.color.textColorDark,
                  ),
              const SizedBox(
                height: 24,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 18),
                decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: context.color.borderColor.darken(30))),
                child: Row(
                  children: [
                    // Display the country code as text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("+${widget.countryCode}")
                          .size(context.font.large)
                          .centerAlign(),
                    ),
                    Expanded(
                      child: Text(
                        widget.mobile!,
                      ).size(context.font.large),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 46,
              ),
              UiUtils.buildButton(context,
                  onPressed: sendVerificationCode,
                  buttonTitle: "verifyMobileNumberLbl".translate(context),
                  radius: 10,
                  disabledColor: const Color.fromARGB(255, 104, 102, 106)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (Constant.emailAuthentication == '1') emailSignUp(),
                  if (Constant.googleAuthentication == "1" ||
                      Constant.appleAuthentication == "1")
                    googleAndAppleAuth(),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("alreadyHaveAcc".translate(context))
                          .color(context.color.textColorDark.brighten(50)),
                      const SizedBox(
                        width: 12,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.login);
                        },
                        child: Text("login".translate(context))
                            .underline()
                            .color(context.color.territoryColor),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget googleAndAppleAuth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 24,
        ),
        if (Constant.googleAuthentication == "1")
          UiUtils.buildButton(context,
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child:
                    UiUtils.getSvg(AppIcons.googleIcon, width: 22, height: 22),
              ),
              showElevation: false,
              buttonColor: context.color.secondaryColor,
              border: context.watch<AppThemeCubit>().state.appTheme !=
                      AppTheme.dark
                  ? BorderSide(
                      color: context.color.textDefaultColor.withOpacity(0.5))
                  : null,
              textColor: context.color.textDefaultColor, onPressed: () {
            context.read<AuthenticationCubit>().setData(
                payload: GoogleLoginPayload(), type: AuthenticationType.google);
            context.read<AuthenticationCubit>().authenticate();
          },
              radius: 8,
              height: 46,
              buttonTitle: "continueWithGoogle".translate(context)),
        if (Constant.appleAuthentication == "1" && Platform.isIOS) ...[
          const SizedBox(
            height: 12,
          ),
          UiUtils.buildButton(context,
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child:
                    UiUtils.getSvg(AppIcons.appleIcon, width: 22, height: 22),
              ),
              showElevation: false,
              buttonColor: context.color.secondaryColor,
              border: context.watch<AppThemeCubit>().state.appTheme !=
                      AppTheme.dark
                  ? BorderSide(
                      color: context.color.textDefaultColor.withOpacity(0.5))
                  : null,
              textColor: context.color.textDefaultColor, onPressed: () {
            context.read<AuthenticationCubit>().setData(
                payload: AppleLoginPayload(), type: AuthenticationType.apple);
            context.read<AuthenticationCubit>().authenticate();
          },
              height: 46,
              radius: 8,
              buttonTitle: "continueWithApple".translate(context)),
        ]
      ],
    );
  }

  Widget termAndPolicyTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 15.0, start: 25.0, end: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("bySigningUpLoggingIn".translate(context))
              .centerAlign()
              .size(context.font.small)
              .color(context.color.textLightColor.withOpacity(0.8)),
          const SizedBox(
            height: 3,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            InkWell(
                child: Text("termsOfService".translate(context))
                    .underline()
                    .color(context.color.territoryColor)
                    .size(context.font.small),
                onTap: () => Navigator.pushNamed(
                        context, Routes.profileSettings, arguments: {
                      'title': "termsConditions".translate(context),
                      'param': Api.termsAndConditions
                    })),
            /*CustomTextButton(
                text:Text("termsOfService".translate(context)).underline().color(context.color.teritoryColor).size(context.font.small),
                onPressed: () => Navigator.pushNamed(
                        context, Routes.profileSettings,
                        arguments: {
                          'title': UiUtils.getTranslatedLabel(
                              context, "termsConditions"),
                          'param': Api.termsAndConditions
                        })),*/
            const SizedBox(
              width: 5.0,
            ),
            Text("andTxt".translate(context))
                .size(context.font.small)
                .color(context.color.textLightColor.withOpacity(0.8)),
            const SizedBox(
              width: 5.0,
            ),
            InkWell(
                child: Text("privacyPolicy".translate(context))
                    .underline()
                    .color(context.color.territoryColor)
                    .size(context.font.small),
                onTap: () => Navigator.pushNamed(
                        context, Routes.profileSettings, arguments: {
                      'title': "privacyPolicy".translate(context),
                      'param': Api.privacyPolicy
                    })),
          ]),
        ],
      ),
    );
  }

  Widget otpInput() {
    return CustomOtpField(
        currentCode: otp,
        onCodeChanged: (String? code) {
          otp = code;
          print("OTP changed: $otp");
        },
        onCodeSubmitted: (String code) {
          otp = code;
        });
  }

  Widget verifyOTPWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: FittedBox(
              fit: BoxFit.none,
              child: MaterialButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.main,
                    arguments: {
                      "from": "login",
                      "isSkipped": true,
                    },
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: context.color.territoryColor,
                elevation: 0,
                height: 28,
                minWidth: 64,
                child: Text("skip".translate(context))
                    .color(context.color.buttonColor),
              ),
            ),
          ),
          const SizedBox(
            height: 66,
          ),
          Text("signInWithMob".translate(context))
              .size(context.font.extraLarge),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Text("+${phoneLoginPayload.countryCode}\t${phoneLoginPayload.phoneNumber}")
                  .size(context.font.large),
              const SizedBox(
                width: 5,
              ),
              InkWell(
                  child: Text("change".translate(context))
                      .underline()
                      .color(context.color.territoryColor)
                      .size(context.font.large),
                  onTap: () => Navigator.pushNamed(context, Routes.login)),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          otpInput(),
          /* CustomTextFormField(
              controller: _otpController,
              keyboard: TextInputType.number,
              hintText: "enterOTPHere".translate(context),
              //maxLength: 6,
              validator: CustomTextFieldValidator.otpSix),*/
          const SizedBox(
            height: 8,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MaterialButton(
              onPressed: () {
                Widgets.showLoader(context);
                setState(() {
                  hasErrorOccurred = false;
                  otp = "";
                });
                context.read<AuthenticationCubit>().setData(
                      payload: phoneLoginPayload,
                      type: AuthenticationType.phone,
                    );
                context.read<AuthenticationCubit>().verify();
              },
              child: Text("resendOTP".translate(context))
                  .color(context.color.textColorDark.withOpacity(0.7)),
            ),
          ),
          const SizedBox(
            height: 19,
          ),
          UiUtils.buildButton(
            context,
            onPressed: () {
              if (otp == null || otp!.trim().isEmpty) {
                HelperUtils.showSnackBarMessage(
                    context, "lblEnterOtp".translate(context));
              } else if (otp!.trim().length < 6) {
                HelperUtils.showSnackBarMessage(
                    context, "enter6Digits".translate(context));
              } else {
                phoneLoginPayload.setOTP(otp!.trim());
                context.read<AuthenticationCubit>().authenticate();
              }
            },
            buttonTitle: "signIn".translate(context),
            radius: 8,
          ),
        ],
      ),
    );
  }
}
