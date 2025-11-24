import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';

class AppUtils {
  static Future<String> getVersion() async {
    // AppLogger.info('getVersion');

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    return 'v$version+$buildNumber';
  }

  static bool isDesktop() {
    // AppLogger.info('isDesktop');

    return kIsWeb ||
        (kIsWeb == false &&
            (Platform.isMacOS || Platform.isWindows || Platform.isLinux));
  }

  static void copyToClipboard(String data) async {
    // AppLogger.info('copyToClipboard');
    // AppLogger.variable('data', data);

    Clipboard.setData(ClipboardData(text: data)).then((_) {});
  }

  static String formataData(DateTime data) {
    // AppLogger.info('formataData');
    // AppLogger.variable('data', data);

    return DateFormat('dd/MM/yyyy').format(data);
  }

  static String formataDataHora(DateTime data) {
    // AppLogger.info('formataDataHora');
    // AppLogger.variable('data', data);

    return DateFormat('dd/MM/yyyy hh:mm').format(data);
  }

  static String formataDataHoraCompleta(DateTime data) {
    // AppLogger.info('formataDataHoraCompleta');
    // AppLogger.variable('data', data);

    return DateFormat('dd/MM/yyyy hh:mm:ss').format(data);
  }

  static String formataHora(DateTime data) {
    // AppLogger.info('formataHora');
    // AppLogger.variable('data', data);

    return DateFormat('kk:mm').format(data);
  }

  static String formataValor(BuildContext context, num valor, {decimal = 2}) {
    // AppLogger.info('formataValor');
    // AppLogger.variable('value', valor);
    // AppLogger.variable('decimal', decimal);

    Locale systemLocale = Localizations.localeOf(context);
    // AppLogger.variable('systemLocale', systemLocale.toString());

    NumberFormat formatter = NumberFormat.simpleCurrency(
      locale: systemLocale.toString(),
      decimalDigits: decimal,
    );
    return formatter.format(valor);
  }

  static String formataNumero(BuildContext context, num valor, {decimal = 0}) {
    // AppLogger.info('formataNumero');
    // AppLogger.variable('value', valor);
    // AppLogger.variable('decimal', decimal);

    Locale systemLocale = Localizations.localeOf(context);
    // AppLogger.variable('systemLocale', systemLocale.toString());

    NumberFormat formatter = NumberFormat.decimalPatternDigits(
      locale: systemLocale.toString(),
      decimalDigits: decimal,
    );
    return formatter.format(valor);
  }
}
