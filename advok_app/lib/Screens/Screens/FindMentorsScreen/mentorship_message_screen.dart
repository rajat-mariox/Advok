import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import 'mentorship_request_sent_screen.dart';

/// Step 3 of the mentorship request flow — optional intro message.
///
/// Pops with `true` when the request is sent so earlier steps can
/// propagate the result back to the mentors list.
class MentorshipMessageScreen extends StatefulWidget {
  const MentorshipMessageScreen({
    super.key,
    required this.mentorName,
    required this.mentorSpecialty,
    required this.mentorImage,
  });

  final String mentorName;
  final String mentorSpecialty;
  final String mentorImage;

  @override
  State<MentorshipMessageScreen> createState() =>
      _MentorshipMessageScreenState();
}

class _MentorshipMessageScreenState extends State<MentorshipMessageScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressBar(),
                      const SizedBox(height: 20),
                      const Text(
                        'Add a Message',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 26 / 18,
                          letterSpacing: -0.39,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.fillGrey,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 6,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 21 / 14,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText:
                                "Introduce yourself and describe what you'd "
                                'like to learn...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 21 / 14,
                              letterSpacing: -0.15,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildSendButton(),
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

  Widget _buildProgressBar() {
    return Row(
      children: [
        for (int step = 1; step <= 3; step++) ...[
          if (step > 1) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSendButton() {
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
            onTap: () async {
              final sent = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => MentorshipRequestSentScreen(
                    mentorName: widget.mentorName,
                    mentorSpecialty: widget.mentorSpecialty,
                    mentorImage: widget.mentorImage,
                  ),
                ),
              );
              if (sent == true && mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_send.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Send Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.31,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
