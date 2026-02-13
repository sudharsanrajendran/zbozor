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
import 'package:Ebozor/ui/screens/widgets/custom_text_form_field.dart';
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
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Ebozor/utils/login/lib/payloads.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

class SignUpMainScreen extends StatefulWidget {
  const SignUpMainScreen({super.key});

  @override
  State<SignUpMainScreen> createState() => LoginScreenState();

  static CupertinoPageRoute route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => SignUpMainScreen());
  }
}

class LoginScreenState extends State<SignUpMainScreen> {
  final TextEditingController emailMobileTextController =
      TextEditingController();
  String? phone, countryCode, countryName, flagEmoji;
  Country? simCountry;
  String? otp;
  bool isOtpSent = false;
  bool hasErrorOccurred = false;
  final TextEditingController _pinPutController = TextEditingController();
  String signature = "";

  Timer? timer;
  late Size size;
  CountryService countryCodeService = CountryService();
  bool isLoginButtonDisabled = true;
  VoidCallback? _authListenerCancel;
  bool isMobileNumberField = false;
  String numberOrEmail = "";
  final _formKey = GlobalKey<FormState>();

  late PhoneLoginPayload phoneLoginPayload =
      PhoneLoginPayload(emailMobileTextController.text, countryCode!);
  bool isBack = false;

  @override
  void initState() {
    super.initState();

    getSignature();
    context.read<AuthenticationCubit>().init();
    context.read<FetchSystemSettingsCubit>().fetchSettings();
    _authListenerCancel =
        context.read<AuthenticationCubit>().listen((MLoginState state) {
      if (state is MOtpSendInProgress) {
        if (mounted) Widgets.showLoader(context);
      }

      if (state is MVerificationPending) {
        if (mounted) {
          if (hasErrorOccurred) return;
          Widgets.hideLoder(context);
          SmsAutoFill().listenForCode();
          isOtpSent = true;
          setState(() {});
          if (isMobileNumberField) {
            if (isMobileNumberField) {
              HelperUtils.showSnackBarMessage(
                  context, "optsentsuccessflly".translate(context));
            }
          }
        }
      }

      if (state is MFail) {
        hasErrorOccurred = true;
        if (mounted) Widgets.hideLoder(context);
        if (state.error == "google-cancelled") {
          return;
        }

        if (mounted) ScaffoldMessenger.of(context).removeCurrentSnackBar();
        if (isOtpSent && (otp == null || otp!.trim().isEmpty)) {
          if (mounted) {
            HelperUtils.showSnackBarMessage(
                context, "otpSendFailed".translate(context),
                type: MessageType.error);
          }
        } else {
          debugPrint("Signup Error (MFail): ${state.error}");
          if (state.error is FirebaseAuthException) {
            final e = state.error as FirebaseAuthException;
            if (e.code == 'too-many-requests' ||
                e.message?.contains("blocked all requests") == true ||
                e.message?.contains("24 hours") == true) {
              if (mounted) {
                HelperUtils.showSnackBarMessage(
                    context, "tooManyAttempts".translate(context),
                    type: MessageType.error);
              }
            } else if (e.code == 'invalid-phone-number') {
              if (mounted) {
                HelperUtils.showSnackBarMessage(
                    context, "invalidPhone".translate(context),
                    type: MessageType.error);
              }
            } else if (e.code == 'invalid-verification-code') {
              if (mounted) {
                HelperUtils.showSnackBarMessage(
                    context, "invalidOtp".translate(context),
                    type: MessageType.error);
              }
            } else {
              if (mounted) {
                HelperUtils.showSnackBarMessage(
                    context, "loginFailed".translate(context),
                    type: MessageType.error);
              }
            }
          } else {
            if (mounted) {
              HelperUtils.showSnackBarMessage(
                  context, "loginFailed".translate(context),
                  type: MessageType.error);
            }
          }
        }
      }
      if (state is MSuccess) {
        // Widgets.hideLoder(context);
      }
    });
    getSimCountry().then((value) {
      simCountry = value;
      countryCode = value.phoneCode;
      countryName = value.countryCode;

      flagEmoji = value.flagEmoji;
      setState(() {});
    });
  }

  /// it will return user's sim cards country code
  Future<Country> getSimCountry() async {
    List<Country> countryList = countryCodeService.getAll();
    String? simCountryCode;

    try {
      simCountryCode = await DeviceRegion.getSIMCountryCode();
      if (Platform.isIOS &&
          (simCountryCode == "us" || simCountryCode == "US")) {
        simCountryCode = null;
      }
    } catch (e) {}

    Country simCountry = countryList.firstWhere(
      (element) {
        if (Constant.isDemoModeOn) {
          return countryList.any(
            (element) => element.phoneCode == Constant.defaultCountryCode,
          );
        } else {
          return element.countryCode == simCountryCode?.toUpperCase();
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

  Future<void> getSignature() async {
    signature = await SmsAutoFill().getAppSignature;
    await SmsAutoFill().listenForCode();
    setState(() {});
  }

  Future<bool> onBackPress() {
    if (isOtpSent == true) {
      setState(() {
        isOtpSent = false;
        setState(() {
          isOtpSent = false;
          otp = "";
          _pinPutController.clear();
        });
      });
    } else {
      return Future.value(true);
    }
    return Future.value(false);
  }

  Widget otpInput() {
    return Center(
      child: Pinput(
        length: 6,
        controller: _pinPutController,
        onChanged: (String? code) {
          otp = code;
        },
        onCompleted: (String code) {
          otp = code;
        },
        defaultPinTheme: PinTheme(
          width: 50,
          height: 50,
          textStyle: TextStyle(
            fontSize: 20,
            color: context.color.textColorDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.color.territoryColor,
                width: 2.0,
              ),
            ),
          ),
        ),
        keyboardType: TextInputType.number,
        showCursor: true,
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        // listenForMultipleSmsOnAndroid: true,
      ),
    );
  }

  Widget verifyOTPWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18)
          .copyWith(top: MediaQuery.of(context).padding.top + 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: FittedBox(
              fit: BoxFit.none,
              child: MaterialButton(
                onPressed: () {
                  HelperUtils.killPreviousPages(context, Routes.main,
                      {"from": "login", "isSkipped": true});
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
          Text("signInWithMob".translate(context))
              .size(context.font.extraLarge),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Text("+${phoneLoginPayload.countryCode} ${phoneLoginPayload.phoneNumber}")
                  .size(context.font.large),
              const SizedBox(
                width: 5,
              ),
              InkWell(
                  child: Text("change".translate(context))
                      .underline()
                      .color(context.color.territoryColor)
                      .size(context.font.large),
                  onTap: () {
                    setState(() {
                      isOtpSent = false;
                      otp = "";
                      _pinPutController.clear();
                    });
                  }),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          otpInput(),
          const SizedBox(
            height: 8,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MaterialButton(
              onPressed: () {
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
              child: Text("resendOtp".translate(context))
                  .underline()
                  .color(context.color.territoryColor)
                  .size(context.font.small),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          UiUtils.buildButton(context, onPressed: () {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            if (otp == null || otp!.trim().isEmpty) {
              HelperUtils.showSnackBarMessage(
                  context, "enterOtp".translate(context));
              return;
            }
            if (otp!.trim().length < 6) {
              HelperUtils.showSnackBarMessage(
                  context, "enter6Digits".translate(context));
              return;
            }
            phoneLoginPayload.setOTP(otp!.trim());
            context.read<AuthenticationCubit>().setData(
                payload: phoneLoginPayload, type: AuthenticationType.phone);
            context.read<AuthenticationCubit>().authenticate();
          },
              buttonTitle: "submit".translate(context),
              radius: 10,
              disabled: false,
              disabledColor: context.color.territoryColor),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authListenerCancel?.call();
    // ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Unsafe in dispose
    SmsAutoFill().unregisterListener();
    if (timer != null) {
      timer!.cancel();
    }

    emailMobileTextController.dispose();
    _pinPutController.dispose();

    super.dispose();
  }

  Future<void> _onTapContinue() async {
    if (emailMobileTextController.text.trim().isEmpty) {
      HelperUtils.showSnackBarMessage(
          context, "pleaseEnterEmailOrPhoneNumber".translate(context),
          type: MessageType.warning);
      return;
    }
    if (isMobileNumberField) {
      hasErrorOccurred = false;

      bool isValid = await HelperUtils.validatePhone(
          emailMobileTextController.text.trim(), countryName!);

      if (!isValid && countryCode == "1") {
        if (emailMobileTextController.text.trim().length != 10) {
          isValid = false;
        } else {
          isValid = true;
        }
      }

      if (!isValid) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        HelperUtils.showSnackBarMessage(
            context, "pleaseEnterValidPhoneNumber".translate(context),
            type: MessageType.error);
        return;
      }

      if (simCountry != null && countryCode != simCountry!.phoneCode) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        HelperUtils.showSnackBarMessage(
            context,
            "simCountryError"
                .translate(context)
                .replaceFirst("{}", simCountry!.phoneCode),
            type: MessageType.error);
        return;
      }

      phoneLoginPayload =
          PhoneLoginPayload(emailMobileTextController.text, countryCode!);

      context
          .read<AuthenticationCubit>()
          .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
      context.read<AuthenticationCubit>().verify();

      setState(() {});
    } else {
      Navigator.pushNamed(context, Routes.signup, arguments: {
        "emailId": emailMobileTextController.text.toString().trim()
      });
    }
  }

  Future<void> sendVerificationCode() async {
    /*  context
        .read<AuthenticationCubit>()
        .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
    context.read<AuthenticationCubit>().verify();

    setState(() {});*/

    final form = _formKey.currentState;

    if (form == null) return;
    form.save();
    //checkbox value should be 1 before Login/SignUp
    if (form.validate()) {
      _onTapContinue();

      // firebaseLoginProcess();
    }
    // showSnackBar( UiUtils.getTranslatedLabel(context, "acceptPolicy"), context);
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PopScope(
          canPop: isBack,
          onPopInvoked: (didPop) {
            if (isOtpSent) {
              setState(() {
                isOtpSent = false;
                isMobileNumberField = true;
                isMobileNumberField = true;
                otp = "";
                _pinPutController.clear();
              });
              return;
            }
            setState(() {
              isBack = true;
            });
            return;
          },
          child: Scaffold(
            backgroundColor: context.color.backgroundColor,
            bottomNavigationBar: _buildStaticFooter(),
            body: Builder(builder: (context) {
              return BlocListener<LoginCubit, LoginState>(
                listener: (context, state) {
                  if (state is LoginSuccess) {
                    HiveUtils.setUserIsAuthenticated(true);
                    context
                        .read<UserDetailsCubit>()
                        .fill(HiveUtils.getUserDetails());

                    // Change: Allow Mobile Users to bypass Profile Completion
                    if (state.isProfileCompleted || isMobileNumberField) {
                      if (HiveUtils.getCityName() != null &&
                          HiveUtils.getCityName() != "") {
                        HelperUtils.killPreviousPages(
                            context, Routes.main, {"from": "login"});
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.main, (route) => false,
                            arguments: {"from": "login"});
                      }
                    } else {
                      Navigator.pushNamed(
                        context,
                        Routes.completeProfile,
                        arguments: {
                          "from": "login",
                          "popToCurrent": false,
                          "type": isMobileNumberField
                              ? AuthenticationType.phone
                              : AuthenticationType.email,
                          "extraData": {
                            "email": state.credential.user?.email ??
                                state.apiResponse['email'],
                            "username": state.apiResponse['name'],
                            "mobile": state.apiResponse['mobile'],
                            "countryCode": countryCode
                          }
                        },
                      );
                    }
                  }
                  if (state is LoginFailure) {
                    Widgets.hideLoder(context);
                    HelperUtils.showSnackBarMessage(
                        context, state.errorMessage.toString(),
                        type: MessageType.error);
                  }
                },
                child: BlocListener<AuthenticationCubit, AuthenticationState>(
                  listener: (context, state) {
                    if (state is AuthenticationSuccess) {
                      if (mounted) Widgets.hideLoder(context);
                      // Trigger Login instead of redirecting
                      context.read<LoginCubit>().login(
                            phoneNumber: (state.payload as PhoneLoginPayload)
                                .phoneNumber,
                            firebaseUserId: state.credential.user!.uid,
                            type: state.type.name,
                            credential: state.credential,
                            countryCode:
                                "+${(state.payload as PhoneLoginPayload).countryCode}",
                            name: null,
                          );
                    }
                    if (state is AuthenticationFail) {
                      if (mounted) Widgets.hideLoder(context);
                      /*HelperUtils.showSnackBarMessage(context, "Signup Failed",
                        type: MessageType.error);*/
                    }
                    if (state is AuthenticationInProcess) {
                      if (mounted) Widgets.showLoader(context);
                    }
                  },
                  child: Form(
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
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget mobileAndEmailSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("signUpToeClassify".translate(context))
            .size(context.font.large)
            .color(
              context.color.textColorDark,
            ),
        const SizedBox(
          height: 24,
        ),
        CustomTextFormField(
            controller: emailMobileTextController,
            fillColor: context.color.secondaryColor,
            borderColor: context.color.borderColor.darken(30),
            onChange: (value) {
              bool isNumber = value.toString().contains(RegExp(r'^[0-9]+$'));

              isMobileNumberField =
                  Constant.mobileAuthentication == "1" ? isNumber : false;

              numberOrEmail = value;
              setState(() {});
            },
            keyboard: (Constant.mobileAuthentication == "1" &&
                    Constant.emailAuthentication == "1")
                ? (isMobileNumberField
                    ? TextInputType.phone
                    : TextInputType.emailAddress)
                : (Constant.mobileAuthentication == "1")
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
            validator: (Constant.mobileAuthentication == "1" &&
                    Constant.emailAuthentication == "1")
                ? (isMobileNumberField
                    ? CustomTextFieldValidator.phoneNumber
                    : CustomTextFieldValidator.email)
                : (Constant.mobileAuthentication == "1")
                    ? CustomTextFieldValidator.phoneNumber
                    : CustomTextFieldValidator.email,
            fixedPrefix: (isMobileNumberField)
                ? SizedBox(
                    width: 55,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                          onTap: () {
                            showCountryCode();
                          },
                          child: Container(
                            // color: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8),
                            child: Center(
                                child: Text("+$countryCode")
                                    .size(context.font.large)
                                    .centerAlign()),
                          )),
                    ),
                  )
                : null,
            hintText: (Constant.mobileAuthentication == "1" &&
                    Constant.emailAuthentication == "1")
                ? "emailOrPhone".translate(context)
                : (Constant.mobileAuthentication == "1")
                    ? "mobileNumberLbl".translate(context)
                    : "emailAddress".translate(context)),
        const SizedBox(
          height: 46,
        ),
        UiUtils.buildButton(context,
            onPressed: sendVerificationCode,
            buttonTitle: "continue".translate(context),
            radius: 10,
            disabled: false,
            disabledColor: context.color.territoryColor),
      ],
    );
  }

  Widget buildLoginWidget() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: context.screenHeight - 50,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.0)
            .copyWith(top: MediaQuery.of(context).padding.top + 10),
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
            Text("welcome".translate(context))
                .size(context.font.extraLarge)
                .color(context.color.textDefaultColor),
            const SizedBox(
              height: 8,
            ),
            if (Constant.mobileAuthentication == "1" ||
                Constant.emailAuthentication == "1")
              mobileAndEmailSignUp(),
            const SizedBox(
              height: 10,
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
          ],
        ),
      ),
    );
  }

  Widget googleAndAppleSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (Constant.googleAuthentication == "1")
              //////////////////////////

              // continue with google
              UiUtils.buildButton(context,
                  prefixWidget: Padding(
                    padding: EdgeInsetsDirectional.only(end: 10.0),
                    child: UiUtils.getSvg(AppIcons.googleIcon,
                        width: 22, height: 22),
                  ),
                  showElevation: false,
                  outerPadding: const EdgeInsets.only(top: 12),
                  buttonColor: context.color.secondaryColor,
                  border: context.watch<AppThemeCubit>().state.appTheme !=
                          AppTheme.dark
                      ? BorderSide(
                          color:
                              context.color.textDefaultColor.withOpacity(0.5))
                      : null,
                  textColor: context.color.textDefaultColor, onPressed: () {
                context.read<AuthenticationCubit>().setData(
                    payload: GoogleLoginPayload(),
                    type: AuthenticationType.google);
                context.read<AuthenticationCubit>().authenticate();
              },
                  radius: 8,
                  height: 46,
                  buttonTitle: "continueWithGoogle".translate(context)),

            if (Constant.appleAuthentication == "1" && Platform.isIOS)

              //contiunue with apple
              UiUtils.buildButton(context,
                  prefixWidget: Padding(
                    padding: EdgeInsetsDirectional.only(end: 10.0),
                    child: UiUtils.getSvg(AppIcons.appleIcon,
                        width: 22, height: 22),
                  ),
                  showElevation: false,
                  outerPadding: const EdgeInsets.only(top: 12),
                  buttonColor: context.color.secondaryColor,
                  border: context.watch<AppThemeCubit>().state.appTheme !=
                          AppTheme.dark
                      ? BorderSide(
                          color:
                              context.color.textDefaultColor.withOpacity(0.5))
                      : null,
                  textColor: context.color.textDefaultColor, onPressed: () {
                context.read<AuthenticationCubit>().setData(
                    payload: AppleLoginPayload(),
                    type: AuthenticationType.apple);
                context.read<AuthenticationCubit>().authenticate();
              },
                  height: 46,
                  radius: 8,
                  buttonTitle: "continueWithApple".translate(context)),
            const SizedBox(
              height: 24,
            ),
            /////
          ],
        ),
      ],
    );
  }

  Widget _buildStaticFooter() {
    // if (isOtpSent || sendMailClicked) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Constant.googleAuthentication == "1" ||
              Constant.appleAuthentication == "1")
            googleAndAppleSignUp(),
          SizedBox(height: 10),
          termAndPolicyTxt(),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget termAndPolicyTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 15.0, start: 25.0, end: 25.0),
      child: Column(
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
            /*CustomTextButton(
                text:
                    Text("privacyPolicy".translate(context)).underline().color(context.color.teritoryColor).size(context.font.small),
                onPressed: () => Navigator.pushNamed(
                      context,
                      Routes.profileSettings,
                      arguments: {
                        'title': UiUtils.getTranslatedLabel(
                            context, "privacyPolicy"),
                        'param': Api.privacyPolicy
                      },
                    )),*/
          ]),
        ],
      ),
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme:
          CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      onSelect: (Country value) {
        flagEmoji = value.flagEmoji;
        countryCode = value.phoneCode;
        countryName = value.countryCode;
        setState(() {});
      },
    );
  }
}
