import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';
import 'case_details_screen.dart';

enum CaseStatus { active, hearing, discovery, closed }

extension CaseStatusLabel on CaseStatus {
  String get label => switch (this) {
        CaseStatus.active => 'Active',
        CaseStatus.hearing => 'Hearing',
        CaseStatus.discovery => 'Discovery',
        CaseStatus.closed => 'Closed',
      };

  Color get badgeColor => switch (this) {
        CaseStatus.active => const Color(0xFF2A2A2A),
        CaseStatus.hearing => const Color(0xFF555555),
        CaseStatus.discovery => const Color(0xFF333333),
        CaseStatus.closed => const Color(0xFF999999),
      };
}

enum CasePriority { high, medium, low }

extension CasePriorityLabel on CasePriority {
  String get label => switch (this) {
        CasePriority.high => 'High',
        CasePriority.medium => 'Medium',
        CasePriority.low => 'Low',
      };

  Color get badgeColor => switch (this) {
        CasePriority.high => const Color(0xFF1A1A1A),
        CasePriority.medium => const Color(0xFF555555),
        CasePriority.low => const Color(0xFF999999),
      };
}

class AdvocateCase {
  const AdvocateCase({
    required this.number,
    required this.title,
    required this.client,
    required this.status,
    required this.filed,
    this.nextHearing,
    this.priority,
    required this.practiceArea,
    required this.court,
  });

  final String number;
  final String title;
  final String client;
  final CaseStatus status;
  final String filed;

  /// Null for closed cases with no upcoming hearing.
  final String? nextHearing;

  /// Null for closed cases.
  final CasePriority? priority;
  final String practiceArea;
  final String court;
}

/// Advocate case list. Empty until case management is backed by the API.
const List<AdvocateCase> advocateCases = [];

class AdvocateCasesScreen extends StatefulWidget {
  const AdvocateCasesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AdvocateCasesScreen> createState() => _AdvocateCasesScreenState();
}

class _AdvocateCasesScreenState extends State<AdvocateCasesScreen> {
  CaseStatus? _filter;

  List<AdvocateCase> get _filtered => _filter == null
      ? advocateCases
      : advocateCases.where((c) => c.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterChips(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              if (_filtered.isEmpty)
                _buildEmptyState()
              else
                for (int i = 0; i < _filtered.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _CaseCard(
                    caseData: _filtered[i],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CaseDetailsScreen(caseData: _filtered[i]),
                        ),
                      );
                    },
                  ),
                ],
            ],
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
                'assets/icons/ic_briefcase.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No cases yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cases will appear here once case management goes live.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HeaderButton(
            icon: 'assets/icons/ic_arrow_back.svg',
            onTap: widget.onBack,
          ),
          const Text(
            'My Cases',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 22.5 / 15,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          _HeaderButton(
            icon: 'assets/icons/ic_plus.svg',
            onTap: () {
              // TODO: Open the add-case flow once designed.
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <(CaseStatus?, String)>[
      (null, 'All'),
      (CaseStatus.active, 'Active'),
      (CaseStatus.hearing, 'Hearing'),
      (CaseStatus.discovery, 'Discovery'),
      (CaseStatus.closed, 'Closed'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (final (status, label) in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: label,
                selected: _filter == status,
                onTap: () => setState(() => _filter = status),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onTap});

  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Center(
            child: SvgPicture.asset(icon, width: 16, height: 16),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: selected ? AppColors.white : AppColors.textGrey555,
            ),
          ),
        ),
      ),
    );
  }
}

class CaseBadge extends StatelessWidget {
  const CaseBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.5,
          letterSpacing: 0.12,
          color: color,
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.caseData, required this.onTap});

  final AdvocateCase caseData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caseData.number.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: 1.16,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caseData.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Client: ${caseData.client}',
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
                  CaseBadge(
                    label: caseData.status.label,
                    color: caseData.status.badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: SvgPicture.asset(
                      'assets/icons/ic_chevron_right_grey.svg',
                      width: 14,
                      height: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 13),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_calendar_dark.svg',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filed ${caseData.filed}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        letterSpacing: 0.06,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    if (caseData.nextHearing != null) ...[
                      const SizedBox(width: 16),
                      SvgPicture.asset(
                        'assets/icons/ic_clock.svg',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Next: ${caseData.nextHearing}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: 0.06,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (caseData.priority != null)
                      CaseBadge(
                        label: '${caseData.priority!.label} Priority',
                        color: caseData.priority!.badgeColor,
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
}
