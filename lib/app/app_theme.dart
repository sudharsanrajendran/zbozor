// ignore_for_file: deprecated_member_use

import 'package:Ebozor/ui/theme/theme.dart';
import 'package:flutter/material.dart';

enum AppTheme { dark, light }

final appThemeData = {
  AppTheme.light: ThemeData(
    // scaffoldBackgroundColor: pageBackgroundColor,
    brightness: Brightness.light,
    //textTheme
    useMaterial3: false,
    fontFamily: "Manrope",

    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: territoryColor_,
      cursorColor: territoryColor_,
      selectionHandleColor: territoryColor_,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const MaterialStatePropertyAll(territoryColor_),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return territoryColor_.withOpacity(0.3);
        }
        return primaryColorDark;
      }),
    ),
    colorScheme: ColorScheme.fromSeed(
        error: errorMessageColor,
        seedColor: territoryColor_,
        brightness: Brightness.light),
    sliderTheme: SliderThemeData(
      activeTrackColor: territoryColor_,
      inactiveTrackColor: territoryColor_.withOpacity(0.2),
      thumbColor: territoryColor_,
      overlayColor: territoryColor_.withOpacity(0.1),
      trackHeight: 2.0,
      rangeThumbShape:
          const RoundRangeSliderThumbShape(enabledThumbRadius: 8.0),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
    ),
  ),
  AppTheme.dark: ThemeData(
    brightness: Brightness.dark,
    useMaterial3: false,
    fontFamily: "Manrope",
    textSelectionTheme: const TextSelectionThemeData(
      selectionHandleColor: territoryColorDark,
      selectionColor: territoryColorDark,
      cursorColor: territoryColorDark,
    ),
    colorScheme: ColorScheme.fromSeed(
        error: errorMessageColor.withOpacity(0.7),
        seedColor: territoryColorDark,
        brightness: Brightness.dark),
    sliderTheme: SliderThemeData(
      activeTrackColor: territoryColorDark,
      inactiveTrackColor: territoryColorDark.withOpacity(0.2),
      thumbColor: territoryColorDark,
      overlayColor: territoryColorDark.withOpacity(0.1),
      trackHeight: 2.0,
      rangeThumbShape:
          const RoundRangeSliderThumbShape(enabledThumbRadius: 8.0),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
    ),
    switchTheme: SwitchThemeData(
        thumbColor: const MaterialStatePropertyAll(territoryColor_),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return territoryColor_.withOpacity(0.3);
          }
          return primaryColor_.withOpacity(0.2);
        })),
  )
};
