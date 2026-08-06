import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../CommonWidgets/circle_back_button.dart';
import '../../Utils/AppColors/app_colors.dart';

/// Shared chrome for the 2-step law-firm registration flow: back button +
/// segmented progress header with a "Step n of 2" caption, scrollable body
/// and the gradient Continue footer.
class FirmStepScaffold extends StatelessWidget {
  const FirmStepScaffold({
    super.key,
    required this.currentStep,
    required this.children,
    required this.continueEnabled,
    this.onContinue,
    this.continueLabel = 'Continue',
  });

  static const int totalSteps = 2;

  /// 1-based step shown by the progress bar and caption.
  final int currentStep;
  final List<Widget> children;
  final bool continueEnabled;
  final VoidCallback? onContinue;
  final String continueLabel;

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
              _buildProgressHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: children,
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const CircleBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (int i = 0; i < totalSteps; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < currentStep
                                ? AppColors.textPrimary
                                : AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Step $currentStep of $totalSteps',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 16 / 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Opacity(
        opacity: continueEnabled ? 1 : 0.4,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: continueEnabled ? onContinue : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      continueLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.23,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SvgPicture.asset(
                      'assets/icons/ic_chevron_right.svg',
                      width: 18,
                      height: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
