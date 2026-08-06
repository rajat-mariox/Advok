import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';
import '../MessagesScreen/chat_screen.dart';

/// Final screen of the mentorship request flow — confirmation.
///
/// Pops with `true` so the earlier steps unwind and the mentors list can
/// mark the card as requested.
class MentorshipRequestSentScreen extends StatelessWidget {
  const MentorshipRequestSentScreen({
    super.key,
    required this.mentorName,
    required this.mentorSpecialty,
    required this.mentorImage,
  });

  final String mentorName;
  final String mentorSpecialty;
  final String mentorImage;

  String get _firstName => mentorName.split(' ').first;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_check_circle_dark.svg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Request Sent!',
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
                    'Your mentorship request has been sent to $mentorName. '
                    "They'll respond within 24 hours.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 21 / 14,
                      letterSpacing: -0.15,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.fillGrey,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    children: [
                      Text(
                        mentorName,
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
                        mentorSpecialty,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildMessageButton(context),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Back to Mentors',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageButton(BuildContext context) {
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
          borderRadius: BorderRadius.circular(100),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    name: mentorName,
                    image: mentorImage,
                    online: true,
                    specialty: mentorSpecialty,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_chat_bubble.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Message $_firstName',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.23,
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
