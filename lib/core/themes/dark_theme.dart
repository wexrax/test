import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
// Заготовка, не используется
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ),
);