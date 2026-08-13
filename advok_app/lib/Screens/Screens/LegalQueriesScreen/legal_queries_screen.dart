import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

class _LegalQuery {
  const _LegalQuery({required this.question, required this.timeAgo});

  final String question;
  final String timeAgo;
}

/// Legal Queries tab — ask a question to senior advocates/mentors and track
/// the answers.
class LegalQueriesScreen extends StatefulWidget {
  const LegalQueriesScreen({super.key});

  @override
  State<LegalQueriesScreen> createState() => _LegalQueriesScreenState();
}

class _LegalQueriesScreenState extends State<LegalQueriesScreen> {
  int _selectedTab = 1;
  int? _expanded;
  String? _category;
  final TextEditingController _questionController = TextEditingController();

  /// Queries are loaded from the backend; holds locally submitted ones
  /// until then.
  final List<_LegalQuery> _queries = [];

  // All queries stay pending until the backend delivers responses.
  int get _pendingCount => _queries.length;

  @override
  void dispose() {
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
      onTap: () => setState(() => _selectedTab = index),
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
    if (_queries.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _queries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildQueryCard(index),
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
                            _buildStatusChip(false),
                            const SizedBox(width: 8),
                            Text(
                              query.timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: AppColors.textGrey,
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
              child: Text(
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
    final enabled =
        _category != null && _questionController.text.trim().isNotEmpty;
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
                  const Text(
                    'Submit Query',
                    style: TextStyle(
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

  void _submitQuery() {
    setState(() {
      _queries.insert(
        0,
        _LegalQuery(
          question: _questionController.text.trim(),
          timeAgo: 'Just now',
        ),
      );
      _category = null;
      _questionController.clear();
      _selectedTab = 1;
      _expanded = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Query submitted — expect a response within 24 hours.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
