import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Services/post_login_navigator.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/Responsive/responsive.dart';

/// Shown after login when the admin has rejected the registration. Displays
/// the rejection reason and lets the user fix their details and reapply.
class RegistrationRejectedScreen extends StatelessWidget {
  const RegistrationRejectedScreen({
    super.key,
    required this.role,
    this.reason,
  });

  /// Backend role: advocate, law_student or law_firm.
  final String role;
  final String? reason;

  String get _roleIcon {
    switch (role) {
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
      case 'advocate':
        return 'Advocate';
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
                      _buildNextStepsCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildReapplyButton(context),
                    const SizedBox(height: 12),
                    const Text(
                      'Your new submission will be reviewed again by our team.',
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
                      'assets/icons/ic_clear.svg',
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
          'Registration Not Approved',
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
            'Your $_roleLabel registration could not be approved this time. '
            'Review the reason below, update your details and reapply.',
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
            'REASON FROM OUR REVIEW TEAM',
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

  Widget _buildNextStepsCard() {
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
            'WHAT TO DO NEXT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: 1.8,
              color: AppColors.textGrey,
            ),
          ),
          SizedBox(height: 12),
          _StepRow('Read the reason shared by the review team'),
          _StepRow('Correct or update the details in your form'),
          _StepRow('Submit again — reviews typically take 24–48 hrs', isLast: true),
        ],
      ),
    );
  }

  Widget _buildReapplyButton(BuildContext context) {
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
            onTap: () => PostLoginNavigator.startOnboarding(context, role),
            child: const Center(
              child: Text(
                'Update & Reapply',
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

class _StepRow extends StatelessWidget {
  const _StepRow(this.text, {this.isLast = false});

  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.textGrey555,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 19.5 / 13,
                letterSpacing: -0.08,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
