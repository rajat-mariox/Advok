import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../MessagesScreen/chat_screen.dart';

class _FirmLawyer {
  const _FirmLawyer({
    // ignore: unused_element_parameter — set once lawyer photos are uploaded.
    this.avatar = '',
    required this.name,
    required this.designation,
    required this.specialty,
    required this.caseCount,
    required this.since,
  });

  final String avatar;
  final String name;
  final String designation;
  final String specialty;
  final int caseCount;
  final String since;
}

/// Lawyers the firm added during onboarding, mapped onto the card model.
List<_FirmLawyer> _lawyersFromSession() {
  final raw = Session.profile?['lawyers'];
  if (raw is! List) return const [];
  return [
    for (final entry in raw)
      if (entry is Map)
        _FirmLawyer(
          name: _entryField(entry, 'fullName', 'Unnamed Lawyer'),
          designation: _entryField(entry, 'designation', 'Lawyer'),
          specialty: _entryField(entry, 'expertise', 'General Practice'),
          caseCount: 0,
          since: _experienceLabel(entry),
        ),
  ];
}

String _entryField(Map<dynamic, dynamic> entry, String key, String fallback) {
  final value = entry[key]?.toString().trim() ?? '';
  return value.isEmpty ? fallback : value;
}

String _experienceLabel(Map<dynamic, dynamic> entry) {
  final years = entry['yearsExperience']?.toString().trim() ?? '';
  return years.isEmpty ? '—' : '$years yrs experience';
}

/// Lawyer roster for the firm's bottom-nav Lawyers tab.
class FirmLawyersScreen extends StatelessWidget {
  const FirmLawyersScreen({super.key, this.onBack, this.onViewCases});

  final VoidCallback? onBack;
  final VoidCallback? onViewCases;

  @override
  Widget build(BuildContext context) {
    final lawyers = _lawyersFromSession();
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: lawyers.isEmpty
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [_buildEmptyState()],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: lawyers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _LawyerCard(
                      lawyer: lawyers[index],
                      onViewCases: onViewCases,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
              child: SvgPicture.asset(
                'assets/icons/ic_user.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No lawyers yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lawyers added during onboarding will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
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
          CircleBackButton(onTap: onBack),
          const Expanded(
            child: Text(
              'Our Lawyers',
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
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // TODO: Open the add-lawyer form once it's designed.
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_plus.svg',
                    width: 14,
                    height: 14,
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

class _LawyerCard extends StatelessWidget {
  const _LawyerCard({required this.lawyer, this.onViewCases});

  final _FirmLawyer lawyer;
  final VoidCallback? onViewCases;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lawyer.avatar.isEmpty)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_user.svg',
                      width: 22,
                      height: 22,
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    lawyer.avatar,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name,
                      overflow: TextOverflow.ellipsis,
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
                      lawyer.designation,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    Text(
                      lawyer.specialty,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Cases ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  Text(
                    '${lawyer.caseCount}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 22.5 / 15,
                      letterSpacing: -0.23,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_calendar_dark.svg',
                    width: 11,
                    height: 11,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textGrey,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    lawyer.since,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      letterSpacing: 0.06,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              name: lawyer.name,
                              image: lawyer.avatar.isEmpty
                                  ? null
                                  : lawyer.avatar,
                              online: true,
                              specialty: lawyer.specialty,
                            ),
                          ),
                        );
                      },
                      child: const SizedBox(
                        height: 38,
                        child: Center(
                          child: Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 16 / 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.textPrimary,
                          AppColors.gradientDarkEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: onViewCases,
                        child: const SizedBox(
                          height: 38,
                          child: Center(
                            child: Text(
                              'View Cases',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 16 / 12,
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
          ),
        ],
      ),
    );
  }
}
