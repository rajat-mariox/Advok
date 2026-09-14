import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvokAiScreen/advok_ai_screen.dart';
import 'case_notes_screen.dart';

/// A curated court opinion from the backend's /learning/cases list.
class CaseStudy {
  const CaseStudy({
    required this.id,
    required this.title,
    required this.meta,
    required this.tag,
    required this.mins,
    required this.level,
    required this.summary,
    required this.principle,
    this.court = '',
    this.year = '',
    this.citation = '',
    this.judges = '',
    this.hasFullText = false,
    this.hasNotes = false,
  });

  factory CaseStudy.fromApi(Map<String, dynamic> json) {
    final court = json['court'] as String? ?? '';
    final year = json['year'] as String? ?? '';
    final citation = json['citation'] as String? ?? '';
    final mins = (json['mins'] as num?)?.toInt() ?? 5;
    final tag = json['tag'] as String? ?? 'US Law';
    return CaseStudy(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled case',
      meta: [court, year].where((s) => s.isNotEmpty).join(' · '),
      tag: tag,
      mins: '$mins min read',
      level: json['level'] as String? ?? 'Intermediate',
      summary: json['summary'] as String? ?? '',
      principle: json['principle'] as String? ?? '',
      court: court,
      year: year,
      citation: citation,
      judges: json['judges'] as String? ?? '',
      hasFullText: json['hasFullText'] == true,
      hasNotes: json['hasNotes'] == true,
    );
  }

  final String id;
  final String title;
  final String meta;
  final String tag;
  final String mins;
  final String level;
  final String summary;
  final String principle;
  final String court;
  final String year;
  final String citation;
  final String judges;
  final bool hasFullText;

  /// True once ADVOK AI's study notes for this case are cached on the backend.
  final bool hasNotes;
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

  /// Syllabus and full opinion text, loaded on open (can be long).
  String _syllabus = '';
  String _opinionText = '';
  bool _loadingText = true;
  bool _showFullOpinion = false;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  Future<void> _loadText() async {
    if (widget.caseStudy.id.isEmpty) {
      setState(() => _loadingText = false);
      return;
    }
    try {
      final data = await ApiService.fetchCaseStudy(widget.caseStudy.id);
      if (!mounted) return;
      setState(() {
        _syllabus = (data['syllabus'] as String? ?? '').trim();
        _opinionText = (data['opinionText'] as String? ?? '').trim();
        _loadingText = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingText = false);
    }
  }

  void _openAiBrief() {
    final c = widget.caseStudy;
    final cite = c.citation.isNotEmpty ? ' (${c.citation})' : '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvokAiScreen(
          initialPrompt:
              'Give me a law-school style case brief of ${c.title}$cite, '
              '${c.court}${c.year.isNotEmpty ? ' ${c.year}' : ''}: facts, '
              'issue, holding, reasoning, and why it matters for $tagLower.',
        ),
      ),
    );
  }

  String get tagLower => widget.caseStudy.tag.toLowerCase();

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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(data.tag),
                          _Pill(data.level),
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
                        [data.meta, data.citation]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 22 / 15,
                          letterSpacing: -0.23,
                          color: AppColors.textGrey555,
                        ),
                      ),
                      if (data.judges.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Justices: ${data.judges}',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(height: 1, color: AppColors.divider),
                      const SizedBox(height: 20),
                      const _SectionCaption('SUMMARY'),
                      const SizedBox(height: 10),
                      SelectableText(
                        data.summary.isEmpty
                            ? 'No summary has been added for this case yet.'
                            : data.summary,
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
                          data.principle.isEmpty
                              ? 'This case is a frequently cited precedent in '
                                  '${data.tag}.'
                              : data.principle,
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
                      const SizedBox(height: 10),
                      _buildNotesCard(),
                      if (_loadingText) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ],
                      if (!_loadingText && _syllabus.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionCaption('COURT SYLLABUS'),
                        const SizedBox(height: 10),
                        SelectableText(
                          _syllabus,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 22 / 13.5,
                            letterSpacing: -0.1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      if (!_loadingText && _opinionText.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const _SectionCaption('FULL OPINION'),
                        const SizedBox(height: 10),
                        if (!_showFullOpinion)
                          _buildReadFullButton()
                        else ...[
                          SelectableText(
                            _opinionText,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 22 / 13.5,
                              letterSpacing: -0.1,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _showFullOpinion = false),
                              child: const Text(
                                'Collapse opinion',
                                style: TextStyle(
                                  color: AppColors.textGrey555,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Source: CourtListener, Free Law Project. Public '
                          'domain court opinion.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 16 / 11,
                            color: AppColors.textGrey,
                          ),
                        ),
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

  Widget _buildReadFullButton() {
    final words = _opinionText.split(RegExp(r'\s+')).length;
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _showFullOpinion = true),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_book_open.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Read the full opinion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'About ${(words / 230).ceil()} min · court text',
                      style: const TextStyle(
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

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseNotesScreen(caseStudy: widget.caseStudy),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openNotes,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_edit.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.caseStudy.hasNotes
                          ? 'Open Case Notes'
                          : 'Generate Case Notes',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Structured IRAC study notes with key terms',
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

  Widget _buildAiBriefCard() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openAiBrief,
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
                      'Facts, issue, holding and reasoning by ADVOK AI',
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
