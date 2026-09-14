import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvokAiScreen/advok_ai_screen.dart';

/// One row of a dictionary search / browse result.
class LegalTermSummary {
  const LegalTermSummary({
    required this.slug,
    required this.term,
    required this.preview,
    required this.source,
    this.hasPlainEnglish = false,
  });

  factory LegalTermSummary.fromApi(Map<String, dynamic> json) {
    return LegalTermSummary(
      slug: json['slug'] as String? ?? '',
      term: json['term'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      source: json['source'] as String? ?? 'blacks2',
      hasPlainEnglish: json['hasPlainEnglish'] == true,
    );
  }

  final String slug;
  final String term;
  final String preview;

  /// 'blacks2' (Black's Law Dictionary), 'admin' or 'ai'.
  final String source;
  final bool hasPlainEnglish;
}

/// A full dictionary entry.
class LegalTerm {
  const LegalTerm({
    required this.slug,
    required this.term,
    required this.definition,
    required this.source,
    required this.sourceLabel,
    this.plainEnglish,
  });

  factory LegalTerm.fromApi(Map<String, dynamic> json) {
    return LegalTerm(
      slug: json['slug'] as String? ?? '',
      term: json['term'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      source: json['source'] as String? ?? 'blacks2',
      sourceLabel: json['sourceLabel'] as String? ?? '',
      plainEnglish: (json['plainEnglish'] as String?)?.trim(),
    );
  }

  final String slug;
  final String term;
  final String definition;
  final String source;
  final String sourceLabel;

  /// ADVOK AI's modern explanation, once generated.
  final String? plainEnglish;
}

/// Legal Dictionary: ~11,000 terms from Black's Law Dictionary (2nd ed.,
/// public domain) plus ADVOK editorial entries, searchable and browsable
/// A–Z. Every term can be explained in plain English by ADVOK AI.
class LegalDictionaryScreen extends StatefulWidget {
  const LegalDictionaryScreen({super.key});

  @override
  State<LegalDictionaryScreen> createState() => _LegalDictionaryScreenState();
}

class _LegalDictionaryScreenState extends State<LegalDictionaryScreen> {
  static const _pageSize = 40;

  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  List<String> _letters = const [];
  String? _letter;
  List<LegalTermSummary> _terms = const [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadLetters();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    try {
      final letters = await ApiService.fetchDictionaryLetters();
      if (!mounted) return;
      setState(() => _letters = letters);
    } on ApiException {
      // The A–Z strip is a convenience; search still works without it.
    }
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || _terms.length >= _total)) return;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = '';
      }
    });
    try {
      final result = await ApiService.searchDictionary(
        _search.text.trim(),
        letter: _letter,
        limit: _pageSize,
        offset: more ? _terms.length : 0,
      );
      if (!mounted) return;
      final items = (result['terms'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(LegalTermSummary.fromApi)
          .toList();
      setState(() {
        _terms = more ? [..._terms, ...items] : items;
        _total = (result['total'] as num?)?.toInt() ?? items.length;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // A typed query searches the whole dictionary, not one letter.
      if (_search.text.trim().isNotEmpty && _letter != null) {
        setState(() => _letter = null);
      }
      _load();
    });
  }

  void _pickLetter(String? letter) {
    setState(() {
      _letter = _letter == letter ? null : letter;
      _search.clear();
    });
    _load();
  }

  void _openTerm({String? slug, String? term}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalTermScreen(slug: slug, term: term),
      ),
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
              _buildHeader(),
              _buildSearchField(),
              if (_letters.isNotEmpty) _buildLetterStrip(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                  'Legal Dictionary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Black's Law Dictionary · plain-English explanations by ADVOK AI",
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
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, size: 18, color: AppColors.textGrey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: _onQueryChanged,
                onSubmitted: (_) => _load(),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search a term, e.g. habeas corpus',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
              ),
            ),
            if (_search.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                onPressed: () {
                  _search.clear();
                  _load();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterStrip() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _letters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final letter = _letters[i];
          final selected = _letter == letter;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pickLetter(letter),
            child: Container(
              width: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.textPrimary : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.textPrimary : AppColors.borderGrey,
                ),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error.isNotEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load the dictionary',
        message: _error,
        action: ('Retry', _load),
      );
    }
    final query = _search.text.trim();
    if (_terms.isEmpty) {
      return _Message(
        icon: Icons.menu_book_outlined,
        title: query.isEmpty ? 'No terms here yet' : 'No entry for "$query"',
        message: query.isEmpty
            ? 'Pick a letter or search for a term.'
            : 'Ask ADVOK AI to explain it in plain English.',
        action: query.isEmpty
            ? null
            : ('Explain "$query" with ADVOK AI', () => _openTerm(term: query)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _terms.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == _terms.length) {
          return _buildFooter(query);
        }
        return _TermRow(term: _terms[i], onTap: () => _openTerm(slug: _terms[i].slug));
      },
    );
  }

  Widget _buildFooter(String query) {
    final remaining = _total - _terms.length;
    return Column(
      children: [
        if (remaining > 0)
          TextButton(
            onPressed: _loadingMore ? null : () => _load(more: true),
            child: Text(
              _loadingMore ? 'Loading…' : 'Show $remaining more',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        if (query.isNotEmpty)
          TextButton.icon(
            onPressed: () => _openTerm(term: query),
            icon: const Icon(Icons.auto_awesome, size: 15),
            label: Text(
              'Not what you meant? Explain "$query" with ADVOK AI',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.textGrey555),
          ),
        const SizedBox(height: 4),
        Text(
          '$_total term${_total == 1 ? '' : 's'} · Source: Black\'s Law Dictionary, 2nd Edition (1910), public domain',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, height: 1.4, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.term, required this.onTap});

  final LegalTermSummary term;
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            term.term,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              letterSpacing: -0.1,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (term.hasPlainEnglish) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.auto_awesome, size: 13, color: AppColors.textGrey555),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      term.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textGrey555),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: action!.$2,
                icon: const Icon(Icons.auto_awesome, size: 15),
                label: Text(action!.$1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderGrey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One dictionary entry: the historical definition, and ADVOK AI's
/// plain-English explanation (generated on demand, then cached). Opened with
/// a [slug] for a known entry, or just a [term] the dictionary lacks.
class LegalTermScreen extends StatefulWidget {
  const LegalTermScreen({super.key, this.slug, this.term})
      : assert(slug != null || term != null, 'slug or term is required');

  final String? slug;
  final String? term;

  @override
  State<LegalTermScreen> createState() => _LegalTermScreenState();
}

class _LegalTermScreenState extends State<LegalTermScreen> {
  LegalTerm? _entry;
  bool _loading = true;
  bool _explaining = false;
  String _error = '';
  String _explainError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.slug == null) {
      // Unknown term: go straight to the AI explanation.
      setState(() => _loading = false);
      await _explain();
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final json = await ApiService.fetchDictionaryTerm(widget.slug!);
      if (!mounted) return;
      setState(() => _entry = LegalTerm.fromApi(json));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _explain({bool regenerate = false}) async {
    if (_explaining) return;
    setState(() {
      _explaining = true;
      _explainError = '';
    });
    try {
      final json = await ApiService.explainLegalTerm(
        slug: _entry?.slug ?? widget.slug,
        term: _entry == null ? widget.term : null,
        regenerate: regenerate,
      );
      if (!mounted) return;
      setState(() => _entry = LegalTerm.fromApi(json));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _explainError = e.message);
    } finally {
      if (mounted) setState(() => _explaining = false);
    }
  }

  void _askAi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdvokAiScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _entry?.term ?? widget.term ?? '';
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
                        'Legal Dictionary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _error.isNotEmpty
                        ? _Message(
                            icon: Icons.cloud_off_outlined,
                            title: 'Could not load this term',
                            message: _error,
                            action: ('Retry', _load),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.4,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPlainEnglishCard(),
                              if (_entry != null && _entry!.definition.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildDefinitionCard(_entry!),
                              ],
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: _askAi,
                                icon: const Icon(Icons.chat_bubble_outline, size: 15),
                                label: const Text('Ask ADVOK AI a follow-up question'),
                                style: TextButton.styleFrom(foregroundColor: AppColors.textGrey555),
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

  Widget _buildPlainEnglishCard() {
    final text = _entry?.plainEnglish;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                'In plain English',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (text != null && text.isNotEmpty)
            Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: AppColors.white,
              ),
            )
          else if (_explaining)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                ),
                SizedBox(width: 10),
                Text(
                  'ADVOK AI is writing an explanation…',
                  style: TextStyle(fontSize: 13, color: AppColors.white),
                ),
              ],
            )
          else
            Text(
              _explainError.isNotEmpty
                  ? _explainError
                  : 'Get a modern, easy-to-read explanation with an example.',
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.white),
            ),
          const SizedBox(height: 12),
          if (!_explaining)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _explain(regenerate: text != null && text.isNotEmpty),
                icon: Icon(
                  text != null && text.isNotEmpty ? Icons.refresh : Icons.auto_awesome,
                  size: 15,
                ),
                label: Text(
                  text != null && text.isNotEmpty ? 'Regenerate' : 'Explain in plain English',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefinitionCard(LegalTerm entry) {
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
            entry.source == 'blacks2' ? 'Dictionary definition' : 'Definition',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            entry.definition,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.source == 'blacks2'
                ? 'Source: ${entry.sourceLabel}, public domain. Historical text digitised by OCR; small errors are possible.'
                : 'Source: ${entry.sourceLabel}',
            style: const TextStyle(fontSize: 11, height: 1.4, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
