import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Services/api_service.dart';
import '../Utils/AppColors/app_colors.dart';
import '../Utils/CountryData/country_catalog.dart';

/// Loads an admin-managed app page (Terms, Privacy, ...) from the backend and
/// shows it as a [ContentSheet]. Falls back to [fallback] if the server is
/// unreachable, so the sheet always opens with something to read.
class CmsContentSheet extends StatefulWidget {
  const CmsContentSheet({
    super.key,
    required this.slug,
    required this.fallback,
  });

  final String slug;
  final ContentSheet fallback;

  @override
  State<CmsContentSheet> createState() => _CmsContentSheetState();
}

class _CmsContentSheetState extends State<CmsContentSheet> {
  late final Future<ContentSheet> _content;

  @override
  void initState() {
    super.initState();
    _content = _load();
  }

  Future<ContentSheet> _load() async {
    final page = await ApiService.fetchCmsPage(widget.slug);
    final sections = (page['sections'] as List)
        .whereType<Map<String, dynamic>>()
        .map((s) => (
              title: (s['title'] as String?) ?? '',
              body: (s['body'] as String?) ?? '',
            ))
        .toList();
    if (sections.isEmpty) throw StateError('Empty page');
    return ContentSheet(
      title: (page['title'] as String?) ?? widget.fallback.title,
      sections: sections,
      lastUpdated: (page['lastUpdatedLabel'] as String?) ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContentSheet>(
      future: _content,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        if (snapshot.hasError) return widget.fallback;
        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(color: AppColors.white),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.textPrimary),
          ),
        );
      },
    );
  }
}

/// Full-height sheet with titled text sections, used for legal content
/// like the Privacy Policy and Terms & Conditions.
class ContentSheet extends StatelessWidget {
  const ContentSheet({
    super.key,
    required this.title,
    required this.sections,
    required this.lastUpdated,
  });

  final String title;
  final List<({String title, String body})> sections;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: AppColors.white),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderGrey)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
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
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (int i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 20),
                  Text(
                    sections[i].title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      letterSpacing: -0.08,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sections[i].body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 21.125 / 13,
                      letterSpacing: -0.08,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    lastUpdated,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.textGrey,
                    ),
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

class LogoutSheet extends StatelessWidget {
  const LogoutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 33),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.progressTrack,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_logout.svg',
                        width: 26,
                        height: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Logout?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      letterSpacing: -0.43,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You will be signed out of your account. All local data '
                    'will be preserved for your next login.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 22.75 / 14,
                      letterSpacing: -0.15,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SheetButton(
                    label: 'Cancel',
                    background: AppColors.progressTrack,
                    textColor: AppColors.textPrimary,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SheetButton(
                    label: 'Yes, Logout',
                    background: const Color(0xFF1A1A1A),
                    textColor: AppColors.white,
                    bold: true,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SheetButton extends StatelessWidget {
  const SheetButton({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
    this.bold = false,
  });

  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key});

  @override
  State<LocationSheet> createState() => LocationSheetState();
}

class LocationSheetState extends State<LocationSheet> {
  static const List<String> _cities = [
    'New York, NY',
    'Los Angeles, CA',
    'Chicago, IL',
    'Houston, TX',
    'Phoenix, AZ',
    'Philadelphia, PA',
    'San Antonio, TX',
    'San Diego, CA',
    'Dallas, TX',
    'San Jose, CA',
  ];

  String _query = '';
  String _selected = 'New York, NY';

  @override
  Widget build(BuildContext context) {
    final cities = _query.isEmpty
        ? _cities
        : _cities
              .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
              .toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Change Location',
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
                      width: 30,
                      height: 30,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/ic_clear.svg',
                          width: 14,
                          height: 14,
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
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_search.svg',
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Search city…',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final city = cities[index];
                final selected = city == _selected;
                return Material(
                  color: selected ? AppColors.fillGrey : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selected = city),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_pin.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            city,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 20 / 14,
                              letterSpacing: -0.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    onTap: () => Navigator.of(context).pop(_selected),
                    child: const Center(
                      child: Text(
                        'Save Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: -0.23,
                          color: AppColors.white,
                        ),
                      ),
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
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.progressTrack,
              shape: BoxShape.circle,
            ),
            child: Center(child: SvgPicture.asset(icon, width: 15, height: 15)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.06,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
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

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.iconBackground,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Shown instead of the default chevron (e.g. the notifications toggle).
  final Widget? trailing;

  /// Recolors the icon when the asset's own color doesn't match the design.
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground ?? AppColors.progressTrack,
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                SvgPicture.asset(
                  'assets/icons/ic_chevron_right_grey.svg',
                  width: 15,
                  height: 15,
                ),
          ],
        ),
      ),
    );
  }
}

class RateSheet extends StatefulWidget {
  const RateSheet({super.key});

  @override
  State<RateSheet> createState() => RateSheetState();
}

class RateSheetState extends State<RateSheet> {
  int _rating = 5;
  bool _submitted = false;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: EdgeInsets.fromLTRB(
        21,
        21,
        21,
        33 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rate ADVOK',
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
                    width: 30,
                    height: 30,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_clear.svg',
                        width: 14,
                        height: 14,
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
          const SizedBox(height: 16),
          if (_submitted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_verified.svg',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thanks for your feedback!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: -0.23,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your review helps us improve ADVOK for everyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How would you rate your experience?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: AppColors.textGrey555,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: SvgPicture.asset(
                      'assets/icons/ic_star.svg',
                      width: 36,
                      height: 36,
                      colorFilter: ColorFilter.mode(
                        i < _rating
                            ? AppColors.textPrimary
                            : AppColors.borderGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Write a review (optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
                color: AppColors.textGrey555,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 93,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey, width: 0.7),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 14,
                  height: 22.4 / 14,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Tell us what you think…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    height: 22.4 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
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
                    onTap: () {
                      // TODO: Submit the rating to the backend.
                      setState(() => _submitted = true);
                    },
                    child: const Center(
                      child: Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 22.5 / 15,
                          letterSpacing: -0.23,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key});

  @override
  State<ShareSheet> createState() => ShareSheetState();
}

class ShareSheetState extends State<ShareSheet> {
  static const String _inviteLink = 'https://advok.app/invite/alex2025';
  static const List<({String icon, String label})> _options = [
    (icon: 'assets/icons/ic_whatsapp.svg', label: 'WhatsApp'),
    (icon: 'assets/icons/ic_twitter.svg', label: 'Twitter'),
    (icon: 'assets/icons/ic_mail.svg', label: 'Email'),
    (icon: 'assets/icons/ic_copy_link.svg', label: 'Copy Link'),
  ];

  bool _copied = false;

  Future<void> _copyLink() async {
    await Clipboard.setData(const ClipboardData(text: _inviteLink));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 33),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share ADVOK',
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
                    width: 30,
                    height: 30,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_clear.svg',
                        width: 14,
                        height: 14,
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
          const SizedBox(height: 16),
          const Text(
            'Invite your friends and colleagues to ADVOK.',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final option in _options)
                _buildShareOption(option.icon, option.label),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 46,
            padding: const EdgeInsets.only(left: 17, right: 9),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey, width: 0.7),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    _inviteLink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _copyLink,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        _copied ? 'Copied' : 'Copy',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: 0.06,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(String icon, String label) {
    return GestureDetector(
      onTap: label == 'Copy Link'
          ? _copyLink
          : () {
              // TODO: Share via the selected channel.
            },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey, width: 0.7),
            ),
            child: Center(child: SvgPicture.asset(icon, width: 22, height: 22)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 0.12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutSheet extends StatefulWidget {
  const AboutSheet({super.key});

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  // App properties stay local — they describe this build, not CMS content.
  static const List<({String label, String value})> _facts = [
    (label: 'Version', value: '2.1.0 (Build 241)'),
    (label: 'Platform', value: 'iOS & Android'),
    (label: 'Developed by', value: 'ADVOK Technologies Inc.'),
    (label: 'Headquarters', value: 'New York, NY, USA'),
    (label: 'Support Email', value: 'support@advok.app'),
    (label: 'Website', value: 'www.advok.app'),
  ];

  /// Admin-managed "About ADVOK" sections from the CMS (empty until loaded;
  /// stays empty offline so the sheet still opens with the app facts).
  List<({String title, String body})> _sections = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await ApiService.fetchCmsPage('about-us');
      final sections = (page['sections'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => (
                title: (s['title'] as String?) ?? '',
                body: (s['body'] as String?) ?? '',
              ))
          .where((s) => s.body.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() => _sections = sections);
    } catch (_) {
      // Server unreachable — keep the static sheet.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 33),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'About ADVOK',
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
                    width: 30,
                    height: 30,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_clear.svg',
                        width: 14,
                        height: 14,
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
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ADVOK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 33 / 22,
                            letterSpacing: -0.81,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'LEGAL PLATFORM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16 / 12,
                            letterSpacing: 1.2,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Admin-managed "About ADVOK" content from the CMS.
                  for (final section in _sections) ...[
                    const SizedBox(height: 16),
                    if (section.title.isNotEmpty) ...[
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: -0.08,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      section.body,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 21 / 13,
                        letterSpacing: -0.08,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (int i = 0; i < _facts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fillGrey,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _facts[i].label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 18 / 12,
                              color: AppColors.textGrey555,
                            ),
                          ),
                          Text(
                            _facts[i].value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 18 / 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '© 2025 ADVOK Technologies Inc. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      letterSpacing: 0.06,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RolePickerSheet extends StatefulWidget {
  const RolePickerSheet({super.key, this.currentRoleIndex = 0});

  final int currentRoleIndex;

  @override
  State<RolePickerSheet> createState() => RolePickerSheetState();
}

class RolePickerSheetState extends State<RolePickerSheet> {
  static List<({String icon, String title, String subtitle})> get _roles => [
    (
      icon: 'assets/icons/ic_role_client.svg',
      title: 'Client',
      subtitle: 'Find & consult lawyers',
    ),
    (
      icon: 'assets/icons/ic_role_advocate.svg',
      title: CountryCatalog.terms.lawyerSingular,
      subtitle: 'Manage cases & clients',
    ),
    (
      icon: 'assets/icons/ic_role_student.svg',
      title: 'Law Student',
      subtitle: 'Learn & connect',
    ),
    (
      icon: 'assets/icons/ic_role_firm.svg',
      title: 'Law Firm',
      subtitle: 'Run your practice',
    ),
  ];

  late int _selected = widget.currentRoleIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 33),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Switch User Type',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 25.5 / 17,
                      letterSpacing: -0.43,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select your role to switch',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ],
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
                        width: 16,
                        height: 16,
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
          const SizedBox(height: 16),
          for (int i = 0; i < _roles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildRoleOption(i),
          ],
          const SizedBox(height: 16),
          SizedBox(
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
                  onTap: () => Navigator.of(context).pop(_selected),
                  child: Center(
                    child: Text(
                      'Continue as ${_roles[_selected].title}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 22.5 / 15,
                        letterSpacing: -0.23,
                        color: AppColors.white,
                      ),
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

  Widget _buildRoleOption(int index) {
    final role = _roles[index];
    final selected = index == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.progressTrack : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.borderGrey,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey, width: 0.7),
              ),
              child: Center(
                child: SvgPicture.asset(role.icon, width: 20, height: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        role.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: -0.08,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (index == widget.currentRoleIndex) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.17,
                              color: AppColors.textGrey555,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.subtitle,
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
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.textPrimary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.borderGrey,
                  width: 1.4,
                ),
              ),
              child: selected
                  ? Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_check.svg',
                        width: 11,
                        height: 11,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({super.key});

  @override
  State<DeleteAccountSheet> createState() => DeleteAccountSheetState();
}

class DeleteAccountSheetState extends State<DeleteAccountSheet> {
  static const List<String> _reasons = [
    'Found a better service',
    'Privacy concerns',
    'Too expensive',
    'Not using anymore',
    'Other',
  ];

  int? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 33),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    'assets/icons/ic_trash.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Delete Account?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 25.5 / 17,
                      letterSpacing: -0.43,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'This action cannot be undone',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Deleting your account will permanently remove all your data '
            'including case history, messages, bookings, and documents.',
            style: TextStyle(
              fontSize: 14,
              height: 22.75 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reason for leaving (optional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 18 / 12,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _reasons.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _buildReasonOption(i),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Cancel',
                  background: AppColors.progressTrack,
                  textColor: AppColors.textPrimary,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Continue',
                  background: const Color(0xFF1A1A1A),
                  textColor: AppColors.white,
                  onTap: () {
                    // TODO: Delete the account once the backend exists.
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(int index) {
    final selected = index == _selectedReason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 0.7,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.borderGrey,
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
            const SizedBox(width: 12),
            Text(
              _reasons[index],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: -0.08,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color background,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
