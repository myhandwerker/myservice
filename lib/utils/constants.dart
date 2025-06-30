// lib/utils/constants.dart
// Düzeltmeler: AppColors.white eklendi. AppTextStyles'taki eksik 'body' ve 'subtitle' yerine
// 'bodyMedium' veya 'bodySmall' gibi tanımlı stiller kullanılacak.
// 'headline6' yerine 'headlineSmall' kullanıldı.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF1A1A2E); // Koyu lacivert
  static const Color background = Color(0xFF0F0F1B); // Daha koyu arka plan
  static const Color surface = Color(0xFF2E2E4B); // Yüzey elemanları için
  static const Color accent = Color(0xFF00ADB5); // Turkuaz mavisi
  static const Color yellowAccent = Color(0xFFFED100); // Sarı vurgu rengi
  static const Color textPrimary = Color(0xFFFFFFFF); // Beyaz metin
  static const Color textSecondary = Color(0xFFAAAAAA); // Gri metin
  static const Color error = Color(0xFFE53935); // Kırmızı hata rengi
  static const Color success = Color(0xFF66BB6A); // Yeşil başarı rengi
  static const Color warning = Color(0xFFFFB300); // Turuncu uyarı rengi
  static const Color info = Color(0xFF2196F3); // Mavi bilgi rengi
  static const Color divider = Color(0xFF424242); // Bölücü çizgiler için

  static const Color white = Colors.white; // Eksik olan 'white' rengi eklendi
}

class AppTextStyles {
  // GoogleFonts kullanımı için pubspec.yaml'a google_fonts eklenmeli
  static final TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static final TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static final TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static final TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static final TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static final TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static final TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // 'body' ve 'subtitle' yerine bu tanımlar kullanılacak
  static final TextStyle bodyLarge = GoogleFonts.openSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  static final TextStyle bodyMedium = GoogleFonts.openSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  static final TextStyle bodySmall = GoogleFonts.openSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static final TextStyle labelLarge = GoogleFonts.openSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static final TextStyle labelMedium = GoogleFonts.openSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static final TextStyle labelSmall = GoogleFonts.openSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors
        .primary, // Buton metni için genellikle primary üzerine koyu renk
  );

  static var body;

  static var subtitle;
}

class AppConstants {
  static const double padding = 16.0;
  static const double borderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
