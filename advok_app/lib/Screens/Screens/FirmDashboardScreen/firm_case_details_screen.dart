import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../MessagesScreen/chat_screen.dart';
import 'firm_dashboard_screen.dart';

const List<String> _timelineSteps = [
  'Case Opened',
  'Documents Filed',
  'Discovery Phase',
  'Hearing Scheduled',
];

const List<String> _statuses = ['Active', 'Hearing', 'Closed'];

/// Detail view for a firm case, opened from the dashboard's Cases tab.
class FirmCaseDetailsScreen extends StatefulWidget {
  const FirmCaseDetailsScreen({super.key, required this.caseData});

  final FirmCase caseData;

  @override
  State<FirmCaseDetailsScreen> createState() => _FirmCaseDetailsScreenState();
}

class _FirmCaseDetailsScreenState extends State<FirmCaseDetailsScreen> {
  late String _status = widget.caseData.status;

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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    _buildTitleCard(),
                    const SizedBox(height: 16),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildTimelineCard(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: _buildFooterButtons(),
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
        children: const [
          CircleBackButton(),
          SizedBox(width: 14),
          Text(
            'Case Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
              letterSpacing: -0.34,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
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
          Text(
            widget.caseData.number,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 1.2,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.caseData.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 24 / 17,
                    letterSpacing: -0.34,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0.12,
                    color: AppColors.textGrey555,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: 'assets/icons/ic_user.svg',
            label: 'Client',
            value: widget.caseData.client,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: 'assets/icons/ic_briefcase.svg',
            label: 'Assigned Lawyer',
            value: widget.caseData.lawyer,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: 'assets/icons/ic_calendar_dark.svg',
            label: 'Next Hearing',
            value: widget.caseData.nextDate,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: 'assets/icons/ic_clock.svg',
            label: 'Priority',
            value: widget.caseData.priority,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
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
          const Text(
            'Case Timeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.5,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _timelineSteps.length; i++)
            _TimelineRow(
              title: _timelineSteps[i],
              done: i == 0,
              isLast: i == _timelineSteps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      name: widget.caseData.client,
                      online: true,
                      specialty: widget.caseData.title,
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showStatusSheet,
                child: const SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 19.5 / 13,
                        letterSpacing: -0.08,
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
    );
  }

  void _showStatusSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Update Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.31,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final status in _statuses)
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: status == _status
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: status == _status
                            ? SvgPicture.asset(
                                'assets/icons/ic_check.svg',
                                width: 14,
                                height: 14,
                              )
                            : null,
                        onTap: () {
                          setState(() => _status = status);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(icon, width: 15, height: 15),
          ),
        ),
        const SizedBox(width: 12),
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
              Text(
                value,
                style: const TextStyle(
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
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.done,
    required this.isLast,
  });

  final String title;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                if (done)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_check.svg',
                        width: 8,
                        height: 8,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.progressTrack,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                  ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      color: AppColors.progressTrack,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: done ? AppColors.textPrimary : AppColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
