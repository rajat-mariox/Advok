import 'package:flutter/material.dart';

import '../AppNavigation/advocate_nav_screen.dart';
import '../AppNavigation/client_nav_screen.dart';
import '../AppNavigation/firm_nav_screen.dart';
import '../AppNavigation/student_nav_screen.dart';
import '../Screens/AdvocateRegistration/advocate_verification_submitted_screen.dart';
import '../Screens/AdvocateRegistration/describe_yourself_screen.dart';
import '../Screens/ChooseRoleScreen/choose_role_screen.dart';
import '../Screens/ClientNameScreen/client_name_screen.dart';
import '../Screens/LawFirmRegistration/firm_registration_submitted_screen.dart';
import '../Screens/LawFirmRegistration/register_firm_screen.dart';
import '../Screens/LawStudentRegistration/student_verification_screen.dart';
import '../Screens/LawStudentRegistration/verification_submitted_screen.dart';
import '../Screens/LoginScreen/login_screen.dart';
import '../Screens/OtpScreen/otp_screen.dart';
import '../Screens/RegistrationStatus/account_suspended_screen.dart';
import '../Screens/RegistrationStatus/registration_rejected_screen.dart';
import '../Screens/SelectCountryScreen/select_country_screen.dart';
import '../Screens/SplashScreen/splash_screen.dart';

/// Arguments for [AppRoutes.otp].
class OtpArgs {
  const OtpArgs({
    required this.country,
    required this.phoneNumber,
    this.devOtp,
  });

  final Country country;
  final String phoneNumber;
  final String? devOtp;
}

/// Arguments for [AppRoutes.registrationRejected] and
/// [AppRoutes.accountSuspended].
class StatusArgs {
  const StatusArgs({required this.role, this.reason});

  final String role;
  final String? reason;
}

/// Central route table for the app.
///
/// Every major flow screen is registered here by name; screens navigate with
/// `Navigator.pushNamed(context, AppRoutes.x)` instead of building
/// MaterialPageRoutes inline. Screens that need input declare an Args class
/// above and read it from `settings.arguments`.
class AppRoutes {
  AppRoutes._();

  // Auth + onboarding flow.
  static const String splash = '/';
  static const String selectCountry = '/select-country';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String chooseRole = '/choose-role';
  static const String clientName = '/client-name';

  // Registration entry points. Advocate/firm keep their historical names —
  // the in-flow "back to start" popUntil logic matches on them.
  static const String advocateRegistration = DescribeYourselfScreen.routeName;
  static const String firmRegistration = RegisterFirmScreen.routeName;
  static const String studentRegistration = '/register/student';

  // Post-registration status screens.
  static const String advocateSubmitted = '/submitted/advocate';
  static const String studentSubmitted = '/submitted/student';
  static const String firmSubmitted = '/submitted/firm';
  static const String registrationRejected = '/registration-rejected';
  static const String accountSuspended = '/account-suspended';

  // Role home shells (bottom-nav containers).
  static const String clientHome = '/home/client';
  static const String advocateHome = '/home/advocate';
  static const String studentHome = '/home/student';
  static const String firmHome = '/home/firm';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _page(settings, const SplashScreen());
      case selectCountry:
        return _page(settings, const SelectCountryScreen());
      case login:
        final country = settings.arguments as Country;
        return _page(settings, LoginScreen(country: country));
      case otp:
        final args = settings.arguments as OtpArgs;
        return _page(
          settings,
          OtpScreen(
            country: args.country,
            phoneNumber: args.phoneNumber,
            devOtp: args.devOtp,
          ),
        );
      case chooseRole:
        return _page(settings, const ChooseRoleScreen());
      case clientName:
        return _page(settings, const ClientNameScreen());
      case advocateRegistration:
        return _page(settings, const DescribeYourselfScreen());
      case studentRegistration:
        return _page(settings, const StudentVerificationScreen());
      case firmRegistration:
        return _page(settings, const RegisterFirmScreen());
      case advocateSubmitted:
        return _page(settings, const AdvocateVerificationSubmittedScreen());
      case studentSubmitted:
        return _page(settings, const VerificationSubmittedScreen());
      case firmSubmitted:
        return _page(settings, const FirmRegistrationSubmittedScreen());
      case registrationRejected:
        final args = settings.arguments as StatusArgs;
        return _page(
          settings,
          RegistrationRejectedScreen(role: args.role, reason: args.reason),
        );
      case accountSuspended:
        final args = settings.arguments as StatusArgs;
        return _page(
          settings,
          AccountSuspendedScreen(role: args.role, reason: args.reason),
        );
      case clientHome:
        return _page(settings, const ClientNavScreen());
      case advocateHome:
        return _page(settings, const AdvocateNavScreen());
      case studentHome:
        return _page(settings, const StudentNavScreen());
      case firmHome:
        return _page(settings, const FirmNavScreen());
      default:
        // Unknown name — restart at the splash flow rather than crashing.
        return _page(settings, const SplashScreen());
    }
  }

  static MaterialPageRoute<dynamic> _page(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute(settings: settings, builder: (_) => child);
  }
}
