import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateListScreen/advocate_list_screen.dart'
    show InitialsAvatar, decodePhotoDataUrl;
import 'chat_screen.dart';

/// One conversation row from the backend's /messages/threads response.
class _Thread {
  const _Thread({
    required this.peerId,
    required this.name,
    required this.lastMessage,
    required this.timeLabel,
    required this.unread,
    this.photoBytes,
  });

  factory _Thread.fromApi(Map<String, dynamic> json) {
    return _Thread(
      peerId: json['peerId'] as String? ?? '',
      name: json['peerName'] as String? ?? 'User',
      lastMessage: (json['lastFromMe'] == true ? 'You: ' : '') +
          (json['lastMessage'] as String? ?? ''),
      timeLabel: _ago(json['lastAt'] as String?),
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      photoBytes: decodePhotoDataUrl(json['peerPhoto'] as String?),
    );
  }

  static String _ago(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  final String peerId;
  final String name;
  final String lastMessage;
  final String timeLabel;
  final int unread;
  final Uint8List? photoBytes;
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.onBack});

  /// Back action. Inside a nav shell this switches to the Home tab; when the
  /// screen was pushed on its own it pops.
  final VoidCallback? onBack;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with RealtimeRefresh {
  List<_Thread> _threads = [];
  bool _loading = true;
  String _loadError = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    listenRealtime({'messages'}, (_) {
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchThreads();
      if (!mounted) return;
      setState(() {
        _threads = result.map(_Thread.fromApi).toList();
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

  List<_Thread> get _filtered {
    if (_query.isEmpty) return _threads;
    final q = _query.toLowerCase();
    return _threads
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openThread(_Thread thread) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          name: thread.name,
          peerId: thread.peerId,
          online: true,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final threads = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              CircleBackButton(onTap: widget.onBack),
              const SizedBox(width: 12),
              const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 28 / 20,
                  letterSpacing: -0.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_search.svg',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: threads.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [_buildEmptyState()],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: threads.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _ThreadCard(
                            thread: threads[i],
                            onTap: () => _openThread(threads[i]),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final failed = _loadError.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
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
              child: failed
                  ? const Icon(
                      Icons.wifi_off_rounded,
                      size: 26,
                      color: AppColors.textGrey555,
                    )
                  : SvgPicture.asset(
                      'assets/icons/ic_compose.svg',
                      width: 24,
                      height: 24,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            failed ? "Couldn't load messages" : 'No messages yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            failed
                ? _loadError
                : 'Conversations open here once you are connected with '
                    'the other side.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderGrey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread, required this.onTap});

  final _Thread thread;
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: ClipOval(
                  child: thread.photoBytes == null
                      ? InitialsAvatar(name: thread.name, size: 46)
                      : Image.memory(thread.photoBytes!, fit: BoxFit.cover),
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
                            thread.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: -0.08,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          thread.timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 17 / 12.5,
                              fontWeight: thread.unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: thread.unread > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textGrey555,
                            ),
                          ),
                        ),
                        if (thread.unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${thread.unread}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
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
