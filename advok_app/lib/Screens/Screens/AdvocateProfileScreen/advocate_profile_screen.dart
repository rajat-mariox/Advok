import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/Responsive/responsive.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';
import '../BookingScreen/consultation_type_screen.dart';

class AdvocateProfileScreen extends StatelessWidget {
  const AdvocateProfileScreen({super.key, required this.advocate});

  final Advocate advocate;

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
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    _buildStats(),
                    const SizedBox(height: 20),
                    const Text('About', style: _sectionTitleStyle),
                    const SizedBox(height: 8),
                    const Text(
                      'This advocate has not added a bio yet.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 22.75 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Practice Areas', style: _sectionTitleStyle),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PracticeChip(advocate.specialty),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFeeCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConsultationTypeScreen(
                              advocate: advocate,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_calendar_white.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Book Appointment',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _sectionTitleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: -0.08,
    color: AppColors.textPrimary,
  );

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: context.rs(272),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(advocate.image, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xEB000000)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeroCircleButton(
                  icon: 'assets/icons/ic_arrow_back_white.svg',
                  iconSize: 18,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Row(
                  children: [
                    _HeroCircleButton(
                      icon: 'assets/icons/ic_heart_white.svg',
                      iconSize: 16,
                      onTap: () {
                        // TODO: Toggle favourite.
                      },
                    ),
                    const SizedBox(width: 8),
                    _HeroCircleButton(
                      icon: 'assets/icons/ic_share.svg',
                      iconSize: 16,
                      onTap: () {
                        // TODO: Share profile.
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advocate.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 33 / 22,
                    letterSpacing: -0.81,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  advocate.specialty,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: Color(0xFFD9D3D3),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_pin_white.svg',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      advocate.location,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: Color(0xFFD9D3D3),
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

  Widget _buildActionButtons() {
    return Row(
      children: const [
        Expanded(
          child: _ActionButton(
            icon: 'assets/icons/ic_phone.svg',
            label: 'Call',
            badgeColor: Color(0x212A2A2A),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: 'assets/icons/ic_video.svg',
            label: 'Video',
            badgeColor: Color(0x21333333),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: 'assets/icons/ic_qa_chat.svg',
            label: 'Message',
            badgeColor: Color(0x21444444),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _StatCard(value: advocate.cases, label: 'Cases')),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(value: advocate.experience, label: 'Experience'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(value: advocate.rating ?? '—', label: 'Rating'),
        ),
      ],
    );
  }

  Widget _buildFeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultation Fee',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: advocate.price,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 39 / 26,
                          letterSpacing: 0.22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: '/hr',
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ],
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

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  final String icon;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: SvgPicture.asset(icon, width: iconSize, height: iconSize),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.badgeColor,
  });

  final String icon;
  final String label;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: SvgPicture.asset(icon, width: 18, height: 18),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.5,
              letterSpacing: -0.43,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
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

class _PracticeChip extends StatelessWidget {
  const _PracticeChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: AppColors.textGrey555,
        ),
      ),
    );
  }
}
