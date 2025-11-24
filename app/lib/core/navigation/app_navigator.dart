import 'package:flutter/material.dart';

/// Global navigator key para navegação de qualquer lugar do app
/// Útil para interceptors e serviços que precisam navegar sem contexto
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
