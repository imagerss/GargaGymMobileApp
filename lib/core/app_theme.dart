import 'package:flutter/material.dart';

class AppColors {
  static const slate50 = Color(0xfff8fafc);
  static const slate100 = Color(0xfff1f5f9);
  static const slate200 = Color(0xffe2e8f0);
  static const slate300 = Color(0xffcbd5e1);
  static const slate400 = Color(0xff94a3b8);
  static const slate500 = Color(0xff64748b);
  static const slate600 = Color(0xff475569);
  static const slate700 = Color(0xff334155);
  static const slate900 = Color(0xff0f172a);
  static const slate950 = Color(0xff020617);
  static const danger = Color(0xffdc2626);
  static const dangerSoft = Color(0xfffee2e2);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.slate900,
      brightness: Brightness.light,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.slate100,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.slate900,
      displayColor: AppColors.slate950,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.slate900, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.slate900,
        side: const BorderSide(color: AppColors.slate200),
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.slate900,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
  );
}
