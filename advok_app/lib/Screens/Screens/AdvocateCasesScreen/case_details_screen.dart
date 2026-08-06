import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateClientsScreen/client_directory.dart';
import '../MessagesScreen/chat_screen.dart';
import 'advocate_cases_screen.dart';

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.date,
    required this.done,
  });

  final String title;
  final String date;
  final bool done;
}

/// Timeline entries for the case. Empty until case tracking is API-backed.
const List<_TimelineStep> _timeline = [];

/// Documents attached to the case. Empty until file handling exists.
const List<String> _documents = [];

class CaseDetailsScreen extends StatelessWidget {
  const CaseDetailsScreen({super.key, required this.caseData});

  final AdvocateCase caseData;

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    const _SectionLabel('Case Timeline'),
                    const SizedBox(height: 12),
                    if (_timeline.isEmpty)
                      const _EmptyState(
                        icon: 'assets/icons/ic_clock.svg',
                        title: 'No timeline events yet',
                        message:
                            'Case milestones will appear here once case tracking goes live.',
                      )
                    else
                      for (int i = 0; i < _timeline.length; i++)
                        _TimelineRow(
                          step: _timeline[i],
                          isLast: i == _timeline.length - 1,
                        ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Documents'),
                    const SizedBox(height: 12),
                    if (_documents.isEmpty)
                      const _EmptyState(
                        icon: 'assets/icons/ic_file.svg',
                        title: 'No documents yet',
                        message:
                            'Files added to this case will appear here.',
                      )
                    else
                      for (int i = 0; i < _documents.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _DocumentRow(name: _documents[i]),
                      ],
                    const SizedBox(height: 24),
                    _buildActions(context),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
      child: Row(
        children: [
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_arrow_back.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Case Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              CaseBadge(
                label: caseData.status.label,
                color: caseData.status.badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caseData.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 27 / 18,
              letterSpacing: -0.44,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Client: ${caseData.client}',
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final rows = <(String, String)>[
      ('Date Filed', caseData.filed),
      if (caseData.nextHearing != null) ('Next Hearing', caseData.nextHearing!),
      if (caseData.priority != null) ('Priority', caseData.priority!.label),
      ('Practice Area', caseData.practiceArea),
      ('Court', caseData.court),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 19.5 / 13,
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

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final client = ClientDirectory.instance.findByName(
                  caseData.client,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      name: caseData.client,
                      image: client?.avatar,
                      online: true,
                      specialty: caseData.title,
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_chat_bubble.svg',
                      width: 15,
                      height: 15,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Message Client',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // TODO: Open the add-document flow once designed.
                },
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_plus.svg',
                        width: 15,
                        height: 15,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Document',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 20 / 14,
                          letterSpacing: -0.15,
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
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 0.6,
        color: AppColors.textGrey,
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: 24),
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: step.done
                    ? AppColors.textPrimary
                    : AppColors.progressTrack,
                shape: BoxShape.circle,
                border: Border.all(
                  color: step.done
                      ? AppColors.textPrimary
                      : AppColors.borderGrey,
                  width: 1.4,
                ),
              ),
              child: step.done
                  ? Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_check.svg',
                        width: 10,
                        height: 10,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  : null,
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Container(
                  width: 2,
                  height: 20,
                  color: step.done
                      ? AppColors.textPrimary
                      : AppColors.progressTrack,
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 19.5 / 13,
                    letterSpacing: -0.08,
                    color: step.done
                        ? AppColors.textPrimary
                        : AppColors.textGrey555,
                  ),
                ),
                Text(
                  step.date,
                  style: const TextStyle(
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
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Open the document once file handling exists.
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_file.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 19.5 / 13,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/ic_chevron_right_grey.svg',
                width: 13,
                height: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
