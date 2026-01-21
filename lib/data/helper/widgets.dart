import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:Ebozor/utils/constant.dart';

class Widgets {
  static bool isLoadingShowing = false;
  static void showLoader(BuildContext context) async {
    // if (!context.mounted) return;
    if (isLoadingShowing) {
      return;
    }
    isLoadingShowing = true;
    showDialog(
        context: Constant.navigatorKey.currentContext ?? context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (BuildContext context) {
          return AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.black.withOpacity(0),
            ),
            child: SafeArea(
              child: PopScope(
                canPop: false,
                onPopInvoked: (didPop) {
                  return;
                },
                child: Center(
                  child: UiUtils.progress(
                    normalProgressColor: context.color.territoryColor,
                  ),
                ),
                /*onWillPop: () {
                  return Future(
                    () => false,
                  );
                },*/
              ),
            ),
          );
        });
  }

  static void hideLoder(BuildContext context) {
    if (isLoadingShowing) {
      isLoadingShowing = false;
      Navigator.of(Constant.navigatorKey.currentContext ?? context).pop();
    }
  }

  static Center noDataFound(String errorMsg) {
    return Center(child: Text(errorMsg));
  }
}
