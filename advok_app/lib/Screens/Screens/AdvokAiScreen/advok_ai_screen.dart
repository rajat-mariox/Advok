import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';

const List<String> _suggestions = [
  'What are my rights if I am arrested?',
  'How long do criminal cases take?',
  'Can I sue for wrongful termination?',
  'What is a power of attorney?',
];

class AdvokAiScreen extends StatefulWidget {
  const AdvokAiScreen({super.key});

  @override
  State<AdvokAiScreen> createState() => _AdvokAiScreenState();
}

class _AdvokAiScreenState extends State<AdvokAiScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<({String text, bool fromUser})> _messages = [];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add((text: trimmed, fromUser: true));
      // Placeholder reply until the AI backend is connected.
      _messages.add((
        text:
            'Thanks for your question! AI responses will appear here once '
            'the ADVOK AI backend is connected.',
        fromUser: false,
      ));
    });
    _inputController.clear();
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
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
              ),
              _buildInputBar(),
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
          const SizedBox(width: 8),
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
                  'Legal Assistant · Always On',
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Ask any legal question. I provide instant, accurate guidance '
              'based on US law.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
      itemCount: _messages.length,
      itemBuilder: (_, index) {
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
            child: Text(
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
