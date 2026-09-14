import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import 'case_study_screen.dart';
import 'legal_dictionary_screen.dart';

/// IRAC-style study notes for a case, from the backend's cached copy.
class CaseNotes {
  const CaseNotes({
    required this.facts,
    required this.issue,
    required this.rule,
    required this.holding,
    required this.reasoning,
    required this.significance,
    required this.keyTerms,
    required this.generatedAt,
    required this.edited,
  });

  factory CaseNotes.fromApi(Map<String, dynamic> json) {
    return CaseNotes(
      facts: json['facts'] as String? ?? '',
      issue: json['issue'] as String? ?? '',
      rule: json['rule'] as String? ?? '',
      holding: json['holding'] as String? ?? '',
      reasoning: json['reasoning'] as String? ?? '',
      significance: json['significance'] as String? ?? '',
      keyTerms: (json['keyTerms'] as List<dynamic>? ?? const [])
          .map((k) => k.toString())
          .where((k) => k.isNotEmpty)
          .toList(),
      generatedAt: json['generatedAt'] as String? ?? '',
      edited: json['edited'] == true,
    );
  }

  final String facts;
  final String issue;
  final String rule;
  final String holding;
  final String reasoning;
  final String significance;
  final List<String> keyTerms;
  final String generatedAt;

  /// True when the ADVOK editorial team reviewed/edited the generated text.
  final bool edited;

  List<(String, String)> get sections => [
        ('Facts', facts),
        ('Issue', issue),
        ('Rule', rule),
        ('Holding', holding),
        ('Reasoning', reasoning),
        ('Significance', significance),
      ];

  String toPlainText(String title) {
    final b = StringBuffer('$title\n\n');
    for (final s in sections) {
      if (s.$2.isEmpty) continue;
      b.writeln(s.$1.toUpperCase());
      b.writeln(s.$2);
      b.writeln();
    }
    if (keyTerms.isNotEmpty) b.writeln('KEY TERMS: ${keyTerms.join(', ')}');
    return b.toString().trim();
  }
}

/// Lets the student pick which "Case to Read" to generate notes for.
class CaseNotesPickerScreen extends StatefulWidget {
  const CaseNotesPickerScreen({super.key});

  @override
  State<CaseNotesPickerScreen> createState() => _CaseNotesPickerScreenState();
}

class _CaseNotesPickerScreenState extends State<CaseNotesPickerScreen> {
  List<CaseStudy> _cases = const [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await ApiService.fetchCaseStudies();
      if (!mounted) return;
      setState(() => _cases = result.map(CaseStudy.fromApi).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    CircleBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Case Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pick a case — ADVOK AI writes structured IRAC notes',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: AppColors.textGrey555,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _error.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                                ],
                              ),
                            ),
                          )
                        : _cases.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No cases published yet. Check back soon.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textGrey555),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                itemCount: _cases.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _CaseRow(
                                  caseStudy: _cases[i],
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CaseNotesScreen(caseStudy: _cases[i]),
                                    ),
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({required this.caseStudy, required this.onTap});

  final CaseStudy caseStudy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseStudy.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [caseStudy.meta, caseStudy.tag].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey555),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (caseStudy.hasNotes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Notes ready',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                )
              else
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.textGrey555),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

/// The notes themselves: generated by ADVOK AI on first open (cached on the
/// backend afterwards), shown as IRAC sections with tappable key terms.
class CaseNotesScreen extends StatefulWidget {
  const CaseNotesScreen({super.key, required this.caseStudy});

  final CaseStudy caseStudy;

  @override
  State<CaseNotesScreen> createState() => _CaseNotesScreenState();
}

class _CaseNotesScreenState extends State<CaseNotesScreen> {
  CaseNotes? _notes;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final json = await ApiService.generateCaseNotes(widget.caseStudy.id);
      if (!mounted) return;
      setState(() => _notes = CaseNotes.fromApi(json));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyAll() async {
    final notes = _notes;
    if (notes == null) return;
    await Clipboard.setData(ClipboardData(text: notes.toPlainText(widget.caseStudy.title)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes copied to clipboard.')),
    );
  }

  void _openTerm(String term) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalTermScreen(term: term)),
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    CircleBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Case Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_notes != null)
                      IconButton(
                        tooltip: 'Copy all',
                        onPressed: _copyAll,
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textPrimary),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 14),
            Text(
              'ADVOK AI is reading the case and writing your notes…',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey555),
            ),
            SizedBox(height: 4),
            Text(
              'Usually takes a few seconds the first time.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    if (_error.isNotEmpty || _notes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 34, color: AppColors.textGrey),
              const SizedBox(height: 12),
              Text(
                _error.isEmpty ? 'Could not generate notes.' : _error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textGrey555),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderGrey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final notes = _notes!;
    final c = widget.caseStudy;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          c.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [c.meta, c.citation].where((s) => s.isNotEmpty).join(' · '),
          style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
        ),
        const SizedBox(height: 16),
        for (final section in notes.sections)
          if (section.$2.isNotEmpty) ...[
            _NoteSection(title: section.$1, body: section.$2),
            const SizedBox(height: 12),
          ],
        if (notes.keyTerms.isNotEmpty) ...[
          const Text(
            'Key terms · tap to look up',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in notes.keyTerms)
                ActionChip(
                  label: Text(term),
                  onPressed: () => _openTerm(term),
                  backgroundColor: AppColors.fillGrey,
                  side: const BorderSide(color: AppColors.borderGrey),
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(
          notes.edited
              ? 'Generated by ADVOK AI and reviewed by the ADVOK team. Always check against the opinion itself.'
              : 'Generated by ADVOK AI from the court\'s text. Always check against the opinion itself before relying on it.',
          style: const TextStyle(fontSize: 11, height: 1.45, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.title, required this.body});

  final String title;
  final String body;

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.05,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            body,
            style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }
}
