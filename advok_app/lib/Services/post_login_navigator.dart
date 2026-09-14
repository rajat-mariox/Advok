import 'package:flutter/material.dart';

import '../Routes/app_routes.dart';
import '../Screens/AdvocateRegistration/advocate_registration_models.dart';
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
      Navigator.of(context).pushNamed(AppRoutes.chooseRole);
      return;
    }

    void goHome(String route, {Object? arguments}) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(route, (r) => false, arguments: arguments);
    }

    // Suspension locks out every role, including clients.
    if (status == 'suspended') {
      goHome(
        AppRoutes.accountSuspended,
        arguments: StatusArgs(
          role: role,
          reason: Session.user?['suspensionReason'] as String?,
        ),
      );
      return;
    }

    if (role == 'client') {
      // A client who picked the role but never entered a name (e.g. closed
      // the app on the name screen) is asked for it before going home.
      final name = Session.profile?['fullName'] as String?;
      goHome(
        name == null || name.trim().isEmpty
            ? AppRoutes.clientName
            : AppRoutes.clientHome,
      );
      return;
    }

    if (status == 'rejected') {
      goHome(
        AppRoutes.registrationRejected,
        arguments: StatusArgs(
          role: role,
          reason: Session.user?['rejectionReason'] as String?,
        ),
      );
      return;
    }

    if (status == 'pending_approval') {
      switch (role) {
        case 'advocate':
          goHome(AppRoutes.advocateSubmitted);
        case 'law_student':
          goHome(AppRoutes.studentSubmitted);
        default:
          goHome(AppRoutes.firmSubmitted);
      }
      return;
    }

    if (status == 'approved' || status == 'active') {
      switch (role) {
        case 'advocate':
          goHome(AppRoutes.advocateHome);
        case 'law_student':
          goHome(AppRoutes.studentHome);
        default:
          goHome(AppRoutes.firmHome);
      }
      return;
    }

    // onboarding_required — the role was chosen earlier but the form was
    // never submitted, so restart the registration flow.
    startOnboarding(context, role);
  }

  /// Opens the start of the registration flow for [role], clearing the stack.
  static void startOnboarding(BuildContext context, String role) {
    final String route;
    if (role == 'advocate') {
      AdvocateOnboardingData.current.reset();
      route = AppRoutes.advocateRegistration;
    } else if (role == 'law_student') {
      route = AppRoutes.studentRegistration;
    } else {
      route = AppRoutes.firmRegistration;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }
}
