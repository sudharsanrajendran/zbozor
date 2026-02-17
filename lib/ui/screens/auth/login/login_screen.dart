import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:device_region/device_region.dart';
import 'package:Ebozor/app/app_theme.dart';
import 'package:Ebozor/app/routes.dart';

import 'package:Ebozor/data/cubits/auth/authentication_cubit.dart';
import 'package:Ebozor/data/cubits/auth/login_cubit.dart';
import 'package:Ebozor/data/cubits/system/app_theme_cubit.dart';
import 'package:Ebozor/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Ebozor/data/cubits/system/user_details.dart';
import 'package:Ebozor/data/helper/widgets.dart';
import 'package:Ebozor/ui/screens/home/home_screen.dart';
import 'package:Ebozor/ui/screens/widgets/custom_text_form_field.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/ApiService/api.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:Ebozor/utils/cloudState/cloud_state.dart';
import 'package:Ebozor/utils/login/lib/login_status.dart';
import 'package:Ebozor/utils/login/lib/login_system.dart';
import 'package:Ebozor/utils/login/lib/payloads.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginScreen extends StatefulWidget {
  final bool? isDeleteAccount;
  final bool? popToCurrent;

  const LoginScreen({super.key, this.isDeleteAccount, this.popToCurrent});

  @override
  State<LoginScreen> createState() => LoginScreenState();

  static CupertinoPageRoute route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
        builder: (_) => LoginScreen(
              isDeleteAccount: args?['isDeleteAccount'],
              popToCurrent: args?['popToCurrent'],
            ));
  }
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailMobileTextController = TextEditingController(
      text: Constant.isDemoModeOn ? Constant.demoMobileNumber : "");
  bool isOtpSent = false;
  final TextEditingController _pinPutController = TextEditingController();
  bool hasErrorOccurred = false;
  String? phone, otp, countryCode, countryName, flagEmoji;
  Country? simCountry;

  Timer? timer;
  late Size size;
  CountryService countryCodeService = CountryService();
  bool isLoginButtonDisabled = true;
  VoidCallback? _authListenerCancel;
  bool isMobileNumberField = false;
  String numberOrEmail = "";
  bool sendMailClicked = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  bool isObscure = true;
  late PhoneLoginPayload phoneLoginPayload =
      PhoneLoginPayload(emailMobileTextController.text, countryCode!);
  bool isBack = false;
  String signature = "";

  @override
  void initState() {
    super.initState();

    if (Constant.mobileAuthentication == "1") {
      if (Constant.isDemoModeOn) {
        isMobileNumberField = true;
        numberOrEmail = Constant.demoMobileNumber;
      }
    }
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

          // Widgets.showLoader(context);

          isOtpSent = true;
          SmsAutoFill().listenForCode();
          setState(() {});
          if (isMobileNumberField) {
            HelperUtils.showSnackBarMessage(
                context, "optsentsuccessflly".translate(context));
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
          debugPrint("Login Error (MFail): ${state.error}");
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
        if (mounted) Widgets.hideLoder(context);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _authListenerCancel?.call();
    // ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Removed unsafe call
    SmsAutoFill().unregisterListener();
    if (timer != null) {
      timer!.cancel();
    }

    _passwordController.dispose();
    emailMobileTextController.dispose();
    _pinPutController.dispose();

    super.dispose();
  }

  Future<void> _onTapContinue() async {
    forceResendingToken = null;
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

      // isOtpSent = true;
      phoneLoginPayload =
          PhoneLoginPayload(emailMobileTextController.text, countryCode!);

      context
          .read<AuthenticationCubit>()
          .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
      context.read<AuthenticationCubit>().verify();

      setState(() {});
    } else {
      sendMailClicked = true;
      setState(() {});
    }
  }

  //////send verification
  Future<void> sendVerificationCode() async {
    if (widget.isDeleteAccount ?? false) {
      isOtpSent = true;

      context
          .read<AuthenticationCubit>()
          .setData(payload: phoneLoginPayload, type: AuthenticationType.phone);
      context.read<AuthenticationCubit>().verify();

      setState(() {});
    }
    final form = _formKey.currentState;

    if (form == null) return;
    form.save();
    //checkbox value should be 1 before Login/SignUp
    if (form.validate()) {
      if (widget.isDeleteAccount ?? false) {
      } else {
        _onTapContinue();
      }
    }
    // showSnackBar( UiUtils.getTranslatedLabel(context, "acceptPolicy"), context);
  }

  void setDemoOTP() {
    if (Constant.mobileAuthentication == "1") {
      if (emailMobileTextController.text == Constant.demoMobileNumber) {
        otp = Constant.demoModeOTP;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    setDemoOTP();

    /* if (emailMobileTextController.text == Constant.demoMobileNumber) {
      _otpController.text = Constant.demoModeOTP;
    } else {
      _otpController.text = "";
    }*/

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
            if (widget.isDeleteAccount ?? false) {
              Navigator.pop(context);
            } else {
              if (isOtpSent) {
                setState(() {
                  isOtpSent = false;
                  _pinPutController.clear();
                  isMobileNumberField = true;
                });
              } else if (sendMailClicked) {
                setState(() {
                  sendMailClicked = false;
                });
              } else {
                setState(() {
                  isBack = true;
                });
                return;
              }
            }
            setState(() {
              isBack = false;
            });
            return;
          },
          child: Scaffold(
            backgroundColor: context.color.backgroundColor,
            bottomNavigationBar: _buildStaticFooter(),
            body: BlocListener<LoginCubit, LoginState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  // if (mounted) Widgets.hideLoder(context); // Hide loader before navigation
                  HiveUtils.setUserIsAuthenticated(true);
                  //GuestChecker.set(isGuest: false);
                  //context.read<AuthCubit>().updateFCM(context);

                  context
                      .read<UserDetailsCubit>()
                      .fill(HiveUtils.getUserDetails());

                  if (mounted)
                    Widgets.hideLoder(
                        context); // Hide loader immediately before navigation

                  // Change: Allow Mobile Users to bypass Profile Completion (fixes "Email Verify" confusion)
                  if (state.isProfileCompleted) {
                    if (HiveUtils.getCityName() != null &&
                        HiveUtils.getCityName() != "") {
                      HelperUtils.killPreviousPages(
                          context, Routes.main, {"from": "login"});
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.main, (route) => false,
                          arguments: {"from": "login"});
                    }
                  } else if (isMobileNumberField) {
                    Navigator.of(context).pushNamed(
                        Routes.phoneLoginUserDetailsScreen,
                        arguments: {
                          "phone": state.apiResponse['mobile'],
                          "countryCode": countryCode
                        });
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
                  if (mounted)
                    Widgets.hideLoder(context); // Hide loader on failure
                  ////////
                  debugPrint("Login Failure: ${state.errorMessage}");
                  HelperUtils.showSnackBarMessage(
                      context, "Login Failed: ${state.errorMessage}");
                }
              },
              child: BlocConsumer<AuthenticationCubit, AuthenticationState>(
                listener: (context, state) {
                  if (state is AuthenticationSuccess) {
                    // if (mounted) Widgets.hideLoder(context); // Keep loader for continuous UX

                    if (state.type == AuthenticationType.email) {
                      //FirebaseAuth.instance.currentUser?.sendEmailVerification();
                      if (state.credential.user!.emailVerified) {
                        context.read<LoginCubit>().login(
                            phoneNumber: state.credential.user?.phoneNumber,
                            firebaseUserId: state.credential.user!.uid,
                            type: state.type.name,
                            credential: state.credential,
                            countryCode: null,
                            name: CloudState.cloudData['signup_details'] != null
                                ? CloudState.cloudData['signup_details']
                                    ['username']
                                : null);
                      } else {
                        /*HelperUtils.showSnackBarMessage(
                            context, "Please Verify Your email first");*/
                        if (mounted)
                          Widgets.hideLoder(
                              context); // Hide loader if stopping here
                      }
                    } else if (state.type == AuthenticationType.phone) {
                      context.read<LoginCubit>().login(
                          phoneNumber:
                              (state.payload as PhoneLoginPayload).phoneNumber,
                          firebaseUserId: state.credential.user!.uid,
                          type: state.type.name,
                          credential: state.credential,
                          countryCode:
                              "+${(state.payload as PhoneLoginPayload).countryCode}",
                          name: CloudState.cloudData['signup_details'] != null
                              ? CloudState.cloudData['signup_details']
                                  ['username']
                              : null);
                    } else {
                      context.read<LoginCubit>().login(
                          phoneNumber: state.credential.user!.phoneNumber,
                          firebaseUserId: state.credential.user!.uid,
                          type: state.type.name,
                          credential: state.credential,
                          countryCode: null,
                          name: CloudState.cloudData['signup_details'] != null
                              ? CloudState.cloudData['signup_details']
                                  ['username']
                              : null);
                    }
                  }

                  if (state is AuthenticationFail) {
                    if (mounted) Widgets.hideLoder(context);

                    // 🔴 EXACT LOGIN ERROR PRINT HERE
                    debugPrint('========== LOGIN ERROR ==========');
                    debugPrint('ERROR OBJ : ${state.error}');

                    if (state.error is FirebaseAuthException) {
                      final e = state.error as FirebaseAuthException;
                      debugPrint('FIREBASE CODE : ${e.code}');
                      debugPrint('FIREBASE MSG  : ${e.message}');
                    }

                    debugPrint('=================================');
                    // Show friendly message in SnackBar
                    /*HelperUtils.showSnackBarMessage(context, message,
                        type: MessageType.error);*/
                  }

                  if (state is AuthenticationInProcess) {
                    if (mounted) Widgets.showLoader(context);
                  }
                },
                builder: (context, state) {
                  return Builder(builder: (context) {
                    return Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: isOtpSent
                            ? KeyedSubtree(
                                key: const ValueKey("otp"),
                                child: verifyOTPWidget())
                            : sendMailClicked
                                ? KeyedSubtree(
                                    key: const ValueKey("pass"),
                                    child: enterPasswordWidget())
                                : KeyedSubtree(
                                    key: const ValueKey("login"),
                                    child: buildLoginWidget()),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mobileOrEmailLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("loginToeClassify".translate(context))
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

              //isMobileNumberField = isNumber;
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
                            // color: Colors.padding,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8),
                            child: Center(
                                child: Text("+$countryCode")
                                    .size(context.font.large)
                                    .centerAlign()),
                          ),
                        )),
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
        UiUtils.buildButton(
          context,
          onPressed: sendVerificationCode,
          buttonTitle: "continue".translate(context),
          radius: 10,
          disabled: false,
          disabledColor: context.color.territoryColor,
        )
      ],
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

////////////////////////////////////////////
  Widget _buildStaticFooter() {
    if (isOtpSent || sendMailClicked) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (Constant.googleAuthentication == "1" ||
              Constant.appleAuthentication == "1")
            googleAndAppleLogin(),
          SizedBox(height: 10),
          termAndPolicyTxt(),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget buildLoginWidget() {
    return SizedBox(
      height: context.screenHeight - 50,
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
                    HiveUtils.setUserSkip();
                    HelperUtils.killPreviousPages(context, Routes.main,
                        {"from": "login", "isSkipped": true});
                    /*Navigator.pushReplacementNamed(
                      context,
                      Routes.main,
                      arguments: {
                        "from": "login",
                        "isSkipped": true,
                      },
                    );*/
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
            Text("welcomeback".translate(context))
                .size(context.font.extraLarge)
                .color(context.color.textDefaultColor),
            const SizedBox(
              height: 8,
            ),
            if (Constant.mobileAuthentication == "1" ||
                Constant.emailAuthentication == "1")
              mobileOrEmailLogin(),
            const SizedBox(
              height: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (Constant.mobileAuthentication == "1" ||
                    Constant.emailAuthentication == "1")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("dontHaveAcc".translate(context))
                          .color(context.color.textColorDark.brighten(50)),
                      const SizedBox(
                        width: 12,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.signupMainScreen);
                        },
                        child: Text("signUp".translate(context))
                            .underline()
                            .color(context.color.territoryColor),
                      )
                    ],
                  ),
                const SizedBox(
                  height: 24,
                ),
                // if (Constant.googleAuthentication == "1" ||
                //     Constant.appleAuthentication == "1")
                //   googleAndAppleLogin(),
                if (Constant.mobileAuthentication == "0" ||
                    Constant.emailAuthentication == "0") ...[
                  if ((Constant.googleAuthentication == "1") ||
                      (Constant.appleAuthentication == "1" &&
                          Platform.isIOS)) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("dontHaveAcc".translate(context))
                            .color(context.color.textColorDark.brighten(50)),
                        const SizedBox(
                          width: 12,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                                context, Routes.signupMainScreen);
                          },
                          child: Text("signUp".translate(context))
                              .underline()
                              .color(context.color.territoryColor),
                        )
                      ],
                    )
                  ],
                ],
              ],
            ),
            /* const Spacer(),
            termAndPolicyTxt()*/
          ],
        ),
      ),
    );
  }

  //Apple login Widgets
  Widget googleAndAppleLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (Constant.mobileAuthentication == "1" ||
            Constant.emailAuthentication == "1")
          if ((Constant.googleAuthentication == "1") ||
              (Constant.appleAuthentication == "1" && Platform.isIOS))
            Text("orSignInWith".translate(context))
                .color(context.color.textDefaultColor),
        if (Constant.googleAuthentication == "1")
          UiUtils.buildButton(context,
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child:
                    UiUtils.getSvg(AppIcons.googleIcon, width: 22, height: 22),
              ),
              showElevation: false,
              outerPadding: const EdgeInsets.only(top: 12),
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
        ////////////////////////////////

        if (Constant.appleAuthentication == "1" && Platform.isIOS)
          UiUtils.buildButton(context,
              prefixWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child:
                    UiUtils.getSvg(AppIcons.appleIcon, width: 22, height: 22),
              ),
              showElevation: false,
              outerPadding: const EdgeInsets.only(top: 12),
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

  Future<bool> onBackPress() {
    if (widget.isDeleteAccount ?? false) {
      Navigator.pop(context);
    } else {
      if (isOtpSent == true) {
        setState(() {
          isOtpSent = false;
          otp = "";
          _pinPutController.clear();
        });
      } else {
        return Future.value(true);
      }
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
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: sidePadding,
          right: sidePadding),
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
                  /*Navigator.pushReplacementNamed(
                    context,
                    Routes.main,
                    arguments: {
                      "from": "login",
                      "isSkipped": true,
                    },
                  );*/
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
                setState(() {
                  hasErrorOccurred = false;
                  otp = "";
                  _pinPutController.clear();
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
                    context, "enterOtp".translate(context));
                return;
              }

              if (otp!.trim().length < 6) {
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

  Widget enterPasswordWidget() {
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: sidePadding,
          right: sidePadding),
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
                  /* Navigator.pushReplacementNamed(
                    context,
                    Routes.main,
                    arguments: {
                      "from": "login",
                      "isSkipped": true,
                    },
                  );*/
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
            height: 15,
          ),
          Text("signInWithEmail".translate(context))
              .size(context.font.extraLarge),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Text(emailMobileTextController.text).size(context.font.large),
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
            height: 12,
          ),
          CustomTextFormField(
            hintText: "${"password".translate(context)}*",
            controller: _passwordController,
            obscureText: isObscure,
            suffix: IconButton(
              onPressed: () {
                isObscure = !isObscure;
                setState(() {});
              },
              icon: Icon(
                !isObscure ? Icons.visibility : Icons.visibility_off,
                color: context.color.textColorDark.withOpacity(0.3),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.forgotPassword);
              },
              child: Text("${"forgotPassword".translate(context)}?")
                  .color(context.color.textLightColor)
                  .size(context.font.normal),
            ),
          ),
          const SizedBox(
            height: 19,
          ),
          UiUtils.buildButton(
            context,
            onPressed: () {
              context.read<AuthenticationCubit>().setData(
                  payload: EmailLoginPayload(
                      email: emailMobileTextController.text,
                      password: _passwordController.text,
                      type: EmailLoginType.login),
                  type: AuthenticationType.email);
              context.read<AuthenticationCubit>().authenticate();
            },
            buttonTitle: "signIn".translate(context),
            radius: 8,
          ),
        ],
      ),
    );
  }
}
