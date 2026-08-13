import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/session_avatar.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../MessagesScreen/chat_screen.dart';
import 'firm_case_details_screen.dart';

class _Hearing {
  const _Hearing({
    required this.time,
    required this.title,
    required this.subtitle,
  });

  final String time;
  final String title;
  final String subtitle;
}

const List<_Hearing> _hearings = [];

class _ClientRequest {
  const _ClientRequest({
    required this.avatar,
    required this.name,
    required this.matter,
    required this.timeAgo,
  });

  final String avatar;
  final String name;
  final String matter;
  final String timeAgo;
}

const List<_ClientRequest> _requests = [];

class _Lawyer {
  _Lawyer({
    // ignore: unused_element_parameter — set once lawyer photos are uploaded.
    this.avatar = '',
    required this.name,
    required this.role,
    required this.caseCount,
    required this.available,
  });

  final String avatar;
  final String name;
  final String role;
  final int caseCount;
  bool available;
}

class FirmCase {
  const FirmCase({
    required this.number,
    required this.title,
    required this.client,
    required this.lawyer,
    required this.status,
    required this.nextDate,
    required this.priority,
    this.filed = '',
  });

  final String number;
  final String title;
  final String client;
  final String lawyer;
  final String status;
  final String nextDate;
  final String priority;
  final String filed;
}

const List<FirmCase> _cases = [];

class _ScheduleItem {
  const _ScheduleItem({
    required this.title,
    required this.lawyer,
    required this.when,
    required this.type,
  });

  final String title;
  final String lawyer;
  final String when;
  final String type;
}

const List<_ScheduleItem> _schedule = [];

class FirmDashboardScreen extends StatefulWidget {
  const FirmDashboardScreen({super.key, this.onFirmTap});

  final VoidCallback? onFirmTap;

  @override
  State<FirmDashboardScreen> createState() => _FirmDashboardScreenState();
}

class _FirmDashboardScreenState extends State<FirmDashboardScreen> {
  int _tab = 0;
  int _caseFilter = 0;

  static const List<String> _tabs = [
    'Overview',
    'Lawyers',
    'Cases',
    'Calendar',
  ];

  static const List<String> _caseFilters = [
    'All',
    'Active',
    'Hearing',
    'Closed',
  ];

  final List<_ClientRequest> _pendingRequests = List.of(_requests);

  /// Lawyers the firm added during onboarding, mapped onto the card model.
  final List<_Lawyer> _lawyers = _lawyersFromSession();

  static List<_Lawyer> _lawyersFromSession() {
    final raw = Session.profile?['lawyers'];
    if (raw is! List) return [];
    return [
      for (final entry in raw)
        if (entry is Map)
          _Lawyer(
            name: _entryField(entry, 'fullName', 'Unnamed Lawyer'),
            role: _roleFor(entry),
            caseCount: 0,
            available: true,
          ),
    ];
  }

  static String _entryField(
    Map<dynamic, dynamic> entry,
    String key,
    String fallback,
  ) {
    final value = entry[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  static String _roleFor(Map<dynamic, dynamic> entry) {
    final designation = entry['designation']?.toString().trim() ?? '';
    final expertise = entry['expertise']?.toString().trim() ?? '';
    if (designation.isEmpty && expertise.isEmpty) return 'Lawyer';
    if (designation.isEmpty) return expertise;
    if (expertise.isEmpty) return designation;
    return '$designation · $expertise';
  }

  void _declineRequest(_ClientRequest request) {
    setState(() => _pendingRequests.remove(request));
  }

  void _acceptRequest(_ClientRequest request) {
    setState(() => _pendingRequests.remove(request));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildHeader(),
        _buildTabs(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: switch (_tab) {
            0 => _buildOverview(),
            1 => _buildLawyersView(),
            2 => _buildCasesView(),
            _ => _buildCalendarView(),
          },
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid(),
        const SizedBox(height: 24),
        const Text(
          "Today's Hearings",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildHearingsCard(),
        const SizedBox(height: 20),
        _buildRequestsHeader(),
        const SizedBox(height: 12),
        if (_pendingRequests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          )
        else
          for (final (i, request) in _pendingRequests.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            _RequestCard(
              request: request,
              onAccept: () => _acceptRequest(request),
              onDecline: () => _declineRequest(request),
            ),
          ],
        const SizedBox(height: 20),
        const Text(
          'Revenue Overview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildRevenueCard(),
      ],
    );
  }

  Widget _buildLawyersView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Our Lawyers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.5,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
            DecoratedBox(
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
                    // TODO: Open the add-lawyer form once it's designed.
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_plus.svg',
                          width: 11,
                          height: 11,
                          colorFilter: const ColorFilter.mode(
                            AppColors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 16 / 12,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lawyers.isEmpty)
          _buildEmptyState(
            icon: 'assets/icons/ic_user.svg',
            title: 'No lawyers yet',
            message: 'Lawyers added during onboarding will appear here.',
          )
        else
          for (final (i, lawyer) in _lawyers.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _LawyerCard(
              lawyer: lawyer,
              onAvailabilityChanged: (value) {
                setState(() => lawyer.available = value);
              },
            ),
          ],
      ],
    );
  }

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Center(
              child: Container(
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

  Widget _buildCasesView() {
    final filter = _caseFilters[_caseFilter];
    final visibleCases = filter == 'All'
        ? _cases
        : _cases.where((c) => c.status == filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < _caseFilters.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Material(
                color: _caseFilter == i
                    ? AppColors.textPrimary
                    : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _caseFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _caseFilter == i
                            ? AppColors.textPrimary
                            : AppColors.borderGrey,
                      ),
                    ),
                    child: Text(
                      _caseFilters[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                        color: _caseFilter == i
                            ? AppColors.white
                            : AppColors.textGrey555,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (visibleCases.isEmpty)
          _buildEmptyState(
            icon: 'assets/icons/ic_office.svg',
            title: filter == 'All'
                ? 'No cases yet'
                : 'No ${filter.toLowerCase()} cases',
            message: 'Firm cases will appear here once case tracking goes live.',
          )
        else
          for (final (i, firmCase) in visibleCases.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _CaseCard(
              firmCase: firmCase,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FirmCaseDetailsScreen(caseData: firmCase),
                  ),
                );
              },
            ),
          ],
      ],
    );
  }

  Widget _buildCalendarView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Schedule',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_schedule.isEmpty)
          _buildEmptyState(
            icon: 'assets/icons/ic_calendar_dark.svg',
            title: 'Nothing scheduled',
            message:
                'Hearings and consultations will appear here once scheduling goes live.',
          )
        else
          for (final (i, item) in _schedule.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _ScheduleCard(
              item: item,
              onTap: () => _showScheduleSheet(item),
            ),
          ],
      ],
    );
  }

  void _showScheduleSheet(_ScheduleItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 24 / 16,
                          letterSpacing: -0.31,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Material(
                      color: AppColors.progressTrack,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/ic_clear.svg',
                              width: 14,
                              height: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fillGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Column(
                    children: [
                      _SheetInfoRow(
                        icon: 'assets/icons/ic_user.svg',
                        label: 'Lawyer',
                        value: item.lawyer,
                      ),
                      const SizedBox(height: 14),
                      _SheetInfoRow(
                        icon: 'assets/icons/ic_clock.svg',
                        label: 'Date / Time',
                        value: item.when,
                      ),
                      const SizedBox(height: 14),
                      _SheetInfoRow(
                        icon: 'assets/icons/ic_calendar_dark.svg',
                        label: 'Type',
                        value: item.type,
                        valueAsPill: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: AppColors.progressTrack,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            // TODO: Open document preparation once designed.
                          },
                          child: const SizedBox(
                            height: 48,
                            child: Center(
                              child: Text(
                                'Prepare Documents',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 19.5 / 13,
                                  letterSpacing: -0.08,
                                  color: AppColors.textPrimary,
                                ),
                              ),
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
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    name: item.lawyer,
                                    online: true,
                                    specialty: item.title,
                                  ),
                                ),
                              );
                            },
                            child: const SizedBox(
                              height: 48,
                              child: Center(
                                child: Text(
                                  'Message Lawyer',
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Law Firm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  Session.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 25 / 20,
                    letterSpacing: -0.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SessionAvatar(
            size: 44,
            borderRadius: BorderRadius.circular(16),
            fallbackIcon: 'assets/icons/ic_role_firm.svg',
            onTap: widget.onFirmTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Material(
              color: _tab == i ? AppColors.textPrimary : AppColors.fillGrey,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _tab == i
                          ? AppColors.textPrimary
                          : AppColors.borderGrey,
                    ),
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      color: _tab == i
                          ? AppColors.white
                          : AppColors.textGrey555,
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

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _FirmStatCard(
                icon: 'assets/icons/ic_stat_revenue.svg',
                badge: '—',
                value: r'$0',
                label: 'Revenue',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FirmStatCard(
                icon: 'assets/icons/ic_stat_cases.svg',
                badge: '—',
                value: '${_cases.length}',
                label: 'Active Cases',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FirmStatCard(
                icon: 'assets/icons/ic_purpose_clients.svg',
                badge: 'Active',
                value: '${_lawyers.length}',
                label: 'Our Lawyers',
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _FirmStatCard(
                icon: 'assets/icons/ic_user.svg',
                badge: '—',
                value: '0',
                label: 'Clients',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHearingsCard() {
    if (_hearings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Center(
          child: Text(
            'No hearings scheduled today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: AppColors.textGrey,
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            for (int i = 0; i < _hearings.length; i++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: i < _hearings.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.divider),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      child: Text(
                        _hearings[i].time,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: 0.06,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.textPrimary.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hearings[i].title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 19.5 / 13,
                              letterSpacing: -0.08,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hearings[i].subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              letterSpacing: 0.06,
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
      ),
    );
  }

  Widget _buildRequestsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pending Client Requests',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
        if (_pendingRequests.isNotEmpty)
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_pendingRequests.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 80,
            child: Center(
              child: Text(
                'Revenue data will appear once billing goes live.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'This month',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    letterSpacing: 0.06,
                    color: AppColors.textGrey555,
                  ),
                ),
                Text(
                  r'$0',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                    letterSpacing: -0.26,
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

class _FirmStatCard extends StatelessWidget {
  const _FirmStatCard({
    required this.icon,
    required this.badge,
    required this.value,
    required this.label,
  });

  final String icon;
  final String badge;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(icon, width: 16, height: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge,
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
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 25 / 20,
              letterSpacing: -0.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}

class _LawyerCard extends StatelessWidget {
  const _LawyerCard({
    required this.lawyer,
    required this.onAvailabilityChanged,
  });

  final _Lawyer lawyer;
  final ValueChanged<bool> onAvailabilityChanged;

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
                  width: 60,
                  height: 60,
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
                    width: 60,
                    height: 60,
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
                      lawyer.role,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lawyer.caseCount} cases',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available for new cases',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
                _AvailabilityToggle(
                  value: lawyer.available,
                  onChanged: onAvailabilityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
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
                      onTap: () {
                        // TODO: Open case assignment once it's designed.
                      },
                      child: const SizedBox(
                        height: 38,
                        child: Center(
                          child: Text(
                            'Assign Case',
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
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () {
                      // TODO: Open the lawyer profile once it's designed.
                    },
                    child: const SizedBox(
                      height: 38,
                      child: Center(
                        child: Text(
                          'View Profile',
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
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item, this.onTap});

  final _ScheduleItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isHearing = item.type == 'Hearing';
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
          child: _buildRow(isHearing),
        ),
      ),
    );
  }

  Widget _buildRow(bool isHearing) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.progressTrack,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                isHearing
                    ? 'assets/icons/ic_file.svg'
                    : 'assets/icons/ic_calendar_dark.svg',
                width: 16,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 19.5 / 13,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.lawyer,
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
                      width: 11,
                      height: 11,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.when,
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
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.progressTrack,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              item.type,
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
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  const _SheetInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueAsPill = false,
  });

  final String icon;
  final String label;
  final String value;
  final bool valueAsPill;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: SvgPicture.asset(
            icon,
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(
              AppColors.textGrey,
              BlendMode.srcIn,
            ),
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
              const SizedBox(height: 2),
              if (valueAsPill)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      letterSpacing: 0.12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                )
              else
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

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.firmCase, this.onTap});

  final FirmCase firmCase;
  final VoidCallback? onTap;

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
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  firmCase.number,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 1.2,
                    color: AppColors.textGrey,
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
                  firmCase.status,
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
          const SizedBox(height: 2),
          Text(
            firmCase.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_user.svg',
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  AppColors.textGrey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                firmCase.client,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textGrey555,
                ),
              ),
              const SizedBox(width: 14),
              SvgPicture.asset(
                'assets/icons/ic_office.svg',
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  AppColors.textGrey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                firmCase.lawyer,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: AppColors.textPrimary,
                ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_calendar_dark.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Next: ${firmCase.nextDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
                _PriorityPill(priority: firmCase.priority),
              ],
            ),
          ),
      ],
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final base = switch (priority) {
      'High' => const Color(0xFF2A2A2A),
      'Medium' => AppColors.textGrey555,
      _ => AppColors.textGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: base.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$priority Priority',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.5,
          letterSpacing: 0.12,
          color: base,
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.textPrimary : AppColors.progressTrack,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: value ? AppColors.textPrimary : AppColors.borderGrey,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final _ClientRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              request.avatar,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 19.5 / 13,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.matter,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.timeAgo,
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
          const SizedBox(width: 6),
          Material(
            color: AppColors.progressTrack,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onDecline,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_clear.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              ),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAccept,
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_check.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
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
