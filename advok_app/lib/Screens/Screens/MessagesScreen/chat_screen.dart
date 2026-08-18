import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateListScreen/advocate_list_screen.dart' show InitialsAvatar;

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String time;
  final bool isMe;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    this.image,
    this.online = false,
    this.specialty,
  });

  final String name;

  /// Photo asset; when null the ADVOK Support bot avatar is shown.
  final String? image;
  final bool online;
  final String? specialty;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          time: TimeOfDay.now().format(context),
          isMe: true,
        ),
      );
      _controller.clear();
    });
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
    final subtitle = [
      widget.online ? 'Online' : 'Offline',
      if (widget.specialty != null) widget.specialty!,
    ].join(' · ');
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const CircleBackButton(),
          const SizedBox(width: 12),
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
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
          const SizedBox(width: 8),
          _buildActionButton(
            'assets/icons/ic_phone.svg',
            onTap: () {
              // TODO: Start a voice call.
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            'assets/icons/ic_video.svg',
            onTap: () {
              // TODO: Start a video call.
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final isBot = widget.image == null;
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isBot
                  ? AppColors.textPrimary.withValues(alpha: 0.13)
                  : const Color(0xFFF7F7F7),
              shape: BoxShape.circle,
            ),
            child: isBot
                ? Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_bot.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : ClipOval(
                    child: widget.image!.isEmpty
                        ? InitialsAvatar(name: widget.name, size: 38)
                        : Image.asset(widget.image!, fit: BoxFit.cover),
                  ),
          ),
          if (widget.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.4),
                ),
              ),
            ),
        ],
      ),
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
              // TODO: Attach a file.
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
