import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/session_avatar.dart';
import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../../../Utils/Responsive/responsive.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';
import '../AdvocateProfileScreen/advocate_profile_screen.dart';
import '../AdvokAiScreen/advok_ai_screen.dart';
import '../ClientCasesScreen/client_cases_screen.dart';
import '../LawFirmScreen/law_firm_screens.dart';
import '../MessagesScreen/messages_screen.dart';
import '../NotificationScreen/notification_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({
    super.key,
    this.onProfileTap,
    this.onSearchTap,
    this.onMessagesTap,
  });

  /// Called when the header avatar is tapped. Used by the nav shell to
  /// switch to the Profile tab.
  final VoidCallback? onProfileTap;

  /// Quick action "Book" → the Search tab (find an attorney to book).
  final VoidCallback? onSearchTap;

  /// Quick action "Chat" → the Messages tab.
  final VoidCallback? onMessagesTap;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> with RealtimeRefresh {
  VoidCallback? get onProfileTap => widget.onProfileTap;

  /// Verified advocates in the client's country, from the backend.
  List<_AdvocateData> _advocates = [];

  /// Verified law firms in the client's country, from the backend.
  List<LawFirm> _firms = [];

  /// Upcoming consultations (pending or confirmed, today onwards).
  List<Map<String, dynamic>> _upcomingBookings = [];

  /// Unread notifications, for the bell dot.
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    listenRealtime({'bookings', 'notifications'}, (_) {
      _loadBookings();
      _loadUnreadNotifications();
    });
    _loadAdvocates();
    _loadFirms();
    _loadBookings();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final data = await ApiService.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _unreadNotifications = (data['unread'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // Backend unreachable — no dot.
    }
  }

  /// '10:00 AM' → minutes since midnight, for chronological ordering.
  static int _slotMinutes(String? time) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(time?.trim() ?? '');
    if (match == null) return 0;
    var h = int.parse(match.group(1)!) % 12;
    if (match.group(3)!.toUpperCase() == 'PM') h += 12;
    return h * 60 + int.parse(match.group(2)!);
  }

  Future<void> _loadBookings() async {
    try {
      final result = await ApiService.fetchBookings();
      if (!mounted) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcoming = [
        for (final b in result)
          if ((b['status'] == 'pending' || b['status'] == 'confirmed') &&
              (DateTime.tryParse(b['date'] as String? ?? '')?.isBefore(today) ==
                  false))
            b,
      ];
      // Soonest appointment first.
      upcoming.sort((a, b) {
        final byDate = (a['date'] as String? ?? '').compareTo(
          b['date'] as String? ?? '',
        );
        if (byDate != 0) return byDate;
        return _slotMinutes(
          a['time'] as String?,
        ).compareTo(_slotMinutes(b['time'] as String?));
      });
      setState(() => _upcomingBookings = upcoming);
    } catch (_) {
      // Backend unreachable — the section keeps its empty state.
    }
  }

  Future<void> _loadAdvocates() async {
    try {
      final result = await ApiService.fetchAdvocates();
      if (!mounted) return;
      setState(() {
        _advocates = [
          for (final a in result)
            _AdvocateData(
              name: a['name'] as String? ?? 'Advocate',
              specialty:
                  ((a['practiceArea'] as String?)?.trim().isNotEmpty ?? false)
                  ? (a['practiceArea'] as String).trim()
                  : 'General Practice',
              experience:
                  (a['yearsInPractice'] as String?) ??
                  (a['advocateType'] == 'senior'
                      ? '10+ years'
                      : 'Under 10 years'),
              rating: null,
              price: '',
              image: '',
              photoBytes: decodePhotoDataUrl(a['photo'] as String?),
              raw: a,
            ),
        ];
      });
    } catch (_) {
      // Backend unreachable — the section keeps its empty state.
    }
  }

  Future<void> _loadFirms() async {
    try {
      final result = await ApiService.fetchLawFirms();
      if (!mounted) return;
      setState(() => _firms = result.map(LawFirm.fromApi).toList());
    } catch (_) {
      // Backend unreachable — the section keeps its empty state.
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildSearchBar(),
          ),
          if (_liveQuery.trim().isNotEmpty)
            ..._buildLiveResults()
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildAiBanner(),
            ),
            _SectionHeader(
              title: 'Legal Categories',
              onSeeAll: () {
                // Browse every attorney; the list has its own practice-area
                // filters and search.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdvocateListScreen(
                      title: 'All ${CountryCatalog.terms.lawyerPlural}',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildCategories(),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Top ${CountryCatalog.terms.lawyerPlural}',
              onSeeAll: () {
                // Same full list the Search tab shows, every practice area.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdvocateListScreen(
                      title: 'Top ${CountryCatalog.terms.lawyerPlural}',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildAdvocates(context),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Law Firms',
              onSeeAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LawFirmListScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildFirms(context),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAppointments(),
            ),
          ],
        ],
      ),
    );
  }

  /// Search-as-you-type over the attorneys and firms already loaded for the
  /// home screen: name, practice area, firm, location, bar states, years.
  List<Widget> _buildLiveResults() {
    final q = _liveQuery.trim().toLowerCase();
    bool hit(Iterable<String?> parts) =>
        parts.whereType<String>().join(' ').toLowerCase().contains(q);

    final attorneys = [
      for (final a in _advocates)
        if (a.raw != null &&
            hit([
              a.name,
              a.specialty,
              a.experience,
              a.raw!['firmName'] as String?,
              a.raw!['firmRole'] as String?,
              a.raw!['state'] as String?,
              a.raw!['district'] as String?,
              ...(a.raw!['barStates'] as List<dynamic>? ?? []).cast<String>(),
            ]))
          a,
    ];
    final firms = [
      for (final f in _firms)
        if (hit([f.name, f.location, ...f.expertise])) f,
    ];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                attorneys.isEmpty && firms.isEmpty
                    ? 'No results for "${_liveQuery.trim()}"'
                    : '${attorneys.length} attorney${attorneys.length == 1 ? '' : 's'}'
                          '${firms.isEmpty ? '' : ' · ${firms.length} law firm${firms.length == 1 ? '' : 's'}'}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _submitSearch(_liveQuery),
              child: const Text(
                'Filters & sort',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      if (attorneys.isEmpty && firms.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _EmptyState(
            icon: 'assets/icons/ic_search.svg',
            title: 'Nothing matched',
            message:
                'Try a name, a practice area like "Family", a state, '
                'or a law firm.',
          ),
        ),
      for (final a in attorneys)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _LiveResultRow(
            name: a.name,
            subtitle: [
              a.specialty,
              if ((a.raw!['firmName'] as String? ?? '').isNotEmpty)
                a.raw!['firmName'] as String,
              a.experience,
            ].join(' · '),
            photoBytes: a.photoBytes,
            trailing: 'Attorney',
            onTap: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AdvocateProfileScreen(advocate: Advocate.fromApi(a.raw!)),
                ),
              );
            },
          ),
        ),
      for (final f in firms)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _LiveResultRow(
            name: f.name,
            subtitle: [f.summary, f.location].join(' · '),
            photoBytes: f.photoBytes,
            trailing: 'Law Firm',
            onTap: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LawFirmDetailScreen(firm: f)),
              );
            },
          ),
        ),
      const SizedBox(height: 8),
    ];
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
                Text(
                  _greeting,
                  style: const TextStyle(
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
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
              _loadUnreadNotifications();
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
                  if (_unreadNotifications > 0)
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
          SessionAvatar(onTap: onProfileTap),
        ],
      ),
    );
  }

  final TextEditingController _searchController = TextEditingController();

  /// Live search text. While non-empty the home sections are replaced by
  /// matching attorneys and law firms (search-as-you-type).
  String _liveQuery = '';

  /// Opens the attorney list with the typed text as the search query.
  void _submitSearch(String text) {
    final q = text.trim();
    _searchController.clear();
    setState(() => _liveQuery = '');
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvocateListScreen(
          title: q.isEmpty ? 'Search' : 'Results for "$q"',
          initialQuery: q,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_search.svg', width: 17, height: 17),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _liveQuery = v),
              onSubmitted: _submitSearch,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search attorneys, firms, practice areas…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.15,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _submitSearch(_searchController.text),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                'assets/icons/ic_chevron_right.svg',
                width: 14,
                height: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAdvokAi() {
    FocusScope.of(context).unfocus();
    showAdvokAiSheet(context);
  }

  Widget _buildAiBanner() {
    return GestureDetector(
      onTap: _openAdvokAi,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 93,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.6, 1],
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.21),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AI-POWERED · FREE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: 0.62,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI Legal Information',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: -0.23,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ask ADVOK AI for legal information',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                      color: Color(0xFFB9B9B9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.21),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/ic_bot.svg',
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tiles are generated from the country's fixed practice-area list — the
  // same list the attorney onboarding dropdown uses — so tapping a category
  // matches attorneys exactly.
  Widget _buildCategories() {
    final areas = CountryCatalog.terms.practiceAreas;
    const tints = [
      Color(0xFF1A1A1A),
      Color(0xFF333333),
      Color(0xFF0A0A0A),
      Color(0xFF444444),
      Color(0xFF555555),
    ];
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: areas.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final area = areas[index];
          return _IconTile(
            label: _categoryLabel(area),
            icon: _categoryIcon(area),
            tint: tints[index % tints.length],
            iconSize: 24,
            borderAlpha: 0.19,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AdvocateListScreen(title: area, practiceArea: area),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Short tile label: "Employment Law" → "Employment".
  static String _categoryLabel(String area) =>
      area.endsWith(' Law') ? area.substring(0, area.length - 4) : area;

  /// Best-fit icon for a practice area (checked in order so e.g.
  /// "Intellectual Property" resolves before the generic "property" match).
  static String _categoryIcon(String area) {
    final a = area.toLowerCase();
    if (a.contains('criminal')) return 'assets/icons/ic_cat_criminal.svg';
    if (a.contains('family')) return 'assets/icons/ic_cat_family.svg';
    if (a.contains('immigration')) return 'assets/icons/ic_cat_immigration.svg';
    if (a.contains('cyber') || a.contains('intellectual')) {
      return 'assets/icons/ic_cat_cyber.svg';
    }
    if (a.contains('property') || a.contains('estate')) {
      return 'assets/icons/ic_cat_property.svg';
    }
    if (a.contains('employment') ||
        a.contains('labour') ||
        a.contains('injury')) {
      return 'assets/icons/ic_cat_employment.svg';
    }
    if (a.contains('corporate') ||
        a.contains('business') ||
        a.contains('tax') ||
        a.contains('bankruptcy') ||
        a.contains('consumer')) {
      return 'assets/icons/ic_cat_corporate.svg';
    }
    return 'assets/icons/ic_cat_civil.svg';
  }

  Widget _buildAdvocates(BuildContext context) {
    final advocates = _advocates;
    if (advocates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _EmptyState(
          icon: 'assets/icons/ic_search.svg',
          title: 'No ${CountryCatalog.terms.lawyerPlural.toLowerCase()} yet',
          message:
              '${CountryCatalog.terms.lawyerPlural} will appear here once '
              'verified ${CountryCatalog.terms.lawyerPlural.toLowerCase()} '
              'join the platform.',
        ),
      );
    }
    return SizedBox(
      height: context.rs(234),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: advocates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _AdvocateCard(
          advocates[index],
          onTap: advocates[index].raw == null
              ? null
              : () {
                  // Full profile, with Book Appointment right there.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdvocateProfileScreen(
                        advocate: Advocate.fromApi(advocates[index].raw!),
                      ),
                    ),
                  );
                },
        ),
      ),
    );
  }

  /// Horizontal strip of verified law firms; tapping opens the firm's
  /// profile where the client can call or email the firm for a case.
  Widget _buildFirms(BuildContext context) {
    final firms = _firms;
    if (firms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.progressTrack,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_role_firm.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No law firms yet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Verified firms in your area will appear here.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: context.rs(216),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: firms.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) => _FirmCard(
          firms[index],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LawFirmDetailScreen(firm: firms[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconTile(
            label: 'Book',
            icon: 'assets/icons/ic_qa_book.svg',
            tint: const Color(0xFF0A0A0A),
            iconSize: 24,
            borderAlpha: 0.16,
            onTap:
                widget.onSearchTap ??
                () {
                  // Not inside the nav shell: open the attorney list directly.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdvocateListScreen(
                        title: 'Top ${CountryCatalog.terms.lawyerPlural}',
                      ),
                    ),
                  );
                },
          ),
          _IconTile(
            label: 'Chat',
            icon: 'assets/icons/ic_qa_chat.svg',
            tint: const Color(0xFF333333),
            iconSize: 24,
            borderAlpha: 0.16,
            onTap:
                widget.onMessagesTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  );
                },
          ),
          _IconTile(
            label: 'My Cases',
            icon: 'assets/icons/ic_qa_docs.svg',
            tint: const Color(0xFF333333),
            iconSize: 24,
            borderAlpha: 0.16,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ClientCasesScreen()),
              );
            },
          ),
          _IconTile(
            label: 'AI Help',
            icon: 'assets/icons/ic_qa_ai.svg',
            tint: const Color(0xFF444444),
            iconSize: 24,
            borderAlpha: 0.16,
            onTap: _openAdvokAi,
          ),
        ],
      ),
    );
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Widget _buildAppointments() {
    if (_upcomingBookings.isEmpty) {
      return const _EmptyState(
        icon: 'assets/icons/ic_clock.svg',
        title: 'No upcoming appointments',
        message:
            'Book a voice consultation from an attorney or law firm '
            'profile and it will show up here.',
      );
    }
    final rows = <Widget>[];
    for (int i = 0; i < _upcomingBookings.length; i++) {
      final b = _upcomingBookings[i];
      final kind = b['consultationType'] as String? ?? 'video_call';
      final date = DateTime.tryParse(b['date'] as String? ?? '');
      final dateLabel = date == null
          ? (b['time'] as String? ?? '')
          : '${_months[date.month - 1]} ${date.day} · ${b['time'] ?? ''}';
      final amount = (b['amount'] as num?)?.toDouble() ?? 0;
      final pending = b['status'] == 'pending';
      // Firm booking: show the attorney handling it (assigned, or the one the
      // client asked for) with the firm's name.
      final attorney =
          (b['assignedAttorney'] ?? b['requestedAttorney'])
              as Map<String, dynamic>?;
      final attorneyName = (attorney?['name'] as String? ?? '').trim();
      final firmName = (b['firmName'] as String? ?? '').trim();
      final title = attorneyName.isNotEmpty
          ? (firmName.isNotEmpty ? '$attorneyName · $firmName' : attorneyName)
          : (b['advocateName'] as String? ?? 'Attorney');
      rows.add(
        _AppointmentRow(
          icon: switch (kind) {
            'office_visit' => 'assets/icons/ic_office.svg',
            'phone_call' => 'assets/icons/ic_phone.svg',
            _ => 'assets/icons/ic_video.svg',
          },
          title: title,
          subtitle: switch (kind) {
            'office_visit' => 'Office Visit',
            'phone_call' => 'Phone Call',
            _ => 'Video Call',
          },
          time: dateLabel,
          badge: pending ? 'Pending' : 'Confirmed',
          badgeColor: pending
              ? const Color(0xFFB07A00)
              : const Color(0xFF1E7A46),
          price: '\$${amount.toStringAsFixed(0)}',
          showDivider: i < _upcomingBookings.length - 1,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(children: rows),
    );
  }
}

class _AdvocateData {
  const _AdvocateData({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.price,
    required this.image,
    this.photoBytes,
    this.raw,
  });

  final String name;
  final String specialty;
  final String experience;
  final String? rating;
  final String price;
  final String image;

  /// Decoded profile photo uploaded at onboarding (null if none).
  final Uint8List? photoBytes;

  /// The backend's advocate record, for opening the full profile.
  final Map<String, dynamic>? raw;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final String icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    // Full-width card so the content stays centred even though the home
    // column is left-aligned, and it matches the other section cards.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Center(child: SvgPicture.asset(icon, width: 22, height: 22)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square tinted icon tile with a label below, used for categories and
/// quick actions.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconSize,
    required this.borderAlpha,
    this.onTap,
  });

  final String label;
  final String icon;
  final Color tint;
  final double iconSize;
  final double borderAlpha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: _buildContent());
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tint.withValues(alpha: borderAlpha)),
          ),
          child: Center(
            child: icon.endsWith('.svg')
                ? SvgPicture.asset(icon, width: iconSize, height: iconSize)
                : Image.asset(icon, width: iconSize, height: iconSize),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: 0.06,
            color: AppColors.textGrey555,
          ),
        ),
      ],
    );
  }
}

class _AdvocateCard extends StatelessWidget {
  const _AdvocateCard(this.advocate, {this.onTap});

  final _AdvocateData advocate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.rs(158),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGrey),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: context.rs(116),
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (advocate.photoBytes != null)
                    Image.memory(advocate.photoBytes!, fit: BoxFit.cover)
                  else if (advocate.image.isEmpty)
                    _InitialsBox(name: advocate.name)
                  else
                    Image.asset(advocate.image, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_verified_badge.svg',
                            width: 9,
                            height: 9,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.17,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advocate.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 15 / 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advocate.specialty,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      letterSpacing: 0.12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (advocate.rating != null) ...[
                        Text(
                          advocate.rating!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: 0.12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        advocate.experience,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: 0.12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            // No fee collected at onboarding yet — show
                            // availability instead of an empty price.
                            if (advocate.price.isEmpty)
                              const TextSpan(
                                text: 'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: Color(0xFF2A2A2A),
                                ),
                              )
                            else ...[
                              TextSpan(
                                text: advocate.price,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.5,
                                  letterSpacing: -0.08,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const TextSpan(
                                text: '/hr',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.5,
                                  letterSpacing: 0.12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Book',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home-strip card for a verified law firm, sized to sit under the
/// attorney cards. Shows the logo (or initials), name, practice focus,
/// location and team size.
class _FirmCard extends StatelessWidget {
  const _FirmCard(this.firm, {this.onTap});

  final LawFirm firm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.rs(200),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGrey),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: context.rs(92),
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (firm.photoBytes != null)
                    Image.memory(firm.photoBytes!, fit: BoxFit.cover)
                  else
                    _InitialsBox(name: firm.name),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_verified_badge.svg',
                            width: 9,
                            height: 9,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.17,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firm.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 15 / 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firm.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      letterSpacing: 0.12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_pin.svg',
                        width: 10,
                        height: 10,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          firm.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: 0.12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        firm.totalLawyers > 0
                            ? '${firm.totalLawyers} lawyers'
                            : 'Full-service',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Book',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 0.12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback card image with the advocate's initials, used until profile
/// photos are collected during onboarding.
class _InitialsBox extends StatelessWidget {
  const _InitialsBox({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      color: AppColors.progressTrack,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.badge,
    required this.badgeColor,
    required this.price,
    required this.showDivider,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String time;
  final String badge;
  final Color badgeColor;
  final String price;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.divider))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.14),
              ),
            ),
            child: Center(child: SvgPicture.asset(icon, width: 20, height: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
                      'assets/icons/ic_clock.svg',
                      width: 10,
                      height: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        letterSpacing: 0.06,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0.12,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact row for live search results on the home screen.
class _LiveResultRow extends StatelessWidget {
  const _LiveResultRow({
    required this.name,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.photoBytes,
  });

  final String name;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: photoBytes != null
                      ? Image.memory(photoBytes!, fit: BoxFit.cover)
                      : _InitialsBox(name: name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12,
                    color: AppColors.textGrey555,
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
