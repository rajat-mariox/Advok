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
    return base64Decode(comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl);
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
    this.id = '',
    this.rating,
    this.tier = 'junior',
    this.role = '',
    this.photoBytes,
    this.workingDays = const [],
    this.startTime = '',
    this.endTime = '',
    this.firmName = '',
    this.caseCount = 0,
    this.consultationCount = 0,
    this.consultationFee,
    this.barStates = const [],
    this.federalCourts = const [],
    this.yearsInPractice = '',
  });

  /// Builds a card model from the backend's /advocates response.
  factory Advocate.fromApi(Map<String, dynamic> json) {
    final tier = json['advocateType'] as String? ?? 'junior';
    final years = json['yearsInPractice'] as String?;
    final firmRole = json['firmRole'] as String?;
    final practiceArea = (json['practiceArea'] as String?)?.trim() ?? '';
    final location = [
      json['district'],
      json['state'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return Advocate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Advocate',
      specialty: practiceArea.isEmpty ? 'General Practice' : practiceArea,
      experience: years ?? (tier == 'senior' ? '10+ years' : 'Under 10 years'),
      cases: firmRole ?? (json['primaryCourt'] as String? ?? ''),
      location: location.isEmpty ? '—' : location,
      price: '',
      availability: 'Available',
      image: '',
      tier: tier,
      role: firmRole ?? '',
      firmName: json['firmName'] as String? ?? '',
      caseCount: (json['caseCount'] as num?)?.toInt() ?? 0,
      consultationCount: (json['consultationCount'] as num?)?.toInt() ?? 0,
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
      barStates: (json['barStates'] as List<dynamic>? ?? []).cast<String>(),
      federalCourts: (json['federalCourts'] as List<dynamic>? ?? [])
          .cast<String>(),
      yearsInPractice: years ?? '',
      photoBytes: decodePhotoDataUrl(json['photo'] as String?),
      workingDays: (json['workingDays'] as List<dynamic>? ?? []).cast<String>(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
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

  /// Backend user id, needed to book this advocate ('' for demo data).
  final String id;

  /// Weekly availability from onboarding: day labels ('Mon'…'Sun') plus
  /// 24h 'HH:mm' office hours. Drive the booking date/slot pickers.
  final List<String> workingDays;
  final String startTime;
  final String endTime;

  /// Law firm this attorney belongs to ('' for solo practitioners).
  final String firmName;

  /// Cases handled on ADVOK and consultations held, from the backend.
  final int caseCount;
  final int consultationCount;

  /// Voice-consultation fee for this provider (firm attorneys charge their
  /// firm's rate). Null → platform attorney rate.
  final double? consultationFee;

  /// US: states whose bar licensed this attorney; federal court admissions.
  final List<String> barStates;
  final List<String> federalCourts;

  /// Raw years band from onboarding ("3–5 years"), '' when absent.
  final String yearsInPractice;

  /// Lower bound of the experience band, for filtering and sorting:
  /// "0–2" → 0, "3–5" → 3, "6–10" → 6, "11–20" → 11, "20+" → 20.
  /// Countries without bands: senior → 10, junior → 0.
  int get yearsMin {
    final m = RegExp(r'(\d+)').firstMatch(yearsInPractice);
    if (m != null) return int.parse(m.group(1)!);
    return tier == 'senior' ? 10 : 0;
  }

  /// Every state this attorney is tied to (practice location + bar states).
  Set<String> get allStates => {
    if (location.contains(',')) location.split(',').last.trim(),
    ...barStates,
  }..removeWhere((s) => s.isEmpty || s == '—');
}

class AdvocateListScreen extends StatefulWidget {
  const AdvocateListScreen({
    super.key,
    required this.title,
    this.practiceArea,
    this.onBack,
    this.initialQuery,
  });

  /// Pre-filled search text (from the home screen search bar).
  final String? initialQuery;

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
      else ...[
        terms.juniorTitle,
        terms.seniorTitle,
      ],
    ];
  }

  int _selectedFilter = 0;
  late String _query = widget.initialQuery?.trim() ?? '';
  late final TextEditingController _searchController = TextEditingController(
    text: _query,
  );

  // Filter sheet state.
  String? _stateFilter;
  String? _areaFilter;
  int _minYears = 0;
  double? _maxFee;
  final Set<String> _days = <String>{};
  String _sort = _sortOptions.first;

  static const List<String> _sortOptions = [
    'Recommended',
    'Most experienced',
    'Lowest fee',
    'Most consultations',
  ];
  static const List<int> _yearOptions = [0, 2, 5, 10, 20];
  static const List<double?> _feeOptions = [null, 50, 100, 200];
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Platform attorney rate, used when an attorney carries no fee of its own
  /// (fee filter and "Lowest fee" sort).
  double _defaultFee = 90;

  List<Advocate> _advocates = [];
  bool _loading = true;
  String _loadError = '';

  int get _activeFilterCount =>
      (_stateFilter != null ? 1 : 0) +
      (_areaFilter != null ? 1 : 0) +
      (_minYears > 0 ? 1 : 0) +
      (_maxFee != null ? 1 : 0) +
      (_days.isNotEmpty ? 1 : 0);

  double _feeOf(Advocate a) => a.consultationFee ?? _defaultFee;

  /// States offered in the filter: only those attorneys actually have.
  List<String> get _availableStates {
    final set = <String>{};
    for (final a in _advocates) {
      set.addAll(a.allStates);
    }
    return set.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchAdvocates();
      if (!mounted) return;
      setState(() {
        _advocates = result.map(Advocate.fromApi).toList();
        _loading = false;
      });
      try {
        final pricing = await ApiService.fetchConsultationPricing();
        if (mounted) {
          setState(() => _defaultFee = pricing['phone_call'] ?? _defaultFee);
        }
      } catch (_) {
        // Keep the seeded default.
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  /// Advocates matching the screen's practice area (if any), the role chip,
  /// the filter sheet and the search text — then sorted.
  List<Advocate> get _visible {
    final q = _query.trim().toLowerCase();
    final area = (_areaFilter ?? widget.practiceArea)?.trim().toLowerCase();
    final list = [
      for (final a in _advocates)
        if (_matchesArea(a, area) &&
            _matchesFilterChip(a) &&
            _matchesSheet(a) &&
            (q.isEmpty || _matchesQuery(a, q)))
          a,
    ];
    switch (_sort) {
      case 'Most experienced':
        list.sort((a, b) => b.yearsMin.compareTo(a.yearsMin));
      case 'Lowest fee':
        list.sort((a, b) => _feeOf(a).compareTo(_feeOf(b)));
      case 'Most consultations':
        list.sort((a, b) => b.consultationCount.compareTo(a.consultationCount));
      default:
        break; // backend order
    }
    return list;
  }

  /// Free-text search: name, practice area, city/state, law firm, bar
  /// states, federal courts and the experience band ("10", "20+").
  static bool _matchesQuery(Advocate a, String q) {
    final haystack = [
      a.name,
      a.specialty,
      a.location,
      a.firmName,
      a.role,
      a.experience,
      a.yearsInPractice,
      ...a.barStates,
      ...a.federalCourts,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  bool _matchesSheet(Advocate a) {
    if (_stateFilter != null && !a.allStates.contains(_stateFilter)) {
      return false;
    }
    if (_minYears > 0 && a.yearsMin < _minYears) return false;
    if (_maxFee != null && _feeOf(a) > _maxFee!) return false;
    if (_days.isNotEmpty && !_days.every(a.workingDays.contains)) return false;
    return true;
  }

  void _resetFilters() {
    setState(() {
      _stateFilter = null;
      _areaFilter = null;
      _minYears = 0;
      _maxFee = null;
      _days.clear();
      _sort = _sortOptions.first;
    });
  }

  String _feeLabel(double? v) =>
      v == null ? 'Any' : 'Under \$${v.toStringAsFixed(0)}';

  Future<void> _showFilterSheet() async {
    // Work on copies; commit on Apply.
    var state = _stateFilter;
    var areaSel = _areaFilter;
    var years = _minYears;
    var fee = _maxFee;
    final days = Set<String>.from(_days);
    var sort = _sort;
    final states = _availableStates;
    final areas = CountryCatalog.terms.practiceAreas;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          Widget section(String title, Widget child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              child,
              const SizedBox(height: 18),
            ],
          );
          Widget chip(String label, bool selected, VoidCallback onTap) =>
              Material(
                color: selected ? AppColors.textPrimary : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.borderGrey,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setSheet(() {
                            state = null;
                            areaSel = null;
                            years = 0;
                            fee = null;
                            days.clear();
                            sort = _sortOptions.first;
                          }),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGrey555,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          section(
                            'SORT BY',
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final o in _sortOptions)
                                  chip(
                                    o,
                                    sort == o,
                                    () => setSheet(() => sort = o),
                                  ),
                              ],
                            ),
                          ),
                          if (states.isNotEmpty)
                            section(
                              'LICENSED / PRACTICING IN',
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip(
                                    'Any state',
                                    state == null,
                                    () => setSheet(() => state = null),
                                  ),
                                  for (final st in states)
                                    chip(
                                      st,
                                      state == st,
                                      () => setSheet(() => state = st),
                                    ),
                                ],
                              ),
                            ),
                          if (widget.practiceArea == null)
                            section(
                              'PRACTICE AREA',
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip(
                                    'Any',
                                    areaSel == null,
                                    () => setSheet(() => areaSel = null),
                                  ),
                                  for (final ar in areas)
                                    chip(
                                      ar,
                                      areaSel == ar,
                                      () => setSheet(() => areaSel = ar),
                                    ),
                                ],
                              ),
                            ),
                          section(
                            'YEARS IN PRACTICE',
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final y in _yearOptions)
                                  chip(
                                    y == 0 ? 'Any' : '$y+ years',
                                    years == y,
                                    () => setSheet(() => years = y),
                                  ),
                              ],
                            ),
                          ),
                          section(
                            'CONSULTATION FEE',
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final f in _feeOptions)
                                  chip(
                                    _feeLabel(f),
                                    fee == f,
                                    () => setSheet(() => fee = f),
                                  ),
                              ],
                            ),
                          ),
                          section(
                            'AVAILABLE ON',
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _weekdays)
                                  chip(
                                    d,
                                    days.contains(d),
                                    () => setSheet(() {
                                      if (!days.remove(d)) days.add(d);
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(sheetContext).pop(true),
                            child: const Center(
                              child: Text(
                                'Show results',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.23,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _stateFilter = state;
        _areaFilter = areaSel;
        _minYears = years;
        _maxFee = fee;
        _days
          ..clear()
          ..addAll(days);
        _sort = sort;
      });
    }
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Showing ${_visible.length} '
                              '${CountryCatalog.terms.lawyerPlural.toLowerCase()}'
                              '${_sort == _sortOptions.first ? '' : ' · ${_sort.toLowerCase()}'}'
                              '${_activeFilterCount > 0 ? ' · $_activeFilterCount filter${_activeFilterCount == 1 ? '' : 's'}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          if (_activeFilterCount > 0 ||
                              _sort != _sortOptions.first)
                            GestureDetector(
                              onTap: _resetFilters,
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
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
              onTap: _showFilterSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _activeFilterCount > 0
                        ? AppColors.textPrimary
                        : AppColors.borderGrey,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_filter.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search by name, practice area, state or firm',
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
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
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
