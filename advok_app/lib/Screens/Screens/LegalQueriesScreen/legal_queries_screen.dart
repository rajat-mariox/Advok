import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../FindMentorsScreen/find_mentors_screen.dart';

const int _maxQuestionLength = 500;

const List<String> _categories = [
  'Criminal Law',
  'Civil Law',
  'Family Law',
  'Corporate Law',
  'Property Law',
  'Employment Law',
  'Immigration Law',
  'Cyber Law',
];

/// A legal query as the backend stores it.
class _LegalQuery {
  const _LegalQuery({
    required this.id,
    required this.question,
    required this.category,
    required this.answered,
    required this.createdAt,
    this.response,
    this.responderName,
    this.answeredAt,
  });

  factory _LegalQuery.fromApi(Map<String, dynamic> json) {
    return _LegalQuery(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      category: json['category'] as String? ?? '',
      answered: json['status'] == 'answered',
      createdAt: json['createdAt'] as String? ?? '',
      response: (json['response'] as String?)?.trim(),
      responderName: json['responderName'] as String?,
      answeredAt: json['answeredAt'] as String?,
    );
  }

  final String id;
  final String question;
  final String category;
  final bool answered;
  final String createdAt;
  final String? response;
  final String? responderName;
  final String? answeredAt;

  String get timeAgo => _timeAgo(createdAt);
}

/// 'Just now', '5m ago', '3h ago', '2d ago', else 'Sep 11'.
String _timeAgo(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[t.month - 1]} ${t.day}';
}

/// Legal Queries tab — ask a question to senior advocates/mentors and track
/// the answers.
class LegalQueriesScreen extends StatefulWidget {
  const LegalQueriesScreen({super.key});

  @override
  State<LegalQueriesScreen> createState() => _LegalQueriesScreenState();
}

class _LegalQueriesScreenState extends State<LegalQueriesScreen>
    with WidgetsBindingObserver, RealtimeRefresh {
  /// While any query is pending, My Queries polls the backend this often so
  /// the ADVOK team's answer shows up without a manual refresh.
  static const _pollInterval = Duration(seconds: 60);

  int _selectedTab = 1;
  int? _expanded;
  String? _category;
  final TextEditingController _questionController = TextEditingController();

  /// The student's queries from the backend, newest first.
  List<_LegalQuery> _queries = [];
  bool _loading = true;
  bool _submitting = false;
  bool _refreshing = false;
  String _loadError = '';
  Timer? _pollTimer;

  int get _pendingCount => _queries.where((q) => !q.answered).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    listenRealtime({'queries'}, (_) => _loadQueries());
    _loadQueries();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app (e.g. from the notification) picks up new answers.
    if (state == AppLifecycleState.resumed) _loadQueries();
  }

  Future<void> _loadQueries() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final result = await ApiService.fetchLegalQueries();
      if (!mounted) return;
      final next = result.map(_LegalQuery.fromApi).toList();
      final wasLoaded = !_loading;
      final previouslyAnswered = _queries.where((q) => q.answered).map((q) => q.id).toSet();
      final newlyAnswered = next.where((q) => q.answered && !previouslyAnswered.contains(q.id)).toList();
      setState(() {
        _queries = next;
        _loadError = '';
        _loading = false;
      });
      // Announce answers that arrived while the screen was already loaded.
      if (wasLoaded && newlyAnswered.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newlyAnswered.length == 1
                  ? 'Your query "${newlyAnswered.first.question.length > 40 ? '${newlyAnswered.first.question.substring(0, 40)}…' : newlyAnswered.first.question}" was answered.'
                  : '${newlyAnswered.length} of your queries were answered.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _syncPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  /// Polls while something is pending; stops as soon as everything is answered.
  void _syncPolling() {
    final needsPolling = _queries.any((q) => !q.answered);
    if (needsPolling && _pollTimer == null) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => _loadQueries());
    } else if (!needsPolling && _pollTimer != null) {
      _pollTimer!.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _buildTab('Ask a Question', 0)),
              const SizedBox(width: 4),
              Expanded(child: _buildTab('My Queries', 1)),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == 0 ? _buildAskTab() : _buildQueriesTab(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Legal Queries',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 28 / 22,
                letterSpacing: -0.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$_pendingCount Pending',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: 0.11,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 1) _loadQueries();
      },
      child: Container(
        height: 37,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.fillGrey,
          borderRadius: BorderRadius.circular(18),
          border: selected ? null : Border.all(color: AppColors.borderGrey),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: selected ? AppColors.white : AppColors.textGrey555,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- queries

  Widget _buildQueriesTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return RefreshIndicator(
      onRefresh: _loadQueries,
      child: _queries.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_loadError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      _loadError,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
                    ),
                  ),
                _buildEmptyState(),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _queries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildQueryCard(index),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
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
                'assets/icons/ic_help.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textGrey555,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No queries yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask a question and responses from '
            '${CountryCatalog.terms.seniorTitle.toLowerCase()}s\n'
            'will appear here.',
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryCard(int index) {
    final query = _queries[index];
    final expanded = _expanded == index;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = expanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_help.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          query.question,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 20 / 14,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusChip(query.answered),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                [query.category, query.timeAgo]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: SvgPicture.asset(
                      'assets/icons/ic_chevron_down.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.all(16),
              child: query.answered && (query.response ?? '').isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response from ${query.responderName ?? 'ADVOK Legal Team'}'
                          '${query.answeredAt != null ? ' · ${_timeAgo(query.answeredAt!)}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: AppColors.textGrey555,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          query.response!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 19.5 / 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Awaiting response — '
                      '${CountryCatalog.terms.seniorTitle.toLowerCase()}s '
                      'typically reply within 24 hours.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 19.5 / 13,
                        color: AppColors.textGrey555,
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool answered) {
    final color = answered ? const Color(0xFF2A2A2A) : const Color(0xFF555555);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            answered ? 'Answered' : 'Pending',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 0.12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- ask

  Widget _buildAskTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 20),
                _buildFieldLabel('Category'),
                const SizedBox(height: 8),
                _buildCategoryField(),
                const SizedBox(height: 20),
                _buildFieldLabel('Your Question'),
                const SizedBox(height: 8),
                _buildQuestionField(),
                const SizedBox(height: 20),
                _buildMentorCard(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildSubmitButton(),
        ),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask Legal Questions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 22 / 15,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get guidance from '
            '${CountryCatalog.terms.seniorTitle.toLowerCase()}s and mentors. '
            'Responses within 24 hours.',
            style: const TextStyle(
              fontSize: 13,
              height: 19 / 13,
              letterSpacing: -0.08,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: -0.08,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategoryField() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _showCategoryPicker,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _category ?? 'Select category...',
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: _category != null
                      ? AppColors.textPrimary
                      : AppColors.textGrey,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/ic_chevron_down.svg',
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
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 24 / 17,
                  letterSpacing: -0.34,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final category in _categories)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: category == _category
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 20 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: category == _category
                          ? SvgPicture.asset(
                              'assets/icons/ic_check.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            )
                          : null,
                      onTap: () {
                        setState(() => _category = category);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: TextField(
            controller: _questionController,
            maxLines: 7,
            minLines: 7,
            maxLength: _maxQuestionLength,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText: 'Describe your legal question in detail...',
              hintStyle: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.15,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_questionController.text.length} / $_maxQuestionLength',
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildMentorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_user.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect with Mentor',
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
                  'Request guidance from a specific mentor',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (routeContext) => Scaffold(
                    backgroundColor: AppColors.white,
                    body: SafeArea(
                      child: FindMentorsScreen(
                        onBack: () => Navigator.of(routeContext).pop(),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'Browse',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 16 / 12,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = !_submitting &&
        _category != null &&
        _questionController.text.trim().isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? _submitQuery : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_send.svg',
                    width: 17,
                    height: 17,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _submitting ? 'Submitting…' : 'Submit Query',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.31,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuery() async {
    if (_submitting || _category == null) return;
    setState(() => _submitting = true);
    try {
      final json = await ApiService.createLegalQuery(
        category: _category!,
        question: _questionController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _queries.insert(0, _LegalQuery.fromApi(json));
        _category = null;
        _questionController.clear();
        _selectedTab = 1;
        _expanded = null;
      });
      _syncPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Query submitted — expect a response within 24 hours.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
