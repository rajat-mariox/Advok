import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvokAiScreen/advok_ai_screen.dart';

class CaseStudy {
  const CaseStudy({
    required this.title,
    required this.meta,
    required this.tag,
    required this.mins,
    required this.level,
    required this.summary,
  });

  final String title;
  final String meta;
  final String tag;
  final String mins;
  final String level;
  final String summary;

  String get principle =>
      'This case established a foundational precedent in $tag. It is '
      'frequently cited in subsequent rulings and remains a cornerstone of '
      'legal education in the United States.';
}

class CaseStudyScreen extends StatefulWidget {
  const CaseStudyScreen({
    super.key,
    required this.caseStudy,
    required this.saved,
    required this.onToggleSaved,
  });

  final CaseStudy caseStudy;
  final bool saved;

  /// Keeps the bookmark state in sync with the list on the home screen.
  final VoidCallback onToggleSaved;

  @override
  State<CaseStudyScreen> createState() => _CaseStudyScreenState();
}

class _CaseStudyScreenState extends State<CaseStudyScreen> {
  late bool _saved = widget.saved;

  @override
  Widget build(BuildContext context) {
    final data = widget.caseStudy;
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Pill(data.tag),
                          const SizedBox(width: 8),
                          _Pill(data.level),
                          const SizedBox(width: 8),
                          _Pill(data.mins),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 32 / 24,
                          letterSpacing: -0.59,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.meta,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 22 / 15,
                          letterSpacing: -0.23,
                          color: AppColors.textGrey555,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 20),
                      const _SectionCaption('SUMMARY'),
                      const SizedBox(height: 10),
                      Text(
                        data.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 22 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionCaption('KEY LEGAL PRINCIPLE'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.fillGrey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          data.principle,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 21 / 13,
                            letterSpacing: -0.08,
                            color: AppColors.textGrey555,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionCaption('STUDY WITH AI'),
                      const SizedBox(height: 10),
                      _buildAiBriefCard(),
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
              'Case Study',
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
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _saved = !_saved);
              widget.onToggleSaved();
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                'assets/icons/ic_bookmark.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  _saved ? AppColors.textPrimary : AppColors.textGrey,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBriefCard() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdvokAiScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_bot.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Generate AI Case Brief',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Summarize, explain, and quiz yourself',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/ic_chevron_right_grey.svg',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 16 / 11,
          letterSpacing: -0.08,
          color: AppColors.textGrey555,
        ),
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 1.8,
        color: AppColors.textGrey,
      ),
    );
  }
}
