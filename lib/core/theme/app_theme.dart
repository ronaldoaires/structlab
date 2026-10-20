import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';

/// Central theme: widgets inherit from here instead of styling by hand.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandBlue,
    brightness: Brightness.light,
  ).copyWith(
    primary: brandBlue,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: ink,
    onSurfaceVariant: inkMuted,
    outlineVariant: lineColor,
    error: danger,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: shape12,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: shape12,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: brandTint,
      side: const BorderSide(color: lineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: ink),
      checkmarkColor: brandBlue,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: ink),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
      shape: shape12,
    ),
    inputDecorationTheme: InputDecorationTheme(
      helperStyle: const TextStyle(fontSize: 12, color: inkMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandBlue, width: 2),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: shape12,
    ),
  );
}