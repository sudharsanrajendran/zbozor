// import 'dart:async';

import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/system/fetch_language_cubit.dart';
import 'package:Ebozor/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:Ebozor/data/cubits/system/language_cubit.dart';
import 'package:Ebozor/ui/screens/widgets/errors/no_internet.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:Ebozor/utils/responsiveSize.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';

// import 'package:flutter/services.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// import '../app/routes.dart';
import 'package:Ebozor/data/model/system_settings_model.dart';

// import 'package:Ebozor/main.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  //late OldAuthenticationState authenticationState;

  bool isTimerCompleted = false;
  bool isSettingsLoaded = false; //TODO: temp
  bool isLanguageLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool hasInternet = true;
  bool hasNavigated = false;
  bool isBootstrapping = false;

  @override
  void initState() {
    //locationPermission();
    super.initState();
    checkInitialConnectivity();

    subscription = Connectivity().onConnectivityChanged.listen((result) {
      bool connected = !result.contains(ConnectivityResult.none);
      if (mounted) {
        setState(() {
          hasInternet = connected;
        });
      }
      if (connected && !isBootstrapping) {
        bootstrap();
      }
    });
  }

  void checkInitialConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    bool connected = !result.contains(ConnectivityResult.none);
    if (mounted) {
      setState(() {
        hasInternet = connected;
      });
    }
    if (connected && !isBootstrapping) {
      bootstrap();
    }
  }

  void bootstrap() {
    isBootstrapping = true;
    checkIsUserAuthenticated();
    startTimer();
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

/*  Future<void> locationPermission() async {
    if ((await Permission.location.status) == PermissionStatus.denied) {
      await Permission.location.request();
    }
  }*/

  void checkIsUserAuthenticated() async {
    context.read<FetchSystemSettingsCubit>().fetchSettings(forceRefresh: true);
  }

  Future<void> startTimer() async {
    Timer(const Duration(milliseconds: 0), () {
      isTimerCompleted = true;
      if (mounted) setState(() {});
      navigateCheck();
    });
    // Watchdog to prevent splash freeze
    Timer(const Duration(seconds: 4), () {
      if (!hasNavigated && mounted) {
        log("Watchdog Triggered: Timer:$isTimerCompleted, Settings:$isSettingsLoaded, Lang:$isLanguageLoaded");
        if (!isSettingsLoaded) isSettingsLoaded = true;
        if (!isLanguageLoaded) isLanguageLoaded = true;
        isTimerCompleted = true;
        setState(() {});
        navigateCheck();
      }
    });
  }

  void navigateCheck() {
    log("NavigateCheck: Timer:$isTimerCompleted, Settings:$isSettingsLoaded, Lang:$isLanguageLoaded, Navigated:$hasNavigated");
    if (hasNavigated) return;
    if (isTimerCompleted && isSettingsLoaded && isLanguageLoaded) {
      hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToScreen();
      });
    }
  }

  void navigateToScreen() async {
    if (context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.maintenanceMode) ==
        "1") {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
      }
    } else if (HiveUtils.isUserFirstTime() == true) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      }
    } else if (HiveUtils.isUserAuthenticated()) {
      if ((HiveUtils.getUserDetails().name == null ||
              HiveUtils.getUserDetails().name == "") ||
          (HiveUtils.getUserDetails().email == null ||
              HiveUtils.getUserDetails().email == "")) {
        // If name or email is empty, it means the user didn't complete the sign-up flow.
        // We force them to login again.
        HiveUtils.logoutUser(context, onLogout: () {}, isRedirect: false);
        Navigator.pushReplacementNamed(
          context,
          Routes.login,
        );
      } else {
        if (mounted) {
          Navigator.of(context)
              .pushReplacementNamed(Routes.main, arguments: {'from': "main"});
        }
      }
    } else {
      if (mounted) {
        HiveUtils.setUserSkip();
        Navigator.of(context)
            .pushReplacementNamed(Routes.main, arguments: {'from': "main"});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /* SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );*/

    // navigateCheck();

    return hasInternet
        ? BlocListener<FetchLanguageCubit, FetchLanguageState>(
            listener: (context, state) {
              if (state is FetchLanguageSuccess) {
                Map<String, dynamic> map = state.toMap();

                var data = map['file_name'];
                map['data'] = data;
                map.remove("file_name");

                HiveUtils.storeLanguage(map);
                context.read<LanguageCubit>().emit(LanguageLoader(map));
                isLanguageLoaded = true;
                if (mounted) {
                  setState(() {});
                  navigateCheck();
                }
              }
              if (state is FetchLanguageFailure) {
                // Handle failure: proceed with default language so app doesn't freeze
                log("FetchLanguageFailure: ${state.errorMessage}");
                isLanguageLoaded = true;
                if (mounted) {
                  setState(() {});
                  navigateCheck();
                }
              }
            },
            child: BlocListener<FetchSystemSettingsCubit,
                FetchSystemSettingsState>(
              listener: (context, state) {
                if (state is FetchSystemSettingsSuccess) {
                  Constant.isDemoModeOn = context
                      .read<FetchSystemSettingsCubit>()
                      .getSetting(SystemSetting.demoMode);

                  // ANTIGRAVITY FIX: Optimize language loading by chaining it here
                  var settings = state.settings['data'];
                  var code = settings['default_language'];

                  if (HiveUtils.getLanguage() == null ||
                      HiveUtils.getLanguage()?['data'] == null) {
                    context.read<FetchLanguageCubit>().getLanguage(code);
                  } else if (HiveUtils.isUserFirstTime() == true &&
                      code != HiveUtils.getLanguage()?['code']) {
                    context.read<FetchLanguageCubit>().getLanguage(code);
                  } else {
                    isLanguageLoaded = true;
                    if (mounted) setState(() {});
                  }

                  isSettingsLoaded = true;
                  setState(() {});
                  navigateCheck();
                }
                if (state is FetchSystemSettingsFailure) {
                  // ANTIGRAVITY FIX: Proceed even if settings fail to load to prevent hanging
                  isSettingsLoaded = true;
                  isLanguageLoaded =
                      true; // Ensure language is marked loaded if settings fail
                  setState(() {});
                  navigateCheck();
                }
              },
              child: AnnotatedRegion(
                value: SystemUiOverlayStyle(
                  statusBarColor: context.color.backgroundColor,
                ),
                child: Scaffold(
                  backgroundColor: context.color.backgroundColor,
                  // bottomNavigationBar: Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 10.0),
                  //   child: UiUtils.getSvg(AppIcons.companyLogo),
                  // ),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.center,
                        child: Padding(
                          padding: EdgeInsets.only(top: 10.0.rh(context)),
                          child: SizedBox(
                            width: 150.rw(context),
                            height: 150.rh(context),
                            child: Image.asset(AppIcons.splashLogo),
                          ),
                        ),
                      ),
                      /*
                      Padding(
                        padding: EdgeInsets.only(top: 10.0.rh(context)),
                        child: Column(
                          children: [
                            Text(AppSettings.applicationName)
                                .size(context.font.xxLarge)
                                .color(context.color.secondaryColor)
                                .centerAlign()
                                .bold(weight: FontWeight.w600),
                            Text("\"${"buyAndSellAnything".translate(context)}\"")
                                .size(context.font.smaller)
                                .color(context.color.secondaryColor)
                                .centerAlign(),
                          ],
                        ),
                      ),

                       */
                    ],
                  ),
                ),
              ),
            ),
          )
        : NoInternet(
            onRetry: () {
              setState(() {});
            },
          );
  }
}
