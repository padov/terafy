import 'package:terafy/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final BorderRadius borderRadius = BorderRadius.circular(5);
  static final double defaultPadding = 8;

  static final lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryText,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryText,
      error: AppColors.error,
      onError: AppColors.errorText,
      surface: AppColors.surface,
      onSurface: AppColors.surfaceText,
    ),
    // dialogTheme: DialogTheme(
    //   shape: RoundedRectangleBorder(
    //     borderRadius: borderRadius, // Definindo o raio das bordas
    //   ),
    // ),
    // textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5), // Cinza claro
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelStyle: const TextStyle(
        color: AppColors.offBlack,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelAlignment: FloatingLabelAlignment.start,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: const TextStyle(
        color: AppColors.offBlack,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 16),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFFF3F4F6), // grey[100]
      side: BorderSide(color: AppColors.lightBorderColor),
      labelStyle: TextStyle(
        color: AppColors.textColor,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorderColor,
      thickness: 1,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Color(0xFFFAFAFA), // Cinza muito claro (grey[50])
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.lightBorderColor, width: 1),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
    ),
    fontFamily: GoogleFonts.nunitoSans().fontFamily,
  );

  static TextTheme get textTheme {
    return TextTheme(
      // ==========================================
      // DISPLAY - Textos muito grandes (raramente usados)
      // ==========================================

      /// Display Large - 57px
      /// Uso: Splash screens, onboarding
      displayLarge: GoogleFonts.nunitoSans(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
        color: AppColors.primaryText,
      ),

      /// Display Medium - 45px
      /// Uso: Títulos de seções grandes
      displayMedium: GoogleFonts.nunitoSans(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
        color: AppColors.primaryText,
      ),

      /// Display Small - 36px
      /// Uso: Headers importantes
      displaySmall: GoogleFonts.nunitoSans(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
        color: AppColors.primaryText,
      ),

      // ==========================================
      // HEADLINE - Títulos principais
      // ==========================================

      /// Headline Large - 32px
      /// Uso: Título de páginas principais
      /// Exemplo: "Meus Pacientes", "Dashboard"
      headlineLarge: GoogleFonts.nunitoSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
        color: AppColors.primaryText,
      ),

      /// Headline Medium - 28px
      /// Uso: Títulos de seções dentro de páginas
      /// Exemplo: "Próximas Sessões", "Pacientes Ativos"
      headlineMedium: GoogleFonts.nunitoSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
        color: AppColors.primaryText,
      ),

      /// Headline Small - 24px
      /// Uso: Subtítulos de seções
      /// Exemplo: Títulos de cards, dialogs
      headlineSmall: GoogleFonts.nunitoSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.primaryText,
      ),

      // ==========================================
      // TITLE - Títulos menores e componentes
      // ==========================================

      /// Title Large - 22px
      /// Uso: Títulos de cards, lista de itens importantes
      /// Exemplo: Nome do paciente em card
      titleLarge: GoogleFonts.nunitoSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: AppColors.primaryText,
      ),

      /// Title Medium - 16px
      /// Uso: AppBar title, títulos de bottom sheets
      /// Exemplo: Título do AppBar
      titleMedium: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
        color: AppColors.primaryText,
      ),

      /// Title Small - 14px
      /// Uso: Títulos de seções pequenas, labels importantes
      /// Exemplo: "Dados do Paciente", labels de formulário
      titleSmall: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.primaryText,
      ),

      // ==========================================
      // BODY - Textos de corpo (mais usados)
      // ==========================================

      /// Body Large - 16px
      /// Uso: Texto principal de conteúdo, descrições longas
      /// Exemplo: Notas de sessão, anamnese
      bodyLarge: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: AppColors.primaryText,
      ),

      /// Body Medium - 14px
      /// Uso: Texto padrão do app, listas, conteúdo geral
      /// Exemplo: Lista de pacientes, informações em cards
      bodyMedium: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: AppColors.primaryText,
      ),

      /// Body Small - 12px
      /// Uso: Textos secundários, informações complementares
      /// Exemplo: Data/hora de sessão, status
      bodySmall: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.secondaryText,
      ),

      // ==========================================
      // LABEL - Textos de botões, chips, badges
      // ==========================================

      /// Label Large - 14px
      /// Uso: Botões grandes, tabs
      /// Exemplo: Texto de ElevatedButton
      labelLarge: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.primaryText,
      ),

      /// Label Medium - 12px
      /// Uso: Botões médios, chips, badges
      /// Exemplo: TextButton, Chip labels
      labelMedium: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
        color: AppColors.primaryText,
      ),

      /// Label Small - 11px
      /// Uso: Badges pequenas, labels de campos
      /// Exemplo: TextField helper text, pequenos badges
      labelSmall: GoogleFonts.nunitoSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: AppColors.secondaryText,
      ),
    );
  }

  // ============================================
  // ESTILOS CUSTOMIZADOS ADICIONAIS
  // ============================================

  /// Estilo para números/valores monetários
  static TextStyle number({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
      height: 1.2,
      color: color ?? AppColors.primaryText,
      fontFeatures: [
        FontFeature.tabularFigures(), // Números tabulares (mesmo width)
      ],
    );
  }

  /// Estilo para data/hora
  static TextStyle dateTime({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0,
      height: 1.4,
      color: color ?? AppColors.secondaryText,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }

  /// Estilo para código/monospace
  static TextStyle code({double fontSize = 13, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      // Fonte monospace
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
      color: color ?? AppColors.primaryText,
    );
  }

  /// Estilo para badges/pills
  static TextStyle badge({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.5,
      height: 1,
      color: color ?? Colors.white,
    );
  }

  /// Estilo para placeholders
  static TextStyle placeholder({double fontSize = 14, Color? color}) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
      color: color ?? AppColors.secondaryText,
      fontStyle: FontStyle.italic,
    );
  }

  /// Estilo para links
  static TextStyle link({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.25,
      height: 1.43,
      color: color ?? AppColors.secondary,
      decoration: TextDecoration.underline,
      decorationColor: color ?? AppColors.secondary,
    );
  }

  /// Estilo para texto em erro
  static TextStyle error({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.4,
      height: 1.33,
      color: AppColors.error,
    );
  }

  /// Estilo para texto de sucesso
  static TextStyle success({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.4,
      height: 1.33,
      color: AppColors.success,
    );
  }
}
