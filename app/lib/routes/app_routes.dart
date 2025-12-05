import 'package:flutter/material.dart';
import 'package:terafy/features/splash/splash_page.dart';
import 'package:terafy/features/login/login_page.dart';
import 'package:terafy/features/signup/simple_signup_page.dart';
import 'package:terafy/features/signup/complete_profile_page.dart';
import 'package:terafy/features/home/home_page.dart';
import 'package:terafy/features/schedule/schedule_page.dart';
import 'package:terafy/features/agenda/new_appointment_page.dart';
import 'package:terafy/features/agenda/appointment_details_page.dart';
import 'package:terafy/features/financial/financial_page.dart';
import 'package:terafy/features/financial/payment_details_page.dart';
import 'package:terafy/features/financial/reports/financial_reports_page.dart';
import 'package:terafy/features/patients/patients_list_page.dart';
import 'package:terafy/features/patients/patient_dashboard_page.dart';
import 'package:terafy/features/patients/registration/patient_registration_page.dart';
import 'package:terafy/features/sessions/sessions_history_page.dart';
import 'package:terafy/features/sessions/session_details_page.dart';
import 'package:terafy/features/sessions/new_session_page.dart';
import 'package:terafy/features/sessions/session_evolution_page.dart';
import 'package:terafy/features/profile/edit_profile_page.dart';

class AppRouter {
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String completeProfileRoute = '/complete-profile';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String scheduleRoute = '/schedule';
  static const String newAppointmentRoute = '/appointment/new';
  static const String appointmentDetailsRoute = '/appointment/details';
  static const String financialRoute = '/financial';
  static const String paymentDetailsRoute = '/payment-details';
  static const String financialReportsRoute = '/financial/reports';
  static const String patientsRoute = '/patients';
  static const String patientDashboardRoute = '/patient';
  static const String patientRegistrationRoute = '/patient/register';
  static const String sessionsHistoryRoute = '/patient/sessions';
  static const String sessionDetailsRoute = '/session/details';
  static const String newSessionRoute = '/session/new';
  static const String sessionEvolutionRoute = '/session/evolution';
  static const String editProfileRoute = '/profile/edit';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case signupRoute:
        return MaterialPageRoute(builder: (_) => const SimpleSignupPage());
      case completeProfileRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String?;
        return MaterialPageRoute(builder: (_) => CompleteProfilePage(email: email));
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case scheduleRoute:
        return MaterialPageRoute(builder: (_) => const SchedulePage());
      case newAppointmentRoute:
        return MaterialPageRoute(builder: (_) => const NewAppointmentPage());
      case appointmentDetailsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final appointmentId = args['appointmentId'] as String;
        return MaterialPageRoute(
          builder: (_) => AppointmentDetailsPage(appointmentId: appointmentId),
        );
      case financialRoute:
        return MaterialPageRoute(builder: (_) => const FinancialPage());
      case paymentDetailsRoute:
        final paymentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PaymentDetailsPage(paymentId: paymentId),
        );
      case financialReportsRoute:
        return MaterialPageRoute(builder: (_) => const FinancialReportsPage());
      case patientsRoute:
        return MaterialPageRoute(builder: (_) => const PatientsListPage());
      case patientDashboardRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final patientId = args['patientId'] as String;
        return MaterialPageRoute(
          builder: (_) => PatientDashboardPage(patientId: patientId),
        );
      case patientRegistrationRoute:
        return MaterialPageRoute(
          builder: (_) => const PatientRegistrationPage(),
        );
      case sessionsHistoryRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final patientId = args['patientId'] as String;
        final patientName = args['patientName'] as String;
        return MaterialPageRoute(
          builder: (_) => SessionsHistoryPage(
            patientId: patientId,
            patientName: patientName,
          ),
        );
      case sessionDetailsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final sessionId = args['sessionId'] as String;
        final patientName = args['patientName'] as String;
        return MaterialPageRoute(
          builder: (_) => SessionDetailsPage(
            sessionId: sessionId,
            patientName: patientName,
          ),
        );
      case newSessionRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final patientId = args['patientId'] as String;
        final patientName = args['patientName'] as String;
        return MaterialPageRoute(
          builder: (_) =>
              NewSessionPage(patientId: patientId, patientName: patientName),
        );
      case sessionEvolutionRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final sessionId = args['sessionId'] as String;
        final patientName = args['patientName'] as String;
        return MaterialPageRoute(
          builder: (_) => SessionEvolutionPage(
            sessionId: sessionId,
            patientName: patientName,
          ),
        );
      case editProfileRoute:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      // case forgotPasswordRoute:
      //   return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Nenhuma rota definida para ${settings.name}'),
            ),
          ),
        );
    }
  }
}
