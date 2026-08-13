import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../AdvocateProfileScreen/advocate_profile_screen.dart';

/// Decodes a 'data:image/...;base64,xxxx' string into bytes (null if empty
/// or malformed). Shared by the client browse screens.
Uint8List? decodePhotoDataUrl(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;
  final comma = dataUrl.indexOf(',');
  try {
    return base64Decode(
      comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl,
    );
  } catch (_) {
    return null;
  }
}

class Advocate {
  const Advocate({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.cases,
    required this.location,
    required this.price,
    required this.availability,
    required this.image,
    this.rating,
    this.tier = 'junior',
    this.role = '',
    this.photoBytes,
  });

  /// Builds a card model from the backend's /advocates response.
  factory Advocate.fromApi(Map<String, dynamic> json) {
    final tier = json['advocateType'] as String? ?? 'junior';
    final years = json['yearsInPractice'] as String?;
    final firmRole = json['firmRole'] as String?;
    final practiceArea = (json['practiceArea'] as String?)?.trim() ?? '';
    final location = [json['district'], json['state']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    return Advocate(
      name: json['name'] as String? ?? 'Advocate',
      specialty: practiceArea.isEmpty ? 'General Practice' : practiceArea,
      experience:
          years ?? (tier == 'senior' ? '10+ years' : 'Under 10 years'),
      cases: firmRole ?? (json['primaryCourt'] as String? ?? ''),
      location: location.isEmpty ? '—' : location,
      price: '',
      availability: 'Available',
      image: '',
      tier: tier,
      role: firmRole ?? '',
      photoBytes: decodePhotoDataUrl(json['photo'] as String?),
    );
  }

  final String name;
  final String specialty;
  final String experience;
  final String cases;
  final String location;
  final String price;
  final String availability;
  final String image;
  final String? rating;

  /// Internal junior/senior tier, used by the filter chips in countries
  /// without firm roles.
  final String tier;

  /// Firm role (Partner, Associate, …), used by the filter chips in countries
  /// with firm roles (US).
  final String role;

  /// Decoded profile photo uploaded at onboarding (null if none).
  final Uint8List? photoBytes;
}

class AdvocateListScreen extends StatefulWidget {
  const AdvocateListScreen({
    super.key,
    required this.title,
    this.practiceArea,
    this.onBack,
  });

  final String title;

  /// When set (opened from a Legal Categories tile), only advocates whose
  /// practice area matches are listed. Null shows every practice area.
  final String? practiceArea;

  /// Overrides the default back behaviour (popping the route). Used when the
  /// screen is embedded as the Search tab.
  final VoidCallback? onBack;

  @override
  State<AdvocateListScreen> createState() => _AdvocateListScreenState();
}

class _AdvocateListScreenState extends State<AdvocateListScreen> {
  // Filter chips follow the country: firm roles (Partner, Associate, …) where
  // the country uses them (US), otherwise the junior/senior tiers.
  List<String> get _filters {
    final terms = CountryCatalog.terms;
    return [
      'All',
      if (terms.usesFirmRoles)
        ...terms.firmRoles
      else ...[terms.juniorTitle, terms.seniorTitle],
    ];
  }

  int _selectedFilter = 0;
  String _query = '';

  List<Advocate> _advocates = [];
  bool _loading = true;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchAdvocates();
      if (!mounted) return;
      setState(() {
        _advocates = result.map(Advocate.fromApi).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  /// Advocates matching the screen's practice area (if any), the active
  /// filter chip and the search text.
  List<Advocate> get _visible {
    final q = _query.trim().toLowerCase();
    final area = widget.practiceArea?.trim().toLowerCase();
    return [
      for (final a in _advocates)
        if (_matchesArea(a, area) &&
            _matchesFilterChip(a) &&
            (q.isEmpty ||
                a.name.toLowerCase().contains(q) ||
                a.specialty.toLowerCase().contains(q) ||
                a.location.toLowerCase().contains(q)))
          a,
    ];
  }

  /// Practice-area match. Dropdown-registered attorneys carry the exact
  /// catalog string; the two-way contains also catches older free-text
  /// profiles ("Criminal" matches the "Criminal Defense" category).
  static bool _matchesArea(Advocate a, String? area) {
    if (area == null) return true;
    final s = a.specialty.trim().toLowerCase();
    if (s.isEmpty) return false;
    return s.contains(area) || area.contains(s);
  }

  bool _matchesFilterChip(Advocate a) {
    if (_selectedFilter == 0) return true;
    if (CountryCatalog.terms.usesFirmRoles) {
      return a.role == _filters[_selectedFilter];
    }
    return a.tier == (_selectedFilter == 1 ? 'junior' : 'senior');
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildFilterChips(),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_visible.isEmpty)
                      _buildEmptyState()
                    else ...[
                      Text(
                        'Showing ${_visible.length} '
                        '${CountryCatalog.terms.lawyerPlural.toLowerCase()} '
                        'near you',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < _visible.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _AdvocateListCard(advocate: _visible[i]),
                      ],
                    ],
                  ],
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleBackButton(onTap: widget.onBack),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // TODO: Open the filters sheet.
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_filter.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_search.svg', width: 16, height: 16),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText:
                    'Search ${CountryCatalog.terms.lawyerPlural.toLowerCase()}...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  letterSpacing: -0.15,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
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
                'assets/icons/ic_search.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No ${CountryCatalog.terms.lawyerPlural.toLowerCase()} yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loadError.isNotEmpty
                ? _loadError
                : _advocates.isNotEmpty
                    ? 'No ${CountryCatalog.terms.lawyerPlural.toLowerCase()} '
                        'match your search or filter.'
                    : '${CountryCatalog.terms.lawyerPlural} will appear here '
                        'once verified '
                        '${CountryCatalog.terms.lawyerPlural.toLowerCase()} '
                        'join the platform.',
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.textPrimary : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(100),
                border: selected
                    ? null
                    : Border.all(color: AppColors.borderGrey),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    color: selected ? AppColors.white : AppColors.textGrey555,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdvocateListCard extends StatelessWidget {
  const _AdvocateListCard({required this.advocate});

  final Advocate advocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: advocate.photoBytes != null
                ? Image.memory(
                    advocate.photoBytes!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : advocate.image.isEmpty
                    ? InitialsAvatar(name: advocate.name, size: 72)
                    : Image.asset(
                        advocate.image,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                advocate.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  letterSpacing: -0.08,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.fillGrey,
                                    width: 1.4,
                                  ),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/ic_check.svg',
                                    width: 10,
                                    height: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            advocate.specialty,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: AppColors.textGrey555,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Toggle favourite.
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.asset(
                          'assets/icons/ic_heart.svg',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (advocate.rating != null) ...[
                      SvgPicture.asset(
                        'assets/icons/ic_star.svg',
                        width: 11,
                        height: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        advocate.rating!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 16 / 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const _DotSeparator(),
                    ],
                    Text(advocate.experience, style: _metaStyle),
                    const _DotSeparator(),
                    Text(advocate.cases, style: _metaStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_pin.svg',
                      width: 10,
                      height: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(advocate.location, style: _metaStyle),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          // Fee is not collected at onboarding yet; hide the
                          // "/hr" price part until the advocate sets one.
                          if (advocate.price.isNotEmpty) ...[
                            TextSpan(
                              text: advocate.price,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.5,
                                letterSpacing: -0.31,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const TextSpan(
                              text: '/hr ',
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                          TextSpan(
                            text: advocate.availability,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16 / 12,
                              color: Color(0xFF2A2A2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AdvocateProfileScreen(advocate: advocate),
                          ),
                        );
                      },
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            'View Profile',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    color: AppColors.textGrey555,
  );
}

/// Fallback avatar with the advocate's initials, shown when the advocate has
/// no uploaded photo. Shared by the client browse/booking screens.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      color: AppColors.progressTrack,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 10,
          height: 1.5,
          letterSpacing: 0.12,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}
