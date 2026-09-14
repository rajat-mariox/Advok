import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../CommonWidgets/profile_sheets.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import 'support_tickets_screen.dart';

/// Help & Support hub for every role. Contact details come from the admin
/// panel (Settings → Help & Support Contact); the FAQ is the admin-editable
/// `help-center` CMS page; Contact Support raises a ticket the admin answers
/// from the Support page.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Defaults mirror the backend seed so the screen is usable offline.
  String _email = 'support@advok.app';
  String _phone = '+1 800 238 6543';
  String _hours = 'Available Mon–Sat · 9AM–8PM EST';
  String _responseNote = 'Response within 2 hours';
  int _unreadReplies = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final contact = await ApiService.fetchSupportContact();
      final tickets = await ApiService.fetchSupportTickets();
      if (!mounted) return;
      setState(() {
        _email = (contact['email'] as String?)?.trim().isNotEmpty == true
            ? (contact['email'] as String).trim()
            : _email;
        _phone = (contact['phone'] as String?)?.trim().isNotEmpty == true
            ? (contact['phone'] as String).trim()
            : _phone;
        _hours = (contact['hours'] as String?)?.trim().isNotEmpty == true
            ? (contact['hours'] as String).trim()
            : _hours;
        _responseNote =
            (contact['responseNote'] as String?)?.trim().isNotEmpty == true
                ? (contact['responseNote'] as String).trim()
                : _responseNote;
        _unreadReplies = tickets.unread;
      });
    } on ApiException {
      // Keep the defaults; the ticket screen surfaces connection errors.
    }
  }

  Future<void> _launch(Uri uri, String failure) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  Future<void> _emailSupport() => _launch(
        Uri(
          scheme: 'mailto',
          path: _email,
          queryParameters: {'subject': 'ADVOK support request'},
        ),
        'No email app found. Write to $_email.',
      );

  Future<void> _callSupport() => _launch(
        Uri(scheme: 'tel', path: _phone.replaceAll(RegExp(r'[^0-9+]'), '')),
        'Calling is not available on this device. Dial $_phone.',
      );

  Future<void> _openTickets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
    );
    await _load();
  }

  Future<void> _openFaq() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const CmsContentSheet(
        slug: 'help-center',
        fallback: ContentSheet(
          title: 'FAQ & Help Center',
          sections: [
            (
              title: 'How do I book a consultation?',
              body:
                  'Open an attorney\'s profile and tap Book Appointment. '
                  'Choose the consultation type, date and time, then '
                  'confirm. You are notified once the attorney responds.',
            ),
            (
              title: 'Why is my account still pending?',
              body:
                  'Attorney, law student and law firm accounts are reviewed '
                  'by our team. This usually takes 1–2 business days.',
            ),
            (
              title: 'Still need help?',
              body:
                  'Use Contact Support on the Help & Support screen to raise '
                  'a ticket. Our team replies inside the app.',
            ),
          ],
          lastUpdated: 'Last updated: August 25, 2026',
        ),
      ),
    );
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
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSupportTeamCard(),
                    const SizedBox(height: 16),
                    _HelpOption(
                      icon: 'assets/icons/ic_chat_bubble.svg',
                      title: 'Contact Support',
                      subtitle: _unreadReplies > 0
                          ? '$_unreadReplies new '
                              '${_unreadReplies == 1 ? 'reply' : 'replies'} '
                              'from support'
                          : _responseNote,
                      badge: _unreadReplies,
                      onTap: _openTickets,
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_mail.svg',
                      title: 'Email Us',
                      subtitle: _email,
                      onTap: _emailSupport,
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_phone.svg',
                      iconColor: AppColors.textPrimary,
                      title: 'Call Support',
                      subtitle: _phone,
                      onTap: _callSupport,
                    ),
                    const SizedBox(height: 8),
                    _HelpOption(
                      icon: 'assets/icons/ic_book_open.svg',
                      title: 'FAQ & Help Center',
                      subtitle: 'Browse common questions',
                      onTap: _openFaq,
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
              children: [
                const Text(
                  'ADVOK Support Team',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hours,
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
}

class _HelpOption extends StatelessWidget {
  const _HelpOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.badge = 0,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Recolors the icon when the asset's own color doesn't match the design.
  final Color? iconColor;

  /// Unread count shown as a pill before the chevron (0 hides it).
  final int badge;

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              if (badge > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
