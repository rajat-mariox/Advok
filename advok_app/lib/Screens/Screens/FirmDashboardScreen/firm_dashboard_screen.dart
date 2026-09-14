import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dart:typed_data';

import '../../../CommonWidgets/session_avatar.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateListScreen/advocate_list_screen.dart'
    show InitialsAvatar, decodePhotoDataUrl;
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


/// A pending consultation request a client sent to this firm.
class _ClientRequest {
  const _ClientRequest({
    required this.id,
    required this.name,
    required this.matter,
    required this.timeAgo,
    this.photoBytes,
    this.requestedName,
    this.requestedIndex,
  });

  final String id;
  final String name;
  final String matter;
  final String timeAgo;
  final Uint8List? photoBytes;

  /// Set when the client picked one of the firm's attorneys directly.
  final String? requestedName;
  final int? requestedIndex;
}

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

  /// Builds a card from the backend's /cases response (firm view: every
  /// case opened by an attorney on the firm's team).
  factory FirmCase.fromApi(Map<String, dynamic> json) {
    String cap(String s) =>
        s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    String fmt(String? iso) {
      final d = iso == null ? null : DateTime.tryParse(iso);
      if (d == null) return '—';
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${m[d.month - 1]} ${d.day}, ${d.year}';
    }
    return FirmCase(
      number: json['caseNumber'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled case',
      client: json['clientName'] as String? ?? 'Client',
      lawyer: json['advocateName'] as String? ?? 'Attorney',
      status: cap(json['status'] as String? ?? 'active'),
      nextDate: fmt(json['nextHearing'] as String?),
      priority: cap(json['priority'] as String? ?? 'medium'),
      filed: fmt((json['filedDate'] ?? json['createdAt']) as String?),
    );
  }

  final String number;
  final String title;
  final String client;
  final String lawyer;
  final String status;
  final String nextDate;
  final String priority;
  final String filed;
}


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

class _FirmDashboardScreenState extends State<FirmDashboardScreen> with RealtimeRefresh {
  int _tab = 0;
  int _caseFilter = 0;

  static const List<String> _tabs = [
    'Overview',
    'Attorneys',
    'Cases',
    'Calendar',
  ];

  static const List<String> _caseFilters = [
    'All',
    'Active',
    'Hearing',
    'Closed',
  ];

  /// Pending requests from the backend (bookings where this firm is the
  /// provider). Accept/decline go through the same endpoints attorneys use.
  List<_ClientRequest> _pendingRequests = [];
  final Set<String> _respondingIds = <String>{};

  /// Cases opened by the firm's attorneys (backend, firm view).
  List<FirmCase> _cases = [];

  /// Today's confirmed consultations booked with the firm, one row per call:
  /// which attorney, which client, what time.
  List<_Hearing> _hearings = [];

  /// Revenue from consultations clients booked with the firm (confirmed or
  /// completed), regardless of which attorney was assigned.
  double _totalRevenue = 0;
  double _monthRevenue = 0;
  int _paidConsultations = 0;

  /// Lawyers the firm added during onboarding, mapped onto the card model.
  final List<_Lawyer> _lawyers = _lawyersFromSession();

  static List<_Lawyer> _lawyersFromSession() {
    final raw = Session.profile?['lawyers'];
    if (raw is! List) return [];
    return [
      for (final entry in raw)
        if (entry is Map)
          _Lawyer(
            name: _entryField(entry, 'fullName', 'Unnamed Attorney'),
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
    if (designation.isEmpty && expertise.isEmpty) return 'Attorney';
    if (designation.isEmpty) return expertise;
    if (expertise.isEmpty) return designation;
    return '$designation · $expertise';
  }

  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    listenRealtime({'bookings', 'cases'}, (_) {
      _loadRequests();
      _loadCases();
    });
    _loadRequests();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      final result = await ApiService.fetchCases();
      if (!mounted) return;
      setState(() => _cases = result.map(FirmCase.fromApi).toList());
    } on ApiException {
      // Keep the empty state.
    }
  }

  static String _timeAgo(String? iso) {
    final t = iso == null ? null : DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Future<void> _loadRequests() async {
    final List<Map<String, dynamic>> result;
    try {
      result = await ApiService.fetchBookings();
    } on ApiException {
      return; // Dashboard still renders with its empty state.
    }
    if (!mounted) return;
    final requests = <_ClientRequest>[];
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final todayIso = '$monthKey-${now.day.toString().padLeft(2, '0')}';
    double total = 0;
    double month = 0;
    int paid = 0;
    final today = <({int minutes, _Hearing row})>[];
    for (final b in result) {
      if (b['incoming'] != true) continue;
      final status = b['status'] as String?;
      if (status == 'confirmed' || status == 'completed') {
        final amount = (b['amount'] as num?)?.toDouble() ?? 0;
        total += amount;
        paid += 1;
        if ((b['date'] as String? ?? '').startsWith(monthKey)) month += amount;
      }
      if (status == 'confirmed' && b['date'] == todayIso) {
        final time = b['time'] as String? ?? '';
        final attorney =
            ((b['assignedAttorney'] as Map<String, dynamic>?)?['name'] as String?)
                    ?.trim() ??
                '';
        final client = b['clientName'] as String? ?? 'Client';
        final kind = switch (b['consultationType'] as String? ?? '') {
          'phone_call' => 'Voice call',
          'office_visit' => 'Office visit',
          _ => 'Video call',
        };
        today.add((
          minutes: _slotMinutes(time),
          row: _Hearing(
            time: time,
            title: attorney.isEmpty
                ? '$kind with $client'
                : '$attorney · $kind with $client',
            subtitle: attorney.isEmpty
                ? 'No attorney assigned yet'
                : "$attorney's consultation · billed to the firm",
          ),
        ));
      }
      if (status != 'pending') continue;
      final date = b['date'] as String? ?? '';
      final day = DateTime.tryParse(date);
      final dateLabel =
          day == null ? date : '${_monthLabels[day.month - 1]} ${day.day}';
      final kind = switch (b['consultationType'] as String? ?? '') {
        'phone_call' => 'Phone Call',
        'office_visit' => 'Office Visit',
        _ => 'Video Call',
      };
      final requested = b['requestedAttorney'] as Map<String, dynamic>?;
      final requestedName = (requested?['name'] as String? ?? '').trim();
      requests.add(_ClientRequest(
        id: b['id'] as String? ?? '',
        name: b['clientName'] as String? ?? 'Client',
        matter: '$kind · $dateLabel, ${b['time'] as String? ?? ''}'
            '${requestedName.isNotEmpty ? ' · For $requestedName' : ''}',
        timeAgo: _timeAgo(b['createdAt'] as String?),
        photoBytes: decodePhotoDataUrl(b['clientPhoto'] as String?),
        requestedName: requestedName.isEmpty ? null : requestedName,
        requestedIndex: (requested?['index'] as num?)?.toInt(),
      ));
    }
    today.sort((a, b) => a.minutes.compareTo(b.minutes));
    setState(() {
      _pendingRequests = requests;
      _hearings = [for (final t in today) t.row];
      _totalRevenue = total;
      _monthRevenue = month;
      _paidConsultations = paid;
    });
  }

  /// '10:00 AM' -> minutes since midnight, for ordering today's rows.
  static int _slotMinutes(String time) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
        .firstMatch(time.trim());
    if (m == null) return 0;
    var h = int.parse(m.group(1)!) % 12;
    if (m.group(3)!.toUpperCase() == 'PM') h += 12;
    return h * 60 + int.parse(m.group(2)!);
  }

  static String _money(double v) {
    final whole = v.truncateToDouble() == v;
    return '\$${whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
  }

  /// Team attorneys from the firm's onboarding, in the order the backend
  /// keeps them (the index is what the accept call sends).
  List<Map<dynamic, dynamic>> get _teamEntries {
    final raw = Session.profile?['lawyers'];
    if (raw is! List) return const [];
    return [for (final e in raw) if (e is Map) e];
  }

  /// Asks which attorney will handle the consultation; null = cancelled.
  Future<int?> _pickAttorney(_ClientRequest request) {
    final team = _teamEntries;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Assign an attorney',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.31,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                request.requestedName == null
                    ? 'Who will handle ${request.name}\'s consultation? Their '
                        'name and contact details are shared with the client.'
                    : '${request.name} asked for ${request.requestedName}. '
                        'Confirm them or pick someone else. Their contact '
                        'details are shared with the client.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textGrey555,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                itemCount: team.length,
                itemBuilder: (_, i) {
                  final e = team[i];
                  final name = _entryField(e, 'fullName', 'Attorney ${i + 1}');
                  final sub = [
                    _entryField(e, 'designation', ''),
                    _entryField(e, 'barState', ''),
                  ].where((x) => x.isNotEmpty).join(' · ');
                  final isRequested = request.requestedIndex == i;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isRequested ? AppColors.fillGrey : null,
                    leading: InitialsAvatar(name: name, size: 36),
                    trailing: isRequested
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              'Requested',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          )
                        : null,
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: sub.isEmpty
                        ? null
                        : Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey555,
                            ),
                          ),
                    onTap: () => Navigator.of(sheetContext).pop(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(_ClientRequest request, {required bool accept}) async {
    int? attorneyIndex;
    if (accept && _teamEntries.isNotEmpty) {
      if (request.requestedIndex != null) {
        // Client booked this attorney directly: accept assigns them, no
        // picker.
        attorneyIndex = request.requestedIndex;
      } else {
        attorneyIndex = await _pickAttorney(request);
        if (attorneyIndex == null || !mounted) return; // cancelled
      }
    }
    if (!_respondingIds.add(request.id)) return;
    setState(() {});
    try {
      await ApiService.respondToBooking(
        request.id,
        accept: accept,
        attorneyIndex: attorneyIndex,
      );
      if (accept && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attorneyIndex == null
                  ? "${request.name} confirmed — your firm's contact details "
                      'were shared with them.'
                  : '${request.name} confirmed — '
                      '${_entryField(_teamEntries[attorneyIndex], 'fullName', 'the attorney')} '
                      'was assigned and their contact details were shared.',
            ),
          ),
        );
      }
      await _loadRequests();
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

  void _declineRequest(_ClientRequest request) =>
      _respond(request, accept: false);

  void _acceptRequest(_ClientRequest request) =>
      _respond(request, accept: true);

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
          "Today's Schedule",
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
              'Our Attorneys',
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
            title: 'No attorneys yet',
            message: 'Attorneys added during onboarding will appear here.',
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
            message: 'Cases your attorneys open for clients will appear here.',
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
                        label: 'Attorney',
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
                                  'Message Attorney',
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
            Expanded(
              child: _FirmStatCard(
                icon: 'assets/icons/ic_stat_revenue.svg',
                badge: _paidConsultations > 0
                    ? '$_paidConsultations paid'
                    : '—',
                value: _money(_totalRevenue),
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
                label: 'Our Attorneys',
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
            'No consultations or hearings today',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _RevenueFigure(
                  label: 'Total earned',
                  value: _money(_totalRevenue),
                ),
              ),
              Expanded(
                child: _RevenueFigure(
                  label: 'This month',
                  value: _money(_monthRevenue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Text(
              _paidConsultations == 0
                  ? 'Consultations clients book with your firm are billed to '
                      'the firm and show here once confirmed.'
                  : '$_paidConsultations confirmed consultation'
                      '${_paidConsultations == 1 ? '' : 's'} booked with your '
                      'firm. Billed to the firm, not the assigned attorney.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
                color: AppColors.textGrey,
              ),
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

class _RevenueFigure extends StatelessWidget {
  const _RevenueFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            letterSpacing: 0.06,
            color: AppColors.textGrey555,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.5,
            letterSpacing: -0.26,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
