import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/Responsive/responsive.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key, this.onProfileTap});

  /// Called when the header avatar is tapped. Used by the nav shell to
  /// switch to the Profile tab.
  final VoidCallback? onProfileTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildSearchBar(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildAiBanner(),
          ),
          _SectionHeader(title: 'Legal Categories', onSeeAll: () {}),
          const SizedBox(height: 12),
          _buildCategories(),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Top Advocates', onSeeAll: () {}),
          const SizedBox(height: 12),
          _buildAdvocates(context),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: -0.08,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Upcoming Appointments',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: -0.08,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAppointments(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
                Text(
                  Session.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 28 / 20,
                    letterSpacing: -0.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.fillGrey,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_bell.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 7,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGrey, width: 1.4),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/img_avatar_alex.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_search.svg', width: 17, height: 17),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Search lawyers, legal topics...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.15,
                color: AppColors.textGrey,
              ),
            ),
          ),
          SvgPicture.asset('assets/icons/ic_mic.svg', width: 17, height: 17),
        ],
      ),
    );
  }

  Widget _buildAiBanner() {
    return Container(
      height: 93,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.6, 1],
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.21),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AI-POWERED · FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 0.62,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Instant Legal Answers',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: -0.23,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ask ADVOK AI anything legal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: Color(0xFFB9B9B9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.21),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_bot.svg',
                width: 28,
                height: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    const categories = [
      _CategoryData('Criminal', 'assets/icons/ic_cat_criminal.svg',
          Color(0xFF1A1A1A)),
      _CategoryData('Civil', 'assets/icons/ic_cat_civil.svg',
          Color(0xFF333333)),
      _CategoryData('Corporate', 'assets/icons/ic_cat_corporate.svg',
          Color(0xFF0A0A0A)),
      _CategoryData('Family', 'assets/icons/ic_cat_family.svg',
          Color(0xFF0A0A0A)),
      _CategoryData('Property', 'assets/icons/ic_cat_property.svg',
          Color(0xFF333333)),
      _CategoryData('Immigration', 'assets/icons/ic_cat_immigration.svg',
          Color(0xFF444444)),
      _CategoryData('Employment', 'assets/icons/ic_cat_employment.svg',
          Color(0xFF555555)),
      _CategoryData('Cyber', 'assets/icons/ic_cat_cyber.svg',
          Color(0xFF06B6D4)),
    ];
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _IconTile(
            label: category.label,
            icon: category.icon,
            tint: category.tint,
            iconSize: 24,
            borderAlpha: 0.19,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AdvocateListScreen(title: '${category.label} Law'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdvocates(BuildContext context) {
    const advocates = <_AdvocateData>[];
    if (advocates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _EmptyState(
          icon: 'assets/icons/ic_search.svg',
          title: 'No advocates yet',
          message:
              'Advocates will appear here once verified advocates join the platform.',
        ),
      );
    }
    return SizedBox(
      height: context.rs(234),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: advocates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _AdvocateCard(advocates[index]),
      ),
    );
  }

  Widget _buildQuickActions() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconTile(
            label: 'Book',
            icon: 'assets/icons/ic_qa_book.svg',
            tint: Color(0xFF0A0A0A),
            iconSize: 24,
            borderAlpha: 0.16,
          ),
          _IconTile(
            label: 'Chat',
            icon: 'assets/icons/ic_qa_chat.svg',
            tint: Color(0xFF333333),
            iconSize: 24,
            borderAlpha: 0.16,
          ),
          _IconTile(
            label: 'Docs',
            icon: 'assets/icons/ic_qa_docs.svg',
            tint: Color(0xFF333333),
            iconSize: 24,
            borderAlpha: 0.16,
          ),
          _IconTile(
            label: 'AI Help',
            icon: 'assets/icons/ic_qa_ai.svg',
            tint: Color(0xFF444444),
            iconSize: 24,
            borderAlpha: 0.16,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointments() {
    const appointments = <_AppointmentRow>[];
    if (appointments.isEmpty) {
      return const _EmptyState(
        icon: 'assets/icons/ic_clock.svg',
        title: 'No upcoming appointments',
        message: 'Appointments you book will appear here.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: const Column(children: appointments),
    );
  }
}

class _CategoryData {
  const _CategoryData(this.label, this.icon, this.tint);

  final String label;
  final String icon;
  final Color tint;
}

class _AdvocateData {
  const _AdvocateData({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.price,
    required this.image,
  });

  final String name;
  final String specialty;
  final String experience;
  final String? rating;
  final String price;
  final String image;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final String icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.fillGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(icon, width: 24, height: 24),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square tinted icon tile with a label below, used for categories and
/// quick actions.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconSize,
    required this.borderAlpha,
    this.onTap,
  });

  final String label;
  final String icon;
  final Color tint;
  final double iconSize;
  final double borderAlpha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tint.withValues(alpha: borderAlpha)),
          ),
          child: Center(
            child: icon.endsWith('.svg')
                ? SvgPicture.asset(icon, width: iconSize, height: iconSize)
                : Image.asset(icon, width: iconSize, height: iconSize),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: 0.06,
            color: AppColors.textGrey555,
          ),
        ),
      ],
    );
  }
}

class _AdvocateCard extends StatelessWidget {
  const _AdvocateCard(this.advocate);

  final _AdvocateData advocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(158),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: context.rs(116),
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(advocate.image, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_verified_badge.svg',
                          width: 9,
                          height: 9,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: 0.17,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advocate.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 15 / 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advocate.specialty,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.12,
                    color: AppColors.textGrey555,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (advocate.rating != null) ...[
                      Text(
                        advocate.rating!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: 0.12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      advocate.experience,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: advocate.price,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                              letterSpacing: -0.08,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(
                            text: '/hr',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              letterSpacing: 0.12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.textPrimary,
                            AppColors.gradientDarkEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Book',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: 0.12,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.badge,
    required this.badgeColor,
    required this.price,
    required this.showDivider,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String time;
  final String badge;
  final Color badgeColor;
  final String price;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.14),
              ),
            ),
            child: Center(
              child: SvgPicture.asset(icon, width: 20, height: 20),
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
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_clock.svg',
                      width: 10,
                      height: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        letterSpacing: 0.06,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0.12,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
