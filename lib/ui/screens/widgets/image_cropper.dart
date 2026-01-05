import 'package:Ebozor/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:Ebozor/utils/extensions/extensions.dart';

//This will open image crop SDK
class CropImage {
  static BuildContext? _context;

  static void init(BuildContext context) {
    _context = context;
  }

  static Future<CroppedFile?>? crop({required String filePath}) async {
    if (_context == null) {
      return null;
    }

    // Force system UI to be visible to prevent safe area overlap
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: _context!.color.territoryColor,
          statusBarColor: Colors.black, // Set to black to avoid overlap/merging
          toolbarWidgetColor: Colors.white,
          hideBottomControls: false,
          activeControlsWidgetColor: _context!.color.territoryColor,
          lockAspectRatio: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        WebUiSettings(
          context: _context!,
        ),
      ],
    );

    return croppedFile;
  }
}
