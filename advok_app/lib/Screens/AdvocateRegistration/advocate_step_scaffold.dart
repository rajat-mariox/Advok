import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utils/AppColors/app_colors.dart';

/// Shared chrome for the 5-step advocate registration flow: back button +
/// segmented progress header, scrollable body and the gradient Continue
/// footer.
class AdvocateStepScaffold extends StatelessWidget {
  const AdvocateStepScaffold({
    super.key,
    required this.currentStep,
    required this.children,
    required this.continueEnabled,
    this.onContinue,
    this.continueLabel = 'Continue',
    this.continueSubLabel,
  });

  static const int totalSteps = 5;

  /// 1-based step shown by the progress bar and counter.
  final int currentStep;
  final List<Widget> children;
  final bool continueEnabled;
  final VoidCallback? onContinue;
  final String continueLabel;

  /// When set, the footer button shows this second line and drops the
  /// chevron (used by the final "Finish Setup" step).
  final String? continueSubLabel;

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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Row(
        children: [
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_arrow_back.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
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
          ),
          const SizedBox(width: 12),
          Text(
            '$currentStep/$totalSteps',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 16 / 12,
              color: AppColors.textGrey,
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
          height: continueSubLabel == null ? 52 : 56,
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
                child: continueSubLabel == null
                    ? Row(
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
                      )
                    : Column(
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
                          const SizedBox(height: 2),
                          Text(
                            continueSubLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              letterSpacing: 0.06,
                              color: AppColors.white.withValues(alpha: 0.75),
                            ),
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
