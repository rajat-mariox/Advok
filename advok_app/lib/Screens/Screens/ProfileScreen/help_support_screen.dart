import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';
import '../MessagesScreen/chat_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSupportTeamCard(),
                    const SizedBox(height: 16),
                    _HelpOption(
                      icon: 'assets/icons/ic_chat_bubble.svg',
                      title: 'Chat with Support',
                      subtitle: 'Response within 2 hours',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChatScreen(
                            name: 'ADVOK Support',
                            online: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_mail.svg',
                      title: 'Email Us',
                      subtitle: 'support@advok.app',
                      onTap: () {
                        // TODO: Open the email client.
                      },
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_phone.svg',
                      iconColor: AppColors.textPrimary,
                      title: 'Call Support',
                      subtitle: '+1 800 ADVOK HELP',
                      onTap: () {
                        // TODO: Start a phone call.
                      },
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_book_open.svg',
                      title: 'FAQ & Help Center',
                      subtitle: 'Browse common questions',
                      onTap: () {
                        // TODO: Open the FAQ & help center.
                      },
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_video.svg',
                      title: 'Video Walkthrough',
                      subtitle: 'Learn how to use ADVOK',
                      onTap: () {
                        // TODO: Play the walkthrough video.
                      },
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 24 / 16,
              letterSpacing: -0.31,
              color: AppColors.textPrimary,
            ),
          ),
          Material(
            color: AppColors.progressTrack,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_clear.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTeamCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 0.7),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.progressTrack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_user.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ADVOK Support Team',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Available Mon–Sat · 9AM–8PM EST',
                  style: TextStyle(
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
}

class _HelpOption extends StatelessWidget {
  const _HelpOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Recolors the icon when the asset's own color doesn't match the design.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.progressTrack,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 16,
                    height: 16,
                    colorFilter: iconColor != null
                        ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: -0.08,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/ic_chevron_right_grey.svg',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
