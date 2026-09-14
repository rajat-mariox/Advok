import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';

/// One row from the backend's /notifications response.
class _Notification {
  const _Notification({
    required this.title,
    required this.body,
    required this.icon,
    required this.timeLabel,
    required this.unread,
  });

  factory _Notification.fromApi(Map<String, dynamic> json) {
    return _Notification(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      icon: switch (json['type'] as String?) {
        'case_assigned' || 'case_update' => 'assets/icons/ic_briefcase.svg',
        'booking_request' ||
        'booking_accepted' ||
        'booking_declined' =>
          'assets/icons/ic_qa_book.svg',
        'support_reply' || 'query_answered' => 'assets/icons/ic_help.svg',
        _ => 'assets/icons/ic_bell.svg',
      },
      timeLabel: _ago(json['createdAt'] as String?),
      unread: json['readAt'] == null,
    );
  }

  static String _ago(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  final String title;
  final String body;
  final String icon;
  final String timeLabel;
  final bool unread;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with RealtimeRefresh {
  List<_Notification> _notifications = [];
  bool _loading = true;
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
    try {
      await ApiService.markNotificationsRead();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            if (_unreadCount > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 4),
                                child: _buildNewBanner(),
                              ),
                            if (_notifications.isEmpty)
                              _buildEmptyState()
                            else
                              for (final n in _notifications)
                                _NotificationRow(notification: n),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const CircleBackButton(),
          const Expanded(
            child: Text(
              'Notifications',
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
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _unreadCount > 0 ? _markAllRead : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'All read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: _unreadCount > 0
                      ? AppColors.textPrimary
                      : AppColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text(
        '$_unreadCount new notification${_unreadCount == 1 ? '' : 's'}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 16 / 11,
          letterSpacing: -0.08,
          color: AppColors.textPrimary,
        ),
      ),
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
                'assets/icons/ic_bell.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loadError.isNotEmpty
                ? _loadError
                : 'Booking and case updates will appear here.',
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final _Notification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: notification.unread
            ? AppColors.fillGrey.withValues(alpha: 0.6)
            : null,
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Center(
              child: SvgPicture.asset(
                notification.icon,
                width: 17,
                height: 17,
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
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notification.unread
                              ? FontWeight.w800
                              : FontWeight.w600,
                          height: 19.5 / 13,
                          letterSpacing: -0.08,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (notification.unread)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 18 / 12.5,
                    color: AppColors.textGrey555,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textGrey,
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
