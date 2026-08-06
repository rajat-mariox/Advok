import 'package:flutter/material.dart';

import '../AppNavigation/advocate_nav_screen.dart';
import '../AppNavigation/client_nav_screen.dart';
import '../AppNavigation/firm_nav_screen.dart';
import '../AppNavigation/student_nav_screen.dart';
import '../Screens/AdvocateRegistration/advocate_registration_models.dart';
import '../Screens/AdvocateRegistration/advocate_verification_submitted_screen.dart';
import '../Screens/AdvocateRegistration/describe_yourself_screen.dart';
import '../Screens/ChooseRoleScreen/choose_role_screen.dart';
import '../Screens/LawFirmRegistration/firm_registration_submitted_screen.dart';
import '../Screens/LawFirmRegistration/register_firm_screen.dart';
import '../Screens/LawStudentRegistration/student_verification_screen.dart';
import '../Screens/LawStudentRegistration/verification_submitted_screen.dart';
import '../Screens/RegistrationStatus/registration_rejected_screen.dart';
import 'api_service.dart';

/// Decides where the user lands after OTP verification, based on the role and
/// approval status the backend returned for this account.
class PostLoginNavigator {
  PostLoginNavigator._();

  static void navigateAfterLogin(BuildContext context) {
    final role = Session.role;
    final status = Session.status;

    // First login — no role chosen yet.
    if (role == null || status == 'new') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
      );
      return;
    }

    void goHome(Widget screen) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    }

    if (role == 'client') {
      goHome(const ClientNavScreen());
      return;
    }

    if (status == 'rejected') {
      goHome(RegistrationRejectedScreen(
        role: role,
        reason: Session.user?['rejectionReason'] as String?,
      ));
      return;
    }

    if (status == 'pending_approval') {
      switch (role) {
        case 'advocate':
          goHome(const AdvocateVerificationSubmittedScreen());
        case 'law_student':
          goHome(const VerificationSubmittedScreen());
        default:
          goHome(const FirmRegistrationSubmittedScreen());
      }
      return;
    }

    if (status == 'approved' || status == 'active') {
      switch (role) {
        case 'advocate':
          goHome(const AdvocateNavScreen());
        case 'law_student':
          goHome(const StudentNavScreen());
        default:
          goHome(const FirmNavScreen());
      }
      return;
    }

    // onboarding_required — the role was chosen earlier but the form was
    // never submitted, so restart the registration flow.
    startOnboarding(context, role);
  }

  /// Opens the start of the registration flow for [role], clearing the stack.
  static void startOnboarding(BuildContext context, String role) {
    if (role == 'advocate') {
      AdvocateOnboardingData.current.reset();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: DescribeYourselfScreen.routeName),
          builder: (_) => const DescribeYourselfScreen(),
        ),
        (route) => false,
      );
    } else if (role == 'law_student') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentVerificationScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: RegisterFirmScreen.routeName),
          builder: (_) => const RegisterFirmScreen(),
        ),
        (route) => false,
      );
    }
  }
}
