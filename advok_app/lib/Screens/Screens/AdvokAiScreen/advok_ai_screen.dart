import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';

/// Fallback chips shown until the admin-managed list loads.
const List<String> _defaultSuggestions = [
  'What are my rights if I am arrested?',
  'How long do criminal cases take?',
  'Can I sue for wrongful termination?',
  'What is a power of attorney?',
];

class AdvokAiScreen extends StatefulWidget {
  const AdvokAiScreen({super.key, this.initialPrompt, this.asSheet = false});

  /// Sent automatically when the screen opens, e.g. "Brief Miranda v.
  /// Arizona" from a case study's AI Case Brief card.
  final String? initialPrompt;

  /// True when shown inside [showAdvokAiSheet]: drag handle, no back button,
  /// rounded top, and a greeting from the assistant's avatar.
  final bool asSheet;

  @override
  State<AdvokAiScreen> createState() => _AdvokAiScreenState();
}

class _AdvokAiScreenState extends State<AdvokAiScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<({String text, bool fromUser})> _messages = [];

  /// True while a reply is in flight — shows the typing bubble and blocks
  /// double-sends.
  bool _sending = false;

  /// Suggested prompts from the admin panel (active ones only).
  List<String> _suggestions = _defaultSuggestions;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(prompt));
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final list = await ApiService.fetchAiSuggestions();
      if (!mounted) return;
      setState(() => _suggestions = list);
    } catch (_) {
      // Keep the defaults if the backend is unreachable.
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;
    _inputController.clear();
    setState(() {
      _messages.add((text: trimmed, fromUser: true));
      _sending = true;
    });
    _scrollToBottom();

    // Send the recent conversation so follow-up questions keep context; the
    // backend trims it further and adds the ADVOK legal-assistant rules.
    final history = [
      for (final m in _messages)
        {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text},
    ];
    String reply;
    try {
      reply = await ApiService.aiChat(history);
      if (reply.isEmpty) {
        reply = 'I could not come up with an answer just now. Please try '
            'rephrasing your question.';
      }
    } on ApiException catch (e) {
      reply = e.statusCode == 503
          ? 'ADVOK AI is not connected yet. Please try again later.'
          : e.statusCode == null
              ? 'Could not reach ADVOK. Check your connection and try again.'
              : e.message;
    } catch (_) {
      reply = 'Something went wrong. Please try again.';
    }
    if (!mounted) return;
    setState(() {
      _messages.add((text: _stripMarkdown(reply), fromUser: false));
      _sending = false;
    });
    _scrollToBottom();
  }

  /// The model is asked for plain text, but strip stray Markdown so the
  /// bubble never shows literal ** or # characters.
  static String _stripMarkdown(String s) => s
      .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
      .trim();

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

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (widget.asSheet)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        _buildHeader(),
        Expanded(
          child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
        ),
        _buildInputBar(),
      ],
    );
    if (widget.asSheet) {
      // Bottom sheet: showAdvokAiSheet already lifts the whole sheet above
      // the keyboard with a viewInsets padding, so this Scaffold must NOT
      // shrink its body again — doing both subtracted the keyboard height
      // twice and overflowed the header/composer on small screens.
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: Scaffold(
            backgroundColor: AppColors.white,
            resizeToAvoidBottomInset: false,
            body: body,
          ),
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: body),
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
          if (!widget.asSheet) ...[
            const CircleBackButton(),
            const SizedBox(width: 8),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_qa_ai.svg',
                width: 17,
                height: 17,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ADVOK AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 20 / 14,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'AI Legal Assistant · Not legal advice',
                  style: TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: AppColors.textGrey555,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_clear.svg',
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textGrey555,
                      BlendMode.srcIn,
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

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ADVOK AI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 24 / 17,
              letterSpacing: 0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.asSheet
                  ? 'Hi! I\'m ADVOK AI. Ask me anything about U.S. law or '
                      'using ADVOK, or pick a question below. I give general '
                      'legal information, not legal advice.'
                  : 'Get general legal information based on U.S. law. ADVOK '
                      'AI is not a lawyer and does not replace advice from a '
                      'licensed attorney.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 21 / 14,
                letterSpacing: -0.15,
                color: AppColors.textGrey555,
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (final suggestion in _suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSuggestionPill(suggestion),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionPill(String text) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => _send(text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == _messages.length) return _buildTypingBubble();
        final message = _messages[index];
        return Align(
          alignment: message.fromUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: message.fromUser
                  ? AppColors.textPrimary
                  : AppColors.fillGrey,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.fromUser ? 18 : 6),
                bottomRight: Radius.circular(message.fromUser ? 6 : 18),
              ),
              border: message.fromUser
                  ? null
                  : Border.all(color: AppColors.borderGrey),
            ),
            child: SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 21 / 14,
                letterSpacing: -0.15,
                color: message.fromUser
                    ? AppColors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textGrey555,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'ADVOK AI is thinking…',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textGrey555,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              decoration: BoxDecoration(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: _send,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Ask a legal question...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    'assets/icons/ic_mic.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textGrey,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _send(_inputController.text),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_send.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
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

/// Opens ADVOK AI as a chat sheet over the current screen (client home,
/// AI banner, quick action). The sheet covers ~92% of the screen, keeps the
/// input above the keyboard and closes with the X or a swipe down.
Future<void> showAdvokAiSheet(BuildContext context, {String? initialPrompt}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.black.withValues(alpha: 0.45),
    builder: (sheetContext) => Padding(
      // Keep the composer above the keyboard inside the sheet.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: AdvokAiScreen(initialPrompt: initialPrompt, asSheet: true),
      ),
    ),
  );
}
