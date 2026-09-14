import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/session_avatar.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../AdvocateCasesScreen/advocate_cases_screen.dart';
import '../AdvocateCasesScreen/case_details_screen.dart';
import '../AdvocateListScreen/advocate_list_screen.dart'
    show InitialsAvatar, decodePhotoDataUrl;
import '../MessagesScreen/chat_screen.dart';
import '../NotificationScreen/notification_screen.dart';

class _ScheduleEntry {
  const _ScheduleEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    this.status,
    this.clientId,
    // ignore: unused_element_parameter — reserved for blocked-off slots.
    this.blocked = false,
  });

  final String time;
  final String title;
  final String subtitle;
  final String? status;

  /// Backend user id of the client, for opening the chat.
  final String? clientId;
  final bool blocked;
}

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

/// A pending consultation request (any consultation type waiting for the
/// advocate to accept or decline), built from the backend's /bookings
/// response.
class _VisitRequest {
  const _VisitRequest({
    required this.id,
    required this.name,
    required this.matter,
    required this.timeAgo,
    this.photoBytes,
  });

  final String id;
  final String name;
  final String matter;
  final String timeAgo;
  final Uint8List? photoBytes;
}

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

class _AdvocateDashboardScreenState extends State<AdvocateDashboardScreen> with RealtimeRefresh {
  int _tab = 0;

  List<String> get _tabs =>
      ['Today', CountryCatalog.terms.hearingsLabel, 'Tasks'];

  /// Incoming consultation requests waiting for this advocate's answer.
  List<_VisitRequest> _pendingRequests = [];

  /// Today's confirmed appointments.
  List<_ScheduleEntry> _schedule = [];

  /// This advocate's cases, from the backend.
  List<AdvocateCase> _cases = [];

  /// Confirmed-booking earnings per month for the last 7 months (oldest
  /// first) and the all-time total, from the backend's /bookings.
  List<double> _monthEarnings = List.filled(7, 0);
  List<String> _monthEarningLabels = List.filled(7, '');
  double _totalRevenue = 0;

  /// Ids the advocate is currently responding to (buttons disabled).
  final Set<String> _respondingIds = {};

  /// Upcoming court events across this advocate's open cases, soonest first.
  List<_Hearing> get _hearings {
    final rows = [
      for (final c in _cases)
        if (c.nextHearingIso != null && c.status != CaseStatus.closed)
          (
            iso: c.nextHearingIso!,
            hearing: _Hearing(
              date: c.nextHearing!,
              time: c.status.label,
              caseNumber: c.number,
              matter: c.title,
              court: c.court,
            ),
          ),
    ]..sort((a, b) => a.iso.compareTo(b.iso));
    return [for (final r in rows) r.hearing];
  }

  String get _revenueLabel => '\$${_totalRevenue.toStringAsFixed(0)}';

  /// This month's earnings and the growth vs last month, for the chart card.
  double get _thisMonthEarnings =>
      _monthEarnings.isEmpty ? 0 : _monthEarnings.last;

  String get _monthGrowthLabel {
    if (_monthEarnings.length < 2) return '+0%';
    final last = _monthEarnings[_monthEarnings.length - 2];
    if (last <= 0) return _thisMonthEarnings > 0 ? '+100%' : '+0%';
    final pct = ((_thisMonthEarnings - last) / last * 100).round();
    return '${pct >= 0 ? '+' : ''}$pct%';
  }

  @override
  void initState() {
    super.initState();
    listenRealtime({'bookings', 'cases', 'clients'}, (_) {
      _loadBookings();
      _loadCases();
    });
    _loadBookings();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      final result = await ApiService.fetchCases();
      if (!mounted) return;
      setState(() {
        _cases = result.map(AdvocateCase.fromApi).toList();
      });
    } on ApiException {
      // Dashboard still renders with its empty states.
    }
  }

  static String _typeLabel(String kind) => switch (kind) {
        'office_visit' => 'Office Visit',
        'phone_call' => 'Phone Call',
        _ => 'Video Call',
      };

  static String _timeAgo(String? createdAt) {
    final created = DateTime.tryParse(createdAt ?? '');
    if (created == null) return '';
    final diff = DateTime.now().difference(created.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  /// Loads this advocate's bookings: pending ones become requests to accept
  /// or decline, today's confirmed ones fill the schedule card.
  Future<void> _loadBookings() async {
    final List<Map<String, dynamic>> result;
    try {
      result = await ApiService.fetchBookings();
    } on ApiException {
      return; // Dashboard still renders with its empty states.
    }
    if (!mounted) return;

    final now = DateTime.now();
    final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final requests = <_VisitRequest>[];
    final schedule = <_ScheduleEntry>[];

    // Earnings from confirmed consultations: all-time total plus the last
    // 7 months for the chart (oldest first, current month last).
    double totalRevenue = 0;
    final monthEarnings = List<double>.filled(7, 0);
    final monthLabels = <String>[];
    final monthKeys = <String>[];
    for (int i = 6; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      monthLabels.add(_monthLabels[m.month - 1]);
      monthKeys.add('${m.year}-${m.month.toString().padLeft(2, '0')}');
    }

    for (final b in result) {
      final status = b['status'] as String?;
      final kind = b['consultationType'] as String? ?? 'video_call';
      final name = b['clientName'] as String? ?? 'Client';
      final date = b['date'] as String? ?? '';
      final time = b['time'] as String? ?? '';
      // Consultations booked through a law firm are billed to the firm, so
      // they show in the firm's revenue, not the assigned attorney's.
      final billedToMe = b['advocateId'] == Session.userId;
      if (billedToMe && (status == 'confirmed' || status == 'completed')) {
        final amount = (b['amount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;
        final key = date.length >= 7 ? date.substring(0, 7) : '';
        final slot = monthKeys.indexOf(key);
        if (slot >= 0) monthEarnings[slot] += amount;
      }
      if (status == 'pending') {
        final day = DateTime.tryParse(date);
        final dateLabel = day == null
            ? date
            : '${_monthLabels[day.month - 1]} ${day.day}';
        requests.add(_VisitRequest(
          id: b['id'] as String? ?? '',
          name: name,
          matter: '${_typeLabel(kind)} · $dateLabel, $time',
          timeAgo: _timeAgo(b['createdAt'] as String?),
          photoBytes: decodePhotoDataUrl(b['clientPhoto'] as String?),
        ));
      } else if (status == 'confirmed' && date == todayIso) {
        // Assigned by a law firm: say so, keep the type last (the row
        // reads the matter from the last segment).
        final viaFirm = b['advocateId'] != Session.userId
            ? (b['firmName'] as String? ?? '').trim()
            : '';
        schedule.add(_ScheduleEntry(
          time: time,
          title: name,
          subtitle: viaFirm.isEmpty
              ? _typeLabel(kind)
              : 'via $viaFirm · ${_typeLabel(kind)}',
          status: 'Confirmed',
          clientId: b['clientId'] as String?,
        ));
      }
    }
    setState(() {
      _pendingRequests = requests;
      _schedule = schedule;
      _totalRevenue = totalRevenue;
      _monthEarnings = monthEarnings;
      _monthEarningLabels = monthLabels;
    });
  }

  Future<void> _respondToRequest(
    _VisitRequest request, {
    required bool accept,
  }) async {
    if (!_respondingIds.add(request.id)) return;
    setState(() {});
    try {
      await ApiService.respondToBooking(request.id, accept: accept);
      if (accept && mounted) {
        // Backend created the client relationship and texted the client
        // this advocate's contact details.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${request.name} added to My Clients — your contact details '
              'were shared with them.',
            ),
          ),
        );
      }
      await _loadBookings();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      _respondingIds.remove(request.id);
      if (mounted) setState(() {});
    }
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
                      busy: _respondingIds.contains(request.id),
                      onAccept: () =>
                          _respondToRequest(request, accept: true),
                      onDecline: () =>
                          _respondToRequest(request, accept: false),
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
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_bell.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onProfileTap,
            child: SessionAvatar(
              borderRadius: BorderRadius.circular(16),
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
          Expanded(
            child: _StatCard(
              icon: 'assets/icons/ic_stat_revenue.svg',
              value: _revenueLabel,
              label: 'Revenue',
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: _StatCard(
              icon: 'assets/icons/ic_stat_cases.svg',
              value: '${_cases.length}',
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
                            _openClientChat(
                              entry.title,
                              matter: matter,
                              peerId: entry.clientId,
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
                              final matches = _cases
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
        _cases.where((c) => c.number == caseNumber).toList();
    if (matches.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseDetailsScreen(caseData: matches.first),
      ),
    );
  }

  void _openClientChat(String name, {String? matter, String? peerId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          name: name,
          peerId: peerId,
          online: true,
          specialty: matter,
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
            Text(
              'Upcoming ${CountryCatalog.terms.hearingsLabel}',
              style: const TextStyle(
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
              title: 'No court events scheduled',
              message:
                  'Court events appear here when a case has its next '
                  'court event set.',
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
                          final matches = _cases
                              .where((c) => c.number == hearing.caseNumber)
                              .toList();
                          if (matches.isEmpty) return;
                          _openClientChat(
                            matches.first.client,
                            matter: matches.first.title,
                            peerId: matches.first.clientId,
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
    final maxEarning = _monthEarnings.fold<double>(0, (m, e) => e > m ? e : m);
    final bars = [
      for (final e in _monthEarnings) maxEarning > 0 ? e / maxEarning * 80 : 0.0,
    ];
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
                for (int i = 0; i < bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: bars[i],
                      decoration: BoxDecoration(
                        color: i == bars.length - 1
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
              for (int i = 0; i < _monthEarningLabels.length; i++)
                Text(
                  _monthEarningLabels[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.17,
                    color: i == _monthEarningLabels.length - 1
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
                  children: [
                    const Text(
                      'This month',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        letterSpacing: 0.06,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    Text(
                      '\$${_thisMonthEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
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
                          Text(
                            _monthGrowthLabel,
                            style: const TextStyle(
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
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final _VisitRequest request;
  final bool highlighted;

  /// True while the accept/decline call is in flight (buttons disabled).
  final bool busy;
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
            child: request.photoBytes != null
                ? Image.memory(
                    request.photoBytes!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  )
                : InitialsAvatar(name: request.name, size: 46),
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
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: busy ? null : onDecline,
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
                onTap: busy ? null : onAccept,
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
