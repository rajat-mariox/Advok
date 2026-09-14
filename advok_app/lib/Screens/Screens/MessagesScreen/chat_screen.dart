import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/document_utils.dart';
import '../AdvocateListScreen/advocate_list_screen.dart'
    show InitialsAvatar, decodePhotoDataUrl;

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
    this.system = false,
    this.meta,
  });

  final String text;
  final String time;
  final bool isMe;

  /// Platform-generated messages (e.g. "case created") render centered.
  final bool system;

  /// Structured payload for template messages — e.g. the client-details
  /// card sent when a consultation is accepted.
  final Map<String, dynamic>? meta;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    this.peerId,
    this.image,
    this.online = false,
    this.specialty,
    this.caseId,
    this.caseNumber,
  });

  final String name;

  /// Backend user id of the other side. When set, the chat is real: messages
  /// load from and send through the API. When null (support bot, screens not
  /// yet wired to a user) messages stay local to this screen.
  final String? peerId;

  /// Photo asset; when null the ADVOK Support bot avatar is shown.
  final String? image;
  final bool online;
  final String? specialty;

  /// Set when the chat was opened from a case workspace. Lets the attorney
  /// request documents from the client in this thread.
  final String? caseId;
  final String? caseNumber;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with RealtimeRefresh {
  List<ChatMessage> _messages = [];

  /// Details about the other side (name, headline, contact, facts), from the
  /// thread API. Attorneys see the client's details, clients the attorney's.
  Map<String, dynamic>? _peer;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;

  /// The document request currently uploading/downloading (disables its
  /// card's button).
  String? _busyRequestId;

  /// The attorney can request documents when the chat was opened from a
  /// case they manage.
  bool get _canRequestDocument =>
      widget.peerId != null &&
      widget.caseId != null &&
      Session.role == 'advocate';

  @override
  void initState() {
    super.initState();
    if (widget.peerId != null) {
      _loadThread(scrollDown: true);
      // Messages arrive live; the slow poll only covers a dropped stream.
      listenRealtime({'messages'}, (e) {
        final peer = e.data?['peerId'];
        if (peer == null || peer == widget.peerId) _loadThread(scrollDown: true);
      });
      _pollTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _loadThread(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static String _timeLabel(String iso) {
    final at = DateTime.tryParse(iso)?.toLocal();
    if (at == null) return '';
    final h = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final m = at.minute.toString().padLeft(2, '0');
    return '$h:$m ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _loadThread({bool scrollDown = false}) async {
    try {
      final data = await ApiService.fetchChat(widget.peerId!);
      if (!mounted) return;
      final me = Session.userId;
      final peer = data['peer'];
      if (peer is Map<String, dynamic>) _peer = peer;
      final list = (data['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final grew = list.length != _messages.length;
      setState(() {
        _messages = [
          for (final m in list)
            ChatMessage(
              text: m['text'] as String? ?? '',
              time: _timeLabel(m['sentAt'] as String? ?? ''),
              isMe: m['fromId'] == me,
              system: m['system'] == true,
              meta: m['meta'] as Map<String, dynamic>?,
            ),
        ];
      });
      if (scrollDown || grew) _scrollToBottom();
    } on ApiException {
      // Keep whatever is on screen; the next poll retries.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    if (widget.peerId == null) {
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(
            text: text,
            time: TimeOfDay.now().format(context),
            isMe: true,
          ),
        ];
        _controller.clear();
      });
      _scrollToBottom();
      return;
    }

    setState(() => _sending = true);
    try {
      await ApiService.sendChatMessage(widget.peerId!, text);
      _controller.clear();
      await _loadThread(scrollDown: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Attorney: ask the client for a document. The backend drops a request
  /// card into this thread and onto the case timeline.
  Future<void> _openRequestDocumentSheet() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RequestDocumentSheet(
        caseId: widget.caseId!,
        caseNumber: widget.caseNumber,
        clientName: widget.name,
      ),
    );
    if (sent == true) await _loadThread(scrollDown: true);
  }

  /// Client: upload the file the attorney asked for on this request card.
  Future<void> _uploadRequestedDocument(Map<String, dynamic> meta) async {
    final caseId = meta['caseId'] as String? ?? '';
    final requestId = meta['requestId'] as String? ?? '';
    if (caseId.isEmpty || requestId.isEmpty || _busyRequestId != null) return;
    setState(() => _busyRequestId = requestId);
    try {
      final picked = await pickCaseDocument();
      if (picked == null || !mounted) return;
      await ApiService.uploadRequestedCaseDocument(
        caseId,
        requestId,
        name: picked.name,
        fileDataUrl: picked.dataUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.name} sent to your attorney.')),
      );
      await _loadThread(scrollDown: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  /// Either side: save the uploaded document from the request card.
  Future<void> _downloadRequestedDocument(Map<String, dynamic> meta) async {
    final caseId = meta['caseId'] as String? ?? '';
    final docId = meta['docId'] as String? ?? '';
    final requestId = meta['requestId'] as String? ?? '';
    if (caseId.isEmpty || docId.isEmpty || _busyRequestId != null) return;
    setState(() => _busyRequestId = requestId);
    try {
      final json = await ApiService.fetchCase(caseId);
      final doc = (json['documents'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .where((d) => d['id'] == docId)
          .firstOrNull;
      final url = doc?['url'] as String? ?? '';
      if (url.isEmpty) {
        throw ApiException('This document is no longer on the case.');
      }
      final name = doc?['name'] as String? ??
          meta['fileName'] as String? ??
          'document';
      final bytes = await documentBytes(url);
      final path = await saveDocumentToDevice(name: name, bytes: bytes);
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name saved.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
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
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final headline = (_peer?['headline'] as String? ?? '').trim();
    final subtitle = [
      widget.online ? 'Online' : 'Offline',
      if (headline.isNotEmpty)
        headline
      else if (widget.specialty != null)
        widget.specialty!,
    ].join(' · ');
    final canShowDetails = widget.peerId != null && _peer != null;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const CircleBackButton(),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: canShowDetails ? _showPeerDetails : null,
            child: _buildAvatar(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canShowDetails ? _showPeerDetails : null,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_peer?['name'] as String?)?.trim().isNotEmpty == true
                      ? _peer!['name'] as String
                      : widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.06,
                    color: AppColors.gradientDarkEnd,
                  ),
                ),
              ],
              ),
            ),
          ),
          if (canShowDetails) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              'assets/icons/ic_info.svg',
              onTap: _showPeerDetails,
            ),
          ],
        ],
      ),
    );
  }

  /// Bottom sheet with the other side's details: an attorney sees the
  /// client's contact and history, a client sees the attorney's practice,
  /// bar admissions, office and contact. Voice consultations are booked from
  /// the attorney's profile, so there are no call buttons here.
  void _showPeerDetails() {
    final peer = _peer;
    if (peer == null) return;
    final name = peer['name'] as String? ?? widget.name;
    final headline = (peer['headline'] as String? ?? '').trim();
    final phone = (peer['phone'] as String? ?? '').trim();
    final email = (peer['email'] as String? ?? '').trim();
    final rows = (peer['rows'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final photoBytes = decodePhotoDataUrl(peer['photo'] as String?);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: photoBytes != null
                          ? Image.memory(
                              photoBytes,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : InitialsAvatar(name: name, size: 56),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (headline.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              headline,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textGrey555,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (phone.isNotEmpty || email.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'CONTACT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fillGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        if (phone.isNotEmpty)
                          _PeerContactRow(
                            icon: 'assets/icons/ic_phone.svg',
                            value: phone,
                            onCopy: () => _copyToClipboard(sheetContext, phone, 'Phone'),
                          ),
                        if (phone.isNotEmpty && email.isNotEmpty)
                          Container(height: 1, color: AppColors.divider),
                        if (email.isNotEmpty)
                          _PeerContactRow(
                            icon: 'assets/icons/ic_mail.svg',
                            value: email,
                            onCopy: () => _copyToClipboard(sheetContext, email, 'Email'),
                          ),
                      ],
                    ),
                  ),
                ],
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.fillGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < rows.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              border: i == rows.length - 1
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(color: AppColors.divider),
                                    ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    rows[i]['label'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                      color: AppColors.textGrey555,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    rows[i]['value'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext sheetContext,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!sheetContext.mounted) return;
    ScaffoldMessenger.of(sheetContext).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Widget _buildAvatar() {
    final isBot = widget.image == null && widget.peerId == null;
    final peerPhoto = decodePhotoDataUrl(_peer?['photo'] as String?);
    final name = (_peer?['name'] as String?)?.trim().isNotEmpty == true
        ? _peer!['name'] as String
        : widget.name;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.borderGrey),
          ),
          clipBehavior: Clip.antiAlias,
          child: isBot
              ? Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_bot.svg',
                    width: 20,
                    height: 20,
                  ),
                )
              : peerPhoto != null
                  ? Image.memory(peerPhoto, fit: BoxFit.cover)
                  : (widget.image == null || widget.image!.isEmpty)
                      ? InitialsAvatar(name: name, size: 38)
                      : Image.asset(widget.image!, fit: BoxFit.cover),
        ),
        if (widget.online)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(String icon, {required VoidCallback onTap}) {
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
            child: SvgPicture.asset(
              icon,
              width: 15,
              height: 15,
              colorFilter: const ColorFilter.mode(
                AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGrey, width: 0.7),
            ),
            child: const Text(
              'Encrypted End-to-End',
              style: TextStyle(
                fontSize: 10,
                height: 1.5,
                letterSpacing: 0.12,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_messages.isEmpty) _buildEmptyState(),
        for (int i = 0; i < _messages.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          if (_messages[i].meta?['kind'] == 'document_request')
            _buildDocumentRequestCard(_messages[i])
          else if (_messages[i].meta?['kind'] == 'consultation_accepted')
            _ConsultationCard(
              meta: _messages[i].meta!,
              time: _messages[i].time,
            )
          else if (_messages[i].system)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.fillGrey,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.borderGrey, width: 0.7),
                ),
                child: Text(
                  _messages[i].text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 16 / 11,
                    letterSpacing: 0.06,
                    color: AppColors.textGrey555,
                  ),
                ),
              ),
            )
          else
            _MessageBubble(
              message: _messages[i],
              image: widget.image,
            ),
        ],
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
                'assets/icons/ic_send.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Send a message to start the conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRequestCard(ChatMessage message) {
    final meta = message.meta!;
    final status = meta['status'] as String? ?? 'pending';
    final requestId = meta['requestId'] as String? ?? '';
    final pending = status != 'uploaded';
    return _DocumentRequestCard(
      meta: meta,
      time: message.time,
      busy: _busyRequestId == requestId,
      // The recipient of the request is the client — they upload.
      onUpload: pending && !message.isMe && Session.role == 'client'
          ? () => _uploadRequestedDocument(meta)
          : null,
      onDownload:
          !pending ? () => _downloadRequestedDocument(meta) : null,
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 16),
      child: Row(
        children: [
          _buildRoundIconButton(
            size: 40,
            icon: 'assets/icons/ic_attachment.svg',
            iconSize: 16,
            onTap: () {
              if (_canRequestDocument) {
                _openRequestDocumentSheet();
              }
              // Plain file attachments are not wired yet.
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              decoration: BoxDecoration(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderGrey, width: 0.7),
              ),
              child: Center(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildRoundIconButton(
            size: 44,
            icon: 'assets/icons/ic_send.svg',
            iconSize: 17,
            onTap: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton({
    required double size,
    required String icon,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: AppColors.borderGrey, width: 0.7),
          ),
          child: Center(
            child: SvgPicture.asset(icon, width: iconSize, height: iconSize),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.image});

  final ChatMessage message;

  /// Sender photo asset shown next to incoming messages.
  final String? image;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.66;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: message.isMe ? null : AppColors.fillGrey,
        gradient: message.isMe
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              )
            : null,
        border: message.isMe
            ? null
            : Border.all(color: AppColors.borderGrey, width: 0.7),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.isMe ? 18 : 4),
          bottomRight: Radius.circular(message.isMe ? 4 : 18),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 14,
          height: 22.75 / 14,
          letterSpacing: -0.15,
          color: message.isMe ? AppColors.white : AppColors.textPrimary,
        ),
      ),
    );

    final timestamp = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message.time,
        style: const TextStyle(
          fontSize: 10,
          height: 1.5,
          letterSpacing: 0.12,
          color: AppColors.textGrey,
        ),
      ),
    );

    if (message.isMe) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [bubble, timestamp],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null && image!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: ClipOval(
              child: Image.asset(image!, width: 28, height: 28,
                  fit: BoxFit.cover),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bubble, timestamp],
        ),
      ],
    );
  }
}

/// Template card for a document request the attorney sent from a case
/// workspace. The client uploads against it; once fulfilled, either side can
/// download the file from the card.
class _DocumentRequestCard extends StatelessWidget {
  const _DocumentRequestCard({
    required this.meta,
    required this.time,
    this.busy = false,
    this.onUpload,
    this.onDownload,
  });

  final Map<String, dynamic> meta;
  final String time;
  final bool busy;

  /// Client-side action while the request is pending.
  final VoidCallback? onUpload;

  /// Available to both sides once the document is uploaded.
  final VoidCallback? onDownload;

  String _s(String key) => (meta[key] as String?)?.trim() ?? '';

  @override
  Widget build(BuildContext context) {
    final docName = _s('docName').isEmpty ? 'Document' : _s('docName');
    final note = _s('note');
    final caseNumber = _s('caseNumber');
    final fileName = _s('fileName');
    final uploaded = meta['status'] == 'uploaded';

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseNumber.isEmpty
                          ? 'DOCUMENT REQUEST'
                          : 'DOCUMENT REQUEST · CASE '
                              '${caseNumber.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 1.0,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_file.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            docName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                              letterSpacing: -0.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: uploaded
                                ? AppColors.textPrimary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.borderGrey),
                          ),
                          child: Text(
                            uploaded ? 'Uploaded' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.06,
                              color: uploaded
                                  ? AppColors.white
                                  : AppColors.textGrey555,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 18 / 12.5,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ],
                    if (uploaded && fileName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: -0.08,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onUpload != null || onDownload != null)
                InkWell(
                  onTap: busy ? null : (onUpload ?? onDownload),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Center(
                      child: Text(
                        busy
                            ? (onUpload != null
                                ? 'Uploading…'
                                : 'Downloading…')
                            : (onUpload != null
                                ? 'Upload Document'
                                : 'Download'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.5,
                          letterSpacing: -0.08,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              letterSpacing: 0.12,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet where the attorney names the document they need from the
/// client; sending it drops a request card into the thread.
class _RequestDocumentSheet extends StatefulWidget {
  const _RequestDocumentSheet({
    required this.caseId,
    this.caseNumber,
    required this.clientName,
  });

  final String caseId;
  final String? caseNumber;
  final String clientName;

  @override
  State<_RequestDocumentSheet> createState() => _RequestDocumentSheetState();
}

class _RequestDocumentSheetState extends State<_RequestDocumentSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSend => _nameController.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService.requestCaseDocument(
        widget.caseId,
        name: _nameController.text.trim(),
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request a Document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.clientName} gets an upload card in this chat'
            '${widget.caseNumber == null ? '' : ' for case ${widget.caseNumber}'}.',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: _nameController,
            hint: 'Document needed (e.g. Signed retainer agreement)',
          ),
          const SizedBox(height: 10),
          _buildInput(
            controller: _noteController,
            hint: 'Note to the client (optional)',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _canSend && !_sending
                      ? [AppColors.textPrimary, AppColors.gradientDarkEnd]
                      : [AppColors.progressTrack, AppColors.progressTrack],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _canSend && !_sending ? _send : null,
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        _sending ? 'Sending…' : 'Send Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          color: _canSend && !_sending
                              ? AppColors.white
                              : AppColors.textGrey,
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
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 13.5,
          letterSpacing: -0.08,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            letterSpacing: -0.08,
            color: AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

/// Template card dropped into the thread when the advocate accepts a
/// consultation request — shows the attorney's contact details so the
/// client can call them directly.
class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.meta, required this.time});

  final Map<String, dynamic> meta;
  final String time;

  String _s(String key) => (meta[key] as String?)?.trim() ?? '';

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Phone number copied: $phone')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _s('attorneyName').isEmpty ? 'Attorney' : _s('attorneyName');
    final phone = _s('attorneyPhone');
    final photoBytes = decodePhotoDataUrl(_s('attorneyPhoto'));
    final amount = meta['amount'];
    final rows = <(String, String)>[
      if (_s('attorneyEmail').isNotEmpty) ('Email', _s('attorneyEmail')),
      if (_s('consultationType').isNotEmpty)
        ('Consultation', _s('consultationType')),
      if (_s('date').isNotEmpty || _s('time').isNotEmpty)
        ('Date & Time', '${_s('date')} · ${_s('time')}'),
      if (amount is num && amount > 0)
        ('Fee', '\$${amount.toStringAsFixed(2)}'),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONSULTATION CONFIRMED · ATTORNEY CONTACT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 1.0,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: ClipOval(
                            child: photoBytes == null
                                ? InitialsAvatar(name: name, size: 40)
                                : Image.memory(
                                    photoBytes,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                              letterSpacing: -0.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tappable call row — the client talks to the attorney on a
              // call, so the number leads the card and copies on tap.
              if (phone.isNotEmpty)
                InkWell(
                  onTap: () => _copyPhone(context, phone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_phone.svg',
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                              letterSpacing: -0.08,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Text(
                          'Tap to copy',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            letterSpacing: 0.06,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (int i = 0; i < rows.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppColors.divider)),
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
                      Flexible(
                        child: Text(
                          rows[i].$2,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            letterSpacing: -0.08,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              height: 1.5,
              letterSpacing: 0.12,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }
}

class _PeerContactRow extends StatelessWidget {
  const _PeerContactRow({
    required this.icon,
    required this.value,
    required this.onCopy,
  });

  final String icon;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCopy,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 15, height: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SvgPicture.asset('assets/icons/ic_copy_link.svg', width: 14, height: 14),
          ],
        ),
      ),
    );
  }
}
