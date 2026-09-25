import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateCasesScreen/advocate_cases_screen.dart' show AdvocateCase;
import '../AdvocateCasesScreen/case_details_screen.dart';
import '../LegalQueriesScreen/legal_queries_screen.dart';
import '../ProfileScreen/support_tickets_screen.dart';

/// One row from the backend's /notifications response.
class _Notification {
  const _Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.unread,
    this.caseId,
    this.bookingId,
    this.ticketId,
    this.queryId,
  });

  factory _Notification.fromApi(Map<String, dynamic> json) {
    return _Notification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      unread: json['readAt'] == null,
      caseId: json['caseId'] as String?,
      bookingId: json['bookingId'] as String?,
      ticketId: json['ticketId'] as String?,
      queryId: json['queryId'] as String?,
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool unread;
  final String? caseId;
  final String? bookingId;
  final String? ticketId;
  final String? queryId;

  /// Icon + short label for the kind of event, so a glance tells what it is.
  String get icon => switch (type) {
        'case_assigned' || 'case_update' => 'assets/icons/ic_briefcase.svg',
        'booking_request' ||
        'booking_accepted' ||
        'booking_declined' =>
          'assets/icons/ic_calendar_dark.svg',
        'support_reply' => 'assets/icons/ic_help.svg',
        'query_answered' => 'assets/icons/ic_qa_book.svg',
        'account_update' => 'assets/icons/ic_shield.svg',
        _ => 'assets/icons/ic_bell.svg',
      };

  String get kind => switch (type) {
        'case_assigned' || 'case_update' => 'Case',
        'booking_request' ||
        'booking_accepted' ||
        'booking_declined' =>
          'Booking',
        'support_reply' => 'Support',
        'query_answered' => 'Legal query',
        'account_update' => 'Account',
        _ => 'Update',
      };

  /// True when tapping can open something more than the row itself.
  bool get opensScreen =>
      (type == 'support_reply' && ticketId != null) ||
      ((type == 'case_assigned' || type == 'case_update') && caseId != null) ||
      type == 'query_answered';

  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final h = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m ${createdAt.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Section header this notification falls under.
  String get dayLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final days = today.difference(day).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return 'This week';
    return 'Earlier';
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with RealtimeRefresh {
  List<_Notification> _notifications = [];
  bool _loading = true;
  bool _unreadOnly = false;
  bool _marking = false;
  String _loadError = '';

  int get _unreadCount => _notifications.where((n) => n.unread).length;

  @override
  void initState() {
    super.initState();
    listenRealtime({'notifications'}, (_) {
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = (data['notifications'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(_Notification.fromApi)
            .toList();
        _loadError = '';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_marking || _unreadCount == 0) return;
    setState(() => _marking = true);
    try {
      await ApiService.markNotificationsRead();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _open(_Notification n) async {
    if (n.unread) {
      // Optimistic: grey the row right away, then tell the backend.
      setState(() {
        _notifications = [
          for (final x in _notifications)
            x.id == n.id
                ? _Notification(
                    id: x.id,
                    type: x.type,
                    title: x.title,
                    body: x.body,
                    createdAt: x.createdAt,
                    unread: false,
                    caseId: x.caseId,
                    bookingId: x.bookingId,
                    ticketId: x.ticketId,
                    queryId: x.queryId,
                  )
                : x,
        ];
      });
      ApiService.markNotificationRead(n.id).catchError((_) {});
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (n.type == 'support_reply' && n.ticketId != null) {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => SupportTicketDetailScreen(ticketId: n.ticketId!),
        ),
      );
    } else if ((n.type == 'case_assigned' || n.type == 'case_update') &&
        n.caseId != null) {
      try {
        final json = await ApiService.fetchCase(n.caseId!);
        if (!mounted) return;
        await nav.push(
          MaterialPageRoute(
            builder: (_) => CaseDetailsScreen(
              caseData: AdvocateCase.fromApi(json),
              isAttorney: Session.role == 'advocate',
            ),
          ),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } else if (n.type == 'query_answered') {
      await nav.push(
        MaterialPageRoute(builder: (_) => const LegalQueriesScreen()),
      );
    }
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _unreadOnly
        ? _notifications.where((n) => n.unread).toList()
        : _notifications;

    // Group into Today / Yesterday / This week / Earlier, keeping order.
    final sections = <String, List<_Notification>>{};
    for (final n in visible) {
      sections.putIfAbsent(n.dayLabel, () => []).add(n);
    }

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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          children: [
                            _buildFilters(),
                            if (visible.isEmpty)
                              _buildEmptyState()
                            else
                              for (final entry in sections.entries) ...[
                                _SectionLabel(
                                  entry.key,
                                  count: entry.value
                                      .where((n) => n.unread)
                                      .length,
                                ),
                                for (final n in entry.value)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _NotificationCard(
                                      notification: n,
                                      onTap: () => _open(n),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canMark = _unreadCount > 0 && !_marking;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const CircleBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 26 / 20,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _unreadCount == 0
                      ? 'You\'re all caught up'
                      : '$_unreadCount unread',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: canMark ? AppColors.textPrimary : AppColors.fillGrey,
            borderRadius: BorderRadius.circular(100),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: canMark ? _markAllRead : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      canMark
                          ? 'assets/icons/ic_check_circle_white.svg'
                          : 'assets/icons/ic_check_circle_dark.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(
                        canMark ? AppColors.white : AppColors.textGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                        color: canMark ? AppColors.white : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, bool active, VoidCallback onTap, {int? badge}) {
      return Material(
        color: active ? AppColors.textPrimary : AppColors.fillGrey,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 16 / 12.5,
                    color: active ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                if (badge != null && badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.white : AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color:
                            active ? AppColors.textPrimary : AppColors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          chip('All', !_unreadOnly, () => setState(() => _unreadOnly = false)),
          const SizedBox(width: 8),
          chip(
            'Unread',
            _unreadOnly,
            () => setState(() => _unreadOnly = true),
            badge: _unreadCount,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.fillGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_bell.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _unreadOnly ? 'No unread notifications' : 'No notifications yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loadError.isNotEmpty
                ? _loadError
                : _unreadOnly
                    ? 'You\'ve read everything.'
                    : 'Booking, case and support updates will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              height: 16 / 11,
              color: AppColors.textGrey,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$count new',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 16 / 11,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final _Notification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Material(
      color: n.unread ? AppColors.fillGrey : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.unread ? AppColors.fillGrey : AppColors.borderGrey,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: n.unread ? AppColors.textPrimary : AppColors.fillGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    n.icon,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      n.unread ? AppColors.white : AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          n.kind.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            height: 14 / 10,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          n.timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 14 / 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                        if (n.unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.textPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            n.unread ? FontWeight.w800 : FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 18 / 12.5,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ],
                    if (n.opensScreen) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            switch (n.type) {
                              'support_reply' => 'Open conversation',
                              'query_answered' => 'View answer',
                              _ => 'View case',
                            },
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 16 / 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SvgPicture.asset(
                            'assets/icons/ic_chevron_right.svg',
                            width: 12,
                            height: 12,
                            colorFilter: const ColorFilter.mode(
                              AppColors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ],
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
