import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/Responsive/responsive.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'select_purpose_screen.dart';

class DescribeYourselfScreen extends StatefulWidget {
  const DescribeYourselfScreen({super.key});

  static const String routeName = 'advocate_describe';

  @override
  State<DescribeYourselfScreen> createState() => _DescribeYourselfScreenState();
}

class _DescribeYourselfScreenState extends State<DescribeYourselfScreen> {
  AdvocateType? _selected;

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 1,
      continueEnabled: _selected != null,
      onContinue: () {
        AdvocateOnboardingData.current.advocateType = _selected;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SelectPurposeScreen(advocateType: _selected!),
          ),
        );
      },
      children: [
        _buildRegistrationBanner(),
        const SizedBox(height: 24),
        const Text(
          'STEP 1 OF 5',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: 3.06,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Describe Yourself',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 32.5 / 24,
            letterSpacing: -0.43,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose your professional role to personalise your experience.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        _AdvocateTypeCard(
          title: 'Junior Advocate',
          subtitle: 'Less than 10 years of practice',
          note: 'You will be guided by senior advocates',
          selected: _selected == AdvocateType.junior,
          onTap: () => setState(() => _selected = AdvocateType.junior),
        ),
        const SizedBox(height: 12),
        _AdvocateTypeCard(
          title: 'Senior Advocate',
          subtitle: '10+ years of practice',
          note: 'Designated by the High Court or Supreme Court',
          selected: _selected == AdvocateType.senior,
          onTap: () => setState(() => _selected = AdvocateType.senior),
        ),
      ],
    );
  }

  Widget _buildRegistrationBanner() {
    return Container(
      height: context.rs(110),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.progressTrack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_briefcase.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Advocate Registration',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

}

class _AdvocateTypeCard extends StatelessWidget {
  const _AdvocateTypeCard({
    required this.title,
    required this.subtitle,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.white.withValues(alpha: 0.15)
                          : AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_award.svg',
                        width: 22,
                        height: 22,
                        colorFilter: selected
                            ? const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected ? AppColors.white : Colors.transparent,
                      border: selected
                          ? null
                          : Border.all(
                              color: AppColors.borderGrey,
                              width: 1.4,
                            ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 24 / 16,
                  letterSpacing: -0.31,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 13,
                  letterSpacing: -0.08,
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.75)
                      : AppColors.textGrey555,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 12,
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.55)
                      : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
