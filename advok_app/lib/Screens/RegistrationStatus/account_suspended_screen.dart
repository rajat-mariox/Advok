import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Services/api_service.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import '../../Utils/Responsive/responsive.dart';
import '../SplashScreen/splash_screen.dart';

/// Shown after login when the admin has suspended this account (any role).
/// The user is locked out until the suspension is lifted from the admin panel.
class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({
    super.key,
    required this.role,
    this.reason,
  });

  /// Backend role: client, advocate, law_student or law_firm.
  final String role;
  final String? reason;

  String get _roleIcon {
    switch (role) {
      case 'client':
        return 'assets/icons/ic_role_client.svg';
      case 'advocate':
        return 'assets/icons/ic_role_advocate.svg';
      case 'law_student':
        return 'assets/icons/ic_role_student.svg';
      default:
        return 'assets/icons/ic_role_firm.svg';
    }
  }

  String get _roleLabel {
    switch (role) {
      case 'client':
        return 'Client';
      case 'advocate':
        return CountryCatalog.terms.lawyerSingular;
      case 'law_student':
        return 'Law Student';
      default:
        return 'Law Firm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(context),
                      const SizedBox(height: 28),
                      _buildReasonCard(),
                      const SizedBox(height: 16),
                      _buildSupportCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildSignOutButton(context),
                    const SizedBox(height: 12),
                    const Text(
                      'Access is restored automatically once the suspension is lifted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 16 / 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: context.rs(116),
          height: context.rs(116),
          child: Stack(
            children: [
              Container(
                width: context.rs(116),
                height: context.rs(116),
                decoration: const BoxDecoration(
                  color: AppColors.fillGrey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(_roleIcon, width: 44, height: 44),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_lock.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Account Suspended',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 32 / 24,
            letterSpacing: -0.59,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Your $_roleLabel account has been temporarily suspended by our '
            'team and is not accessible right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 21 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REASON FROM OUR TEAM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: 1.8,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (reason == null || reason!.isEmpty) ? 'Not specified.' : reason!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 21 / 14,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'THINK THIS IS A MISTAKE?',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: 1.8,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Contact our support team at support@advok.app and include your '
            'registered phone number. We usually respond within 24 hours.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 19.5 / 13,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Session.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Center(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.31,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
