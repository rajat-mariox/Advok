import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../AppNavigation/student_nav_screen.dart';
import '../../Services/approval_status_poller.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/Responsive/responsive.dart';
import '../RegistrationStatus/registration_rejected_screen.dart';

/// Shown after the student verification form is submitted. Polls the backend
/// and keeps the dashboard locked until the admin verifies the ID; a
/// rejection routes to the rejection screen with the admin's reason.
class VerificationSubmittedScreen extends StatefulWidget {
  const VerificationSubmittedScreen({super.key});

  @override
  State<VerificationSubmittedScreen> createState() =>
      _VerificationSubmittedScreenState();
}

class _VerificationSubmittedScreenState
    extends State<VerificationSubmittedScreen> {
  String _status = 'pending_approval';
  late final ApprovalStatusPoller _poller;

  bool get _approved => _status == 'approved';

  @override
  void initState() {
    super.initState();
    _poller = ApprovalStatusPoller(onChanged: _onStatusChanged);
    _poller.start();
  }

  @override
  void dispose() {
    _poller.stop();
    super.dispose();
  }

  void _onStatusChanged(String status, String? rejectionReason) {
    if (!mounted) return;
    if (status == 'rejected') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RegistrationRejectedScreen(
            role: 'law_student',
            reason: rejectionReason,
          ),
        ),
        (route) => false,
      );
      return;
    }
    setState(() => _status = status);
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
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildAccessCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildDashboardButton(context),
                    const SizedBox(height: 12),
                    Text(
                      _approved
                          ? 'Your student ID is verified. Happy learning!'
                          : 'This screen unlocks automatically once your ID is verified.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
        Container(
          width: context.rs(116),
          height: context.rs(116),
          decoration: const BoxDecoration(
            color: AppColors.fillGrey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/ic_role_student.svg',
              width: 44,
              height: 44,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _approved ? 'Verification Complete!' : 'Verification Submitted!',
          textAlign: TextAlign.center,
          style: const TextStyle(
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
            _approved
                ? 'Your college ID has been verified. All student resources '
                    'and learning tools are now unlocked.'
                : "Your profile has been sent for verification. Once approved, "
                    "you'll gain access to student resources and exclusive learning tools.",
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

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TimelineDot(style: _DotStyle.header),
              const SizedBox(width: 12),
              Text(
                _approved ? 'Verified' : 'Pending Verification',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 22 / 15,
                  letterSpacing: -0.23,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _TimelineStep(
            title: 'Submitted',
            trailing: 'Done',
            style: _DotStyle.done,
          ),
          _TimelineStep(
            title: 'Under Review',
            trailing: _approved ? 'Done' : 'Typically 2–4 hrs',
            style: _approved ? _DotStyle.done : _DotStyle.active,
          ),
          _TimelineStep(
            title: 'ID Verified',
            trailing: _approved ? 'Done' : '—',
            style: _approved ? _DotStyle.done : _DotStyle.upcoming,
          ),
          _TimelineStep(
            title: 'Access Granted',
            trailing: _approved ? 'Done' : '—',
            style: _approved ? _DotStyle.done : _DotStyle.upcoming,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionCaption('AVAILABLE WHILE PENDING'),
          const SizedBox(height: 12),
          const _AccessRow('Cases to Read', unlocked: true),
          const _AccessRow('AI Brief (Basic)', unlocked: true),
          const _AccessRow('Legal News', unlocked: true),
          const _AccessRow('Daily Updates', unlocked: true),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          const _SectionCaption('UNLOCKS AFTER VERIFICATION'),
          const SizedBox(height: 12),
          _AccessRow('Mentorship Access', unlocked: _approved),
          _AccessRow('Internship Portal', unlocked: _approved),
          _AccessRow('Senior Advocate Queries', unlocked: _approved),
          _AccessRow('Certificates', unlocked: _approved, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return Opacity(
      opacity: _approved ? 1 : 0.4,
      child: SizedBox(
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
              onTap: _approved
                  ? () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const StudentNavScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  : null,
              child: Center(
                child: Text(
                  _approved ? 'Go to Dashboard' : 'Waiting for Verification…',
                  style: const TextStyle(
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
      ),
    );
  }
}

enum _DotStyle { header, done, active, upcoming }

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.style});

  final _DotStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _DotStyle.header:
        return Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.textGrey555,
            shape: BoxShape.circle,
          ),
        );
      case _DotStyle.done:
        return Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
        );
      case _DotStyle.active:
        return Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: AppColors.textGrey555,
            shape: BoxShape.circle,
          ),
        );
      case _DotStyle.upcoming:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderGrey, width: 1.4),
          ),
        );
    }
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.trailing,
    required this.style,
    this.isLast = false,
  });

  final String title;
  final String trailing;
  final _DotStyle style;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final upcoming = style == _DotStyle.upcoming;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 4),
                _TimelineDot(style: style),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4, bottom: 2),
                      color: AppColors.progressTrack,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color:
                      upcoming ? AppColors.textGrey : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 11,
              height: 20 / 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 1.8,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow(this.title, {required this.unlocked, this.isLast = false});

  final String title;
  final bool unlocked;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          if (unlocked)
            SvgPicture.asset(
              'assets/icons/ic_check_circle_dark.svg',
              width: 15,
              height: 15,
            )
          else
            SvgPicture.asset(
              'assets/icons/ic_lock.svg',
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                AppColors.textGrey,
                BlendMode.srcIn,
              ),
            ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 19.5 / 13,
              letterSpacing: -0.08,
              color: unlocked ? AppColors.textPrimary : AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
