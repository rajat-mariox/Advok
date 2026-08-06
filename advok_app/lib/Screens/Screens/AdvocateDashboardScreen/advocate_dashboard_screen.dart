import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateCasesScreen/advocate_cases_screen.dart';
import '../AdvocateCasesScreen/case_details_screen.dart';
import '../AdvocateClientsScreen/client_directory.dart';
import '../MessagesScreen/chat_screen.dart';

class _ScheduleEntry {
  // The optional fields below are populated by API data once scheduling is
  // live; no call site passes them while the list is empty.
  const _ScheduleEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    // ignore: unused_element_parameter
    this.status,
    // ignore: unused_element_parameter
    this.blocked = false,
  });

  final String time;
  final String title;
  final String subtitle;
  final String? status;
  final bool blocked;
}

/// Today's appointments. Empty until scheduling is backed by the API.
const List<_ScheduleEntry> _schedule = [];

class _Hearing {
  const _Hearing({
    required this.date,
    required this.time,
    required this.caseNumber,
    required this.matter,
    required this.court,
  });

  final String date;
  final String time;
  final String caseNumber;
  final String matter;
  final String court;
}

/// Upcoming hearings. Empty until hearings are backed by the API.
const List<_Hearing> _hearings = [];

class _ClientRequest {
  const _ClientRequest({
    required this.avatar,
    required this.name,
    required this.matter,
    required this.timeAgo,
    // ignore: unused_element_parameter
    this.urgent = false,
  });

  final String avatar;
  final String name;
  final String matter;
  final String timeAgo;
  final bool urgent;
}

/// Relative bar heights for the earnings chart, Jan–Jul. All zero until
/// earnings are backed by the API.
const List<double> _earningsBars = [0, 0, 0, 0, 0, 0, 0];
const List<String> _earningsMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
];

class AdvocateDashboardScreen extends StatefulWidget {
  const AdvocateDashboardScreen({
    super.key,
    this.onProfileTap,
    this.onViewCasesTap,
    this.onMessageClientsTap,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback? onViewCasesTap;
  final VoidCallback? onMessageClientsTap;

  @override
  State<AdvocateDashboardScreen> createState() =>
      _AdvocateDashboardScreenState();
}

class _AdvocateDashboardScreenState extends State<AdvocateDashboardScreen> {
  int _tab = 0;

  static const List<String> _tabs = ['Today', 'Hearings', 'Tasks'];

  /// Incoming client requests. Empty until requests are backed by the API.
  final List<_ClientRequest> _pendingRequests = [];

  void _declineRequest(_ClientRequest request) {
    setState(() => _pendingRequests.remove(request));
  }

  void _acceptRequest(_ClientRequest request) {
    ClientDirectory.instance.addFromAcceptedRequest(
      name: request.name,
      avatar: request.avatar,
      matter: request.matter,
    );
    setState(() => _pendingRequests.remove(request));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildHeader(),
        _buildStatsRow(),
        const SizedBox(height: 16),
        _buildTabs(),
        const SizedBox(height: 12),
        if (_tab == 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHearingsTab(),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScheduleHeader(),
                const SizedBox(height: 12),
                _buildScheduleCard(),
                const SizedBox(height: 12),
                _buildQuickActions(),
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
                        'No new requests',
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
                      highlighted: i == 0,
                      onAccept: () => _acceptRequest(request),
                      onDecline: () => _declineRequest(request),
                    ),
                  ],
                const SizedBox(height: 20),
                const Text(
                  'Earnings Overview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEarningsCard(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning,',
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Available · ${Session.roleLabel}',
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
              ],
            ),
          ),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // TODO: Open notifications once that screen is designed.
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
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
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey, width: 1.4),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/ic_user.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Expanded(
            child: _StatCard(
              icon: 'assets/icons/ic_stat_revenue.svg',
              value: r'$0',
              label: 'Revenue',
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _StatCard(
              icon: 'assets/icons/ic_stat_cases.svg',
              value: '${advocateCases.length}',
              label: 'Cases',
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _StatCard(
              icon: 'assets/icons/ic_stat_requests.svg',
              value: '${_pendingRequests.length}',
              label: 'Requests',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: _tab == i ? AppColors.textPrimary : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _tab == i
                            ? AppColors.textPrimary
                            : AppColors.borderGrey,
                      ),
                    ),
                    child: Center(
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _todayLabel {
    final now = DateTime.now();
    return '${_weekdayLabels[now.weekday - 1]}, '
        '${_monthLabels[now.month - 1]} ${now.day}';
  }

  Widget _buildScheduleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Schedule",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            _todayLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.06,
              color: AppColors.textGrey555,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
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
            if (_schedule.isEmpty)
              const _EmptyState(
                icon: 'assets/icons/ic_calendar_dark.svg',
                title: 'No appointments today',
                message:
                    'Appointments will appear here once scheduling goes live.',
              )
            else
              for (int i = 0; i < _schedule.length; i++)
                _ScheduleRow(
                  entry: _schedule[i],
                  showDivider: i < _schedule.length - 1,
                  onTap: _schedule[i].blocked
                      ? null
                      : () => _showAppointmentSheet(_schedule[i]),
                ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentSheet(_ScheduleEntry entry) {
    // "Video · DUI Defense" → "DUI Defense"
    final matter = entry.subtitle.split(' · ').last;
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
                    const Text(
                      'Appointment Details',
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
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.progressTrack,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/ic_user.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 22.5 / 15,
                                letterSpacing: -0.23,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              matter,
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
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: AppColors.progressTrack,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openClientChat(entry.title, matter: matter);
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
                                  'Message',
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
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              final matches = advocateCases
                                  .where((c) => c.title == matter)
                                  .toList();
                              if (matches.isEmpty) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CaseDetailsScreen(
                                    caseData: matches.first,
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
                                    'assets/icons/ic_file.svg',
                                    width: 15,
                                    height: 15,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'View Case',
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCase(String caseNumber) {
    final matches =
        advocateCases.where((c) => c.number == caseNumber).toList();
    if (matches.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseDetailsScreen(caseData: matches.first),
      ),
    );
  }

  void _openClientChat(String name, {String? matter}) {
    final client = ClientDirectory.instance.findByName(name);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          name: name,
          image: client?.avatar,
          online: true,
          specialty: matter ?? client?.matter,
        ),
      ),
    );
  }

  Widget _buildHearingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Hearings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.5,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_hearings.length} scheduled',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: 0.06,
                color: AppColors.textGrey555,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_hearings.isEmpty)
          const Center(
            child: _EmptyState(
              icon: 'assets/icons/ic_judge.svg',
              title: 'No hearings scheduled',
              message:
                  'Upcoming hearings will appear here once case management goes live.',
            ),
          )
        else
          for (int i = 0; i < _hearings.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildHearingCard(_hearings[i]),
          ],
      ],
    );
  }

  Widget _buildHearingCard(_Hearing hearing) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey, width: 0.7),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_judge.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hearing.date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hearing.time,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 16.5 / 11,
                      letterSpacing: 0.06,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${hearing.caseNumber} · ${hearing.matter}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 16.25 / 13,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_office.svg',
                width: 11,
                height: 11,
                colorFilter: const ColorFilter.mode(
                  AppColors.textGrey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hearing.court,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textGrey555,
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
                Expanded(
                  child: Material(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openCase(hearing.caseNumber),
                      child: const SizedBox(
                        height: 32,
                        child: Center(
                          child: Text(
                            'View Case',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16 / 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          final matches = advocateCases
                              .where((c) => c.number == hearing.caseNumber)
                              .toList();
                          if (matches.isEmpty) return;
                          _openClientChat(
                            matches.first.client,
                            matter: matches.first.title,
                          );
                        },
                        child: const SizedBox(
                          height: 32,
                          child: Center(
                            child: Text(
                              'Message Client',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: 'assets/icons/ic_chat_bubble.svg',
            label: 'Message Clients',
            onTap: () => widget.onMessageClientsTap?.call(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: 'assets/icons/ic_file.svg',
            label: 'View Cases',
            onTap: () => widget.onViewCasesTap?.call(),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'New Client Requests',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${_pendingRequests.length} New',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: 0.12,
                color: AppColors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < _earningsBars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: _earningsBars[i],
                      decoration: BoxDecoration(
                        color: i == _earningsBars.length - 1
                            ? AppColors.textPrimary
                            : AppColors.progressTrack,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < _earningsMonths.length; i++)
                Text(
                  _earningsMonths[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.17,
                    color: i == _earningsMonths.length - 1
                        ? AppColors.textPrimary
                        : AppColors.textGrey,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.progressTrack,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_trend_up.svg',
                            width: 11,
                            height: 11,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '+0%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.06,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'vs last month',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        letterSpacing: 0.12,
                        color: AppColors.textGrey,
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.progressTrack,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
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
          SvgPicture.asset(icon, width: 16, height: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 22.5 / 15,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.17,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.entry,
    required this.showDivider,
    this.onTap,
  });

  final _ScheduleEntry entry;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: entry.blocked ? AppColors.progressTrack : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.divider))
                : null,
          ),
          child: _buildRow(),
        ),
      ),
    );
  }

  Widget _buildRow() {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            entry.time,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: 0.06,
              color: entry.blocked ? AppColors.textGrey : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 1,
          height: 36,
          color: entry.blocked
              ? AppColors.borderGrey
              : AppColors.textPrimary.withValues(alpha: 0.15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 19.5 / 13,
                  letterSpacing: -0.08,
                  color: entry.blocked
                      ? AppColors.textGrey
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.subtitle,
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
        if (entry.status != null) _StatusPill(status: entry.status!),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final base = status == 'Confirmed'
        ? const Color(0xFF2A2A2A)
        : AppColors.textGrey555;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: base.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
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

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
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
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(icon, width: 15, height: 15),
              const SizedBox(width: 8),
              Text(
                label,
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
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.highlighted,
    required this.onAccept,
    required this.onDecline,
  });

  final _ClientRequest request;
  final bool highlighted;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.textPrimary : AppColors.borderGrey,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
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
                    ),
                    if (request.urgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Urgent',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: 0.17,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
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
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onDecline,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
          const SizedBox(width: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onAccept,
                child: SizedBox(
                  width: 34,
                  height: 34,
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
