import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import 'mentorship_availability_screen.dart';

const List<({String title, String subtitle})> _sessionTypes = [
  (title: '1-on-1 Video Call', subtitle: '45 min session, video call'),
  (title: 'Case Shadow', subtitle: 'Observe a real case, in-person or virtual'),
  (title: 'Weekly Mentorship', subtitle: 'Ongoing weekly check-ins'),
];

/// Step 1 of the mentorship request flow — choose a session type.
///
/// Pops with `true` when the request is completed so the mentors list can
/// mark the card as requested.
class RequestMentorshipScreen extends StatefulWidget {
  const RequestMentorshipScreen({
    super.key,
    required this.mentorName,
    required this.mentorSpecialty,
    required this.mentorImage,
  });

  final String mentorName;
  final String mentorSpecialty;
  final String mentorImage;

  @override
  State<RequestMentorshipScreen> createState() =>
      _RequestMentorshipScreenState();
}

class _RequestMentorshipScreenState extends State<RequestMentorshipScreen> {
  int? _selected;

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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressBar(currentStep: 1),
                      const SizedBox(height: 20),
                      _buildMentorCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'Choose Session Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 26 / 18,
                          letterSpacing: -0.39,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (int i = 0; i < _sessionTypes.length; i++) ...[
                        _buildSessionOption(i),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const CircleBackButton(),
          const Expanded(
            child: Text(
              'Request Mentorship',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 24 / 17,
                letterSpacing: -0.34,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Balances the back button so the title stays centered.
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProgressBar({required int currentStep}) {
    return Row(
      children: [
        for (int step = 1; step <= 3; step++) ...[
          if (step > 1) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: step <= currentStep
                    ? AppColors.textPrimary
                    : AppColors.progressTrack,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMentorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: ClipOval(
              child: Image.asset(widget.mentorImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mentorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.mentorSpecialty,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionOption(int index) {
    final option = _sessionTypes[index];
    final selected = _selected == index;
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _selected = index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 22 / 15,
                  letterSpacing: -0.23,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                option.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 19 / 13,
                  letterSpacing: -0.08,
                  color: AppColors.textGrey555,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final enabled = _selected != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
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
              onTap: enabled
                  ? () async {
                      final sent = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => MentorshipAvailabilityScreen(
                            mentorName: widget.mentorName,
                            mentorSpecialty: widget.mentorSpecialty,
                            mentorImage: widget.mentorImage,
                          ),
                        ),
                      );
                      if (sent == true && mounted) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.31,
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
    );
  }
}
