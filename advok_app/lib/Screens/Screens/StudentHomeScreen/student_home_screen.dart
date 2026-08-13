import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/session_avatar.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../../LawStudentRegistration/verification_submitted_screen.dart';
import '../NotificationScreen/notification_screen.dart';
import '../AdvokAiScreen/advok_ai_screen.dart';
import 'case_study_screen.dart';
import 'news_article_screen.dart';

/// Case studies are loaded from the backend; empty until then.
const List<CaseStudy> _cases = [];

/// Recommended advocates are loaded from the backend; empty until then.
const List<
  ({String name, String subtitle, String rating, String image, bool locked})
>
_advocates = [];

/// Legal news is loaded from the backend; empty until then.
const List<NewsArticle> _news = [];

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key, this.onProfileTap});

  /// Called when the header avatar is tapped. Used by the nav shell to
  /// switch to the Profile tab.
  final VoidCallback? onProfileTap;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  static const List<String> _chips = ['Home', 'Legal News', 'Tools', 'Saved'];

  static const List<String> _newsFilters = [
    'All',
    'Supreme Court',
    'High Court',
    'Legislation',
    'Exam Update',
  ];

  int _selectedChip = 0;
  int _selectedNewsFilter = 0;
  final Set<int> _savedCases = <int>{};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildPendingBanner(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _buildSearchBar(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildChips(),
          ),
          if (_selectedChip == 1)
            ..._buildNewsSection()
          else if (_selectedChip == 3)
            ..._buildSavedSection()
          else if (_selectedChip == 2)
            ..._buildToolsSection()
          else
            ..._buildHomeSections(),
        ],
      ),
    );
  }

  List<Widget> _buildHomeSections() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Featured Learning',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 12),
      _buildSectionPlaceholder(
        'Featured learning content will appear here soon.',
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cases to Read',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_cases.length} cases',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_cases.isEmpty)
        _buildEmptyState(
          icon: 'assets/icons/ic_judge.svg',
          title: 'No cases yet',
          subtitle: 'Case studies will appear here soon.',
        )
      else
        for (int i = 0; i < _cases.length; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildCaseCard(i),
          ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended ${CountryCatalog.terms.lawyerPlural}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: () {},
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: AppColors.textGrey555,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_advocates.isEmpty)
        _buildSectionPlaceholder('Recommended advocates will appear here soon.')
      else
        for (final advocate in _advocates)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildAdvocateCard(advocate),
          ),
    ];
  }

  Widget _buildSectionPlaceholder(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 19.5 / 13,
          color: AppColors.textGrey555,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
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
            child: Center(child: SvgPicture.asset(icon, width: 24, height: 24)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNewsSection() {
    final filter = _newsFilters[_selectedNewsFilter];
    final items = _selectedNewsFilter == 0
        ? _news
        : _news.where((n) => n.tag == filter).toList();
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Legal News',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Updated daily',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (int i = 0; i < _newsFilters.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Material(
                color: _selectedNewsFilter == i
                    ? AppColors.textPrimary
                    : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => setState(() => _selectedNewsFilter = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _selectedNewsFilter == i
                            ? AppColors.textPrimary
                            : AppColors.borderGrey,
                      ),
                    ),
                    child: Text(
                      _newsFilters[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        letterSpacing: -0.08,
                        color: _selectedNewsFilter == i
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (items.isEmpty)
        _buildEmptyState(
          icon: 'assets/icons/ic_book_open.svg',
          title: 'No news yet',
          subtitle: 'Legal news and updates will appear here soon.',
        )
      else
        for (final item in items)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildNewsCard(item),
          ),
    ];
  }

  void _openRelatedCase(String title) {
    final index = _cases.indexWhere((c) => c.title == title);
    if (index == -1) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseStudyScreen(
          caseStudy: _cases[index],
          saved: _savedCases.contains(index),
          onToggleSaved: () => _toggleSaved(index),
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle item) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewsArticleScreen(
                article: item,
                onOpenRelatedCase: _openRelatedCase,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item.tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.source,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 16 / 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSavedSection() {
    final saved = _savedCases.toList()..sort();
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Saved Cases',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (saved.isEmpty)
        _buildSectionPlaceholder(
          'No saved cases yet. Bookmark cases to find them here.',
        )
      else
        for (final index in saved)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildSavedCaseCard(index),
          ),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Saved Notes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 12),
      _buildSectionPlaceholder('No saved notes yet.'),
    ];
  }

  Widget _buildSavedCaseCard(int index) {
    final data = _cases[index];
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseStudyScreen(
                caseStudy: data,
                saved: true,
                onToggleSaved: () => _toggleSaved(index),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_judge.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.tag} · ${data.mins}',
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

  static List<
    ({
      String? svg,
      IconData? iconData,
      String title,
      String subtitle,
      bool locked,
    })
  >
  get _tools => [
    (
      svg: 'assets/icons/ic_bot.svg',
      iconData: null,
      title: 'AI Case Brief',
      subtitle: 'Summarize judgments instantly',
      locked: false,
    ),
    (
      svg: null,
      iconData: Icons.lightbulb_outline,
      title: 'Explain Legal Terms',
      subtitle: 'Plain-English explanations',
      locked: false,
    ),
    (
      svg: 'assets/icons/ic_edit.svg',
      iconData: null,
      title: 'Generate Case Notes',
      subtitle: 'Structured study notes',
      locked: false,
    ),
    (
      svg: 'assets/icons/ic_book_open.svg',
      iconData: null,
      title: 'Legal Dictionary',
      subtitle: '10,000+ legal terms',
      locked: false,
    ),
    (
      svg: 'assets/icons/ic_briefcase.svg',
      iconData: null,
      title: 'Internship Portal',
      subtitle: 'Verify to unlock',
      locked: true,
    ),
    (
      svg: 'assets/icons/ic_check_circle_dark.svg',
      iconData: null,
      title: 'Mock Tests',
      subtitle: 'Verify to unlock',
      locked: true,
    ),
    (
      svg: 'assets/icons/ic_user.svg',
      iconData: null,
      title: 'Mentorship Access',
      subtitle: 'Verify to unlock',
      locked: true,
    ),
    (
      svg: 'assets/icons/ic_qa_chat.svg',
      iconData: null,
      title: '${CountryCatalog.terms.seniorTitle} Queries',
      subtitle: 'Verify to unlock',
      locked: true,
    ),
  ];

  List<Widget> _buildToolsSection() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Student Tools',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 12),
      for (int i = 0; i < _tools.length; i += 2)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildToolCard(_tools[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < _tools.length
                      ? _buildToolCard(_tools[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildToolCard(
    ({
      String? svg,
      IconData? iconData,
      String title,
      String subtitle,
      bool locked,
    })
    tool,
  ) {
    final contentColor = tool.locked
        ? AppColors.textGrey
        : AppColors.textPrimary;
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Remaining unlocked tools open their flows once those screens exist.
        onTap: tool.locked
            ? null
            : () {
                if (tool.title == 'AI Case Brief' ||
                    tool.title == 'Explain Legal Terms') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdvokAiScreen()),
                  );
                }
              },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: tool.locked ? 0.55 : 1,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.progressTrack,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: tool.svg != null
                            ? SvgPicture.asset(
                                tool.svg!,
                                width: 19,
                                height: 19,
                                colorFilter: ColorFilter.mode(
                                  contentColor,
                                  BlendMode.srcIn,
                                ),
                              )
                            : Icon(
                                tool.iconData,
                                size: 21,
                                color: contentColor,
                              ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (tool.locked)
                    SvgPicture.asset(
                      'assets/icons/ic_lock.svg',
                      width: 13,
                      height: 13,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                tool.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tool.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: tool.locked
                      ? AppColors.textGrey
                      : AppColors.textGrey555,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
                Text(
                  Session.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 28 / 20,
                    letterSpacing: -0.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_bell.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 7,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: const SessionAvatar(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const VerificationSubmittedScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.textGrey555,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Verification Pending · Some features locked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_search.svg', width: 16, height: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search cases, laws, topics...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.15,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Material(
              color: _selectedChip == i
                  ? AppColors.textPrimary
                  : AppColors.fillGrey,
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => setState(() => _selectedChip = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _selectedChip == i
                          ? AppColors.textPrimary
                          : AppColors.borderGrey,
                    ),
                  ),
                  child: Text(
                    _chips[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 18 / 13,
                      letterSpacing: -0.08,
                      color: _selectedChip == i
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleSaved(int index) {
    setState(() {
      if (_savedCases.contains(index)) {
        _savedCases.remove(index);
      } else {
        _savedCases.add(index);
      }
    });
  }

  Widget _buildCaseCard(int index) {
    final data = _cases[index];
    final saved = _savedCases.contains(index);
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseStudyScreen(
                caseStudy: data,
                saved: saved,
                onToggleSaved: () => _toggleSaved(index),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_judge.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.meta,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            data.tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              letterSpacing: 0.12,
                              color: AppColors.textGrey555,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          data.mins,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 16 / 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleSaved(index),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    'assets/icons/ic_bookmark.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      saved ? AppColors.textPrimary : AppColors.textGrey,
                      BlendMode.srcIn,
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

  Widget _buildAdvocateCard(
    ({String name, String subtitle, String rating, String image, bool locked})
    advocate,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: advocate.locked ? 0.55 : 1,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: ClipOval(
                child: Image.asset(advocate.image, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: advocate.locked ? 0.55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          advocate.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 20 / 14,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (advocate.locked) ...[
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/icons/ic_lock.svg',
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            AppColors.textGrey,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    advocate.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_star.svg',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        advocate.rating,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 16 / 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (advocate.locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.progressTrack,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Verify to unlock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 16 / 11,
                  color: AppColors.textGrey,
                ),
              ),
            )
          else
            Material(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  child: Text(
                    'Connect',
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
}
