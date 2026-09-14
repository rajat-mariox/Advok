import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/Responsive/responsive.dart';
import '../AdvocateListScreen/advocate_list_screen.dart'
    show Advocate, decodePhotoDataUrl;
import '../BookingScreen/consultation_type_screen.dart';

/// A verified law firm as the client browse screens see it, from the
/// backend's /law-firms response.
class LawFirm {
  const LawFirm({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.receptionNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.foundedYear,
    required this.totalLawyers,
    required this.expertise,
    required this.lawyers,
    this.photoBytes,
    this.consultationFee,
  });

  factory LawFirm.fromApi(Map<String, dynamic> json) {
    final address = [
      json['addressLine1'],
      json['addressLine2'],
      json['city'],
      json['state'],
      json['zip'],
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
    return LawFirm(
      id: json['id'] as String? ?? '',
      name: json['firmName'] as String? ?? 'Law Firm',
      contactPerson: json['contactPerson'] as String? ?? '',
      email: json['officialEmail'] as String? ?? '',
      phone: json['mainPhone'] as String? ?? '',
      receptionNumber: json['receptionNumber'] as String? ?? '',
      address: address.join(', '),
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      foundedYear: json['foundedYear'] as String? ?? '',
      totalLawyers: (json['totalLawyers'] as num?)?.toInt() ?? 0,
      expertise:
          (json['expertise'] as List<dynamic>? ?? []).cast<String>(),
      lawyers: [
        for (final l in (json['lawyers'] as List<dynamic>? ?? []))
          FirmLawyer.fromApi(l as Map<String, dynamic>),
      ],
      photoBytes: decodePhotoDataUrl(json['photo'] as String?),
      consultationFee: (json['consultationFee'] as num?)?.toDouble(),
    );
  }

  /// Voice-consultation fee charged for this firm (and its attorneys).
  final double? consultationFee;

  final String id;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String receptionNumber;
  final String address;
  final String city;
  final String state;
  final String foundedYear;
  final int totalLawyers;

  /// Distinct practice areas across the firm's listed lawyers.
  final List<String> expertise;
  final List<FirmLawyer> lawyers;

  /// Firm logo/photo uploaded at onboarding (null if none).
  final Uint8List? photoBytes;

  /// "City, State" for cards; falls back to the em dash.
  String get location {
    final parts = [city, state].where((s) => s.trim().isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  /// Short one-line summary for cards: first expertise or lawyer count.
  String get summary {
    if (expertise.isNotEmpty) return expertise.first;
    return totalLawyers > 0 ? '$totalLawyers attorneys' : 'Full-service firm';
  }

  /// The firm as a bookable provider, so the client uses the exact same
  /// consultation flow as for an attorney. Firms have no onboarding
  /// schedule, so office hours default to Mon–Fri, 9 AM – 5 PM.
  Advocate toAdvocate() => Advocate(
        id: id,
        name: name,
        specialty: expertise.isNotEmpty ? expertise.first : 'Law Firm',
        experience: totalLawyers > 0 ? '$totalLawyers attorneys' : 'Law Firm',
        cases: 'Law Firm',
        location: location,
        price: '',
        availability: 'Available',
        image: '',
        role: 'Law Firm',
        photoBytes: photoBytes,
        workingDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        startTime: '09:00',
        endTime: '17:00',
        consultationFee: consultationFee,
      );
}

class FirmLawyer {
  const FirmLawyer({
    required this.name,
    required this.designation,
    required this.yearsExperience,
    required this.expertise,
    this.barState = '',
    this.licenseStatus = '',
  });

  factory FirmLawyer.fromApi(Map<String, dynamic> json) => FirmLawyer(
        name: json['fullName'] as String? ?? 'Attorney',
        designation: json['designation'] as String? ?? '',
        yearsExperience: json['yearsExperience'] as String? ?? '',
        barState: json['barState'] as String? ?? '',
        licenseStatus: json['licenseStatus'] as String? ?? '',
        expertise:
            (json['expertise'] as List<dynamic>? ?? []).cast<String>(),
      );

  final String name;
  final String designation;
  final String yearsExperience;
  final String barState;
  final String licenseStatus;
  final List<String> expertise;
}

// ---------------------------------------------------------------------------
// Detail screen
// ---------------------------------------------------------------------------

/// Client-facing law firm profile: contact the firm by phone/email, see the
/// practice areas and the legal team. Modeled on AdvocateProfileScreen.
class LawFirmDetailScreen extends StatelessWidget {
  const LawFirmDetailScreen({super.key, required this.firm});

  final LawFirm firm;

  static const TextStyle _sectionTitleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: -0.08,
    color: AppColors.textPrimary,
  );

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
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: firm.totalLawyers > 0
                                ? '${firm.totalLawyers}'
                                : '—',
                            label: 'Attorneys',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            value: firm.foundedYear.isEmpty
                                ? '—'
                                : firm.foundedYear,
                            label: 'Founded',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            value: firm.expertise.isEmpty
                                ? '—'
                                : '${firm.expertise.length}',
                            label: 'Practice Areas',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (firm.address.isNotEmpty) ...[
                      const Text('Office', style: _sectionTitleStyle),
                      const SizedBox(height: 10),
                      _ContactCard(firm: firm),
                      const SizedBox(height: 20),
                    ],
                    _FirmFeeCard(fee: firm.consultationFee),
                    const SizedBox(height: 20),
                    const Text('Practice Areas', style: _sectionTitleStyle),
                    const SizedBox(height: 12),
                    if (firm.expertise.isEmpty)
                      const Text(
                        'This firm has not listed practice areas yet.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textGrey555,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in firm.expertise) _Chip(e),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Legal Team (${firm.lawyers.length})',
                      style: _sectionTitleStyle,
                    ),
                    const SizedBox(height: 10),
                    if (firm.lawyers.isEmpty)
                      const Text(
                        'Attorneys will appear here once the firm adds them.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textGrey555,
                        ),
                      )
                    else
                      for (int i = 0; i < firm.lawyers.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _LawyerTile(firm.lawyers[i]),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      onTap: () {
                        // Same flow as booking an attorney; the backend
                        // routes the request to the firm's account.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConsultationTypeScreen(
                              advocate: firm.toAdvocate(),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_calendar_white.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Book Appointment',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: context.rs(272),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (firm.photoBytes != null)
            Image.memory(firm.photoBytes!, fit: BoxFit.cover)
          else
            const ColoredBox(color: Color(0xFF2A2A2A)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xEB000000)],
              ),
            ),
          ),
          if (firm.photoBytes == null)
            Center(
              child: SvgPicture.asset(
                'assets/icons/ic_role_firm.svg',
                width: 64,
                height: 64,
                colorFilter: ColorFilter.mode(
                  AppColors.white.withValues(alpha: 0.35),
                  BlendMode.srcIn,
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 20,
            child: Material(
              color: AppColors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_arrow_back_white.svg',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_verified_badge.svg',
                        width: 9,
                        height: 9,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Verified Law Firm',
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
                const SizedBox(height: 8),
                Text(
                  firm.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 33 / 22,
                    letterSpacing: -0.81,
                    color: AppColors.white,
                  ),
                ),
                if (firm.contactPerson.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${firm.contactPerson} · Managing Partner',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: Color(0xFFD9D3D3),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_pin_white.svg',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        firm.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: Color(0xFFD9D3D3),
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
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.firm});

  final LawFirm firm;

  @override
  Widget build(BuildContext context) {
    // Only the office address is public. Phone and email are shared with
    // the client once the firm accepts a consultation request, same as for
    // an individual attorney.
    final rows = <(String, String, String)>[
      if (firm.address.isNotEmpty)
        ('assets/icons/ic_pin.svg', 'Address', firm.address),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.borderGrey),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(rows[i].$1, width: 16, height: 16),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 74,
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$3,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No contact details listed.',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey555),
              ),
            ),
        ],
      ),
    );
  }
}

class _LawyerTile extends StatelessWidget {
  const _LawyerTile(this.lawyer);

  final FirmLawyer lawyer;

  @override
  Widget build(BuildContext context) {
    final meta = [
      lawyer.designation,
      if (lawyer.yearsExperience.trim().isNotEmpty)
        '${lawyer.yearsExperience} yrs',
      if (lawyer.barState.trim().isNotEmpty) '${lawyer.barState} Bar',
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialsCircle(name: lawyer.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lawyer.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppColors.textGrey555,
                    ),
                  ),
                if (lawyer.expertise.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in lawyer.expertise) _Chip(e, small: true),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "See all" list screen
// ---------------------------------------------------------------------------

class LawFirmListScreen extends StatefulWidget {
  const LawFirmListScreen({super.key});

  @override
  State<LawFirmListScreen> createState() => _LawFirmListScreenState();
}

class _LawFirmListScreenState extends State<LawFirmListScreen> {
  List<LawFirm> _firms = [];
  bool _loading = true;
  String _loadError = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchLawFirms();
      if (!mounted) return;
      setState(() {
        _firms = result.map(LawFirm.fromApi).toList();
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

  List<LawFirm> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _firms;
    return [
      for (final f in _firms)
        if (f.name.toLowerCase().contains(q) ||
            f.location.toLowerCase().contains(q) ||
            f.expertise.any((e) => e.toLowerCase().contains(q)))
          f,
    ];
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const CircleBackButton(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Law Firms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.43,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_visible.isEmpty)
                      Padding(
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
                                  'assets/icons/ic_role_firm.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _loadError.isNotEmpty
                                  ? 'Could not load law firms'
                                  : 'No law firms yet',
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
                                  : 'Verified law firms in your area will '
                                      'appear here.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textGrey555,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        'Showing ${_visible.length} law firms near you',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < _visible.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        FirmListCard(firm: _visible[i]),
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

  Widget _buildSearchField() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_search.svg', width: 16, height: 16),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search firms, cities or practice areas',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row card for a law firm (Search tab + See-all list); opens the profile.
class FirmListCard extends StatelessWidget {
  const FirmListCard({super.key, required this.firm});

  final LawFirm firm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LawFirmDetailScreen(firm: firm)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 64,
                height: 64,
                child: firm.photoBytes != null
                    ? Image.memory(firm.photoBytes!, fit: BoxFit.cover)
                    : _InitialsCircle(name: firm.name, size: 64, square: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firm.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firm.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/ic_pin.svg',
                          width: 11, height: 11),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          firm.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        firm.totalLawyers > 0
                            ? '${firm.totalLawyers} attorneys'
                            : 'Verified',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: Color(0xFF2A2A2A),
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

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.5,
              letterSpacing: -0.43,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: small ? AppColors.white : AppColors.fillGrey,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 10.5 : 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: AppColors.textGrey555,
        ),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.name,
    required this.size,
    this.square = false,
  });

  final String name;
  final double size;
  final bool square;

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
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FirmFeeCard extends StatelessWidget {
  const _FirmFeeCard({required this.fee});

  final double? fee;

  static String _label(double v) => v == v.roundToDouble()
      ? '\$${v.toStringAsFixed(0)}'
      : '\$${v.toStringAsFixed(2)}';

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
          const Text(
            'Consultation Fee',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: AppColors.textGrey555,
            ),
          ),
          const SizedBox(height: 2),
          // The firm's rate comes with the firm record; if it is missing
          // (older cached object), fall back to the platform law-firm rate.
          FutureBuilder<Map<String, double>>(
            future: fee == null
                ? ApiService.fetchConsultationPricing()
                : Future.value(const <String, double>{}),
            builder: (context, snapshot) {
              final amount = fee ?? snapshot.data?['law_firm_phone_call'];
              final label = amount != null
                  ? _label(amount)
                  : snapshot.connectionState == ConnectionState.done
                      ? '—'
                      : '…';
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 39 / 26,
                        letterSpacing: 0.22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text: ' / voice consultation',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            "Firm's rate · applies to every attorney at this firm · 60 min "
            'call · platform fee and tax shown at checkout',
            style: TextStyle(
              fontSize: 11.5,
              height: 16 / 11.5,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
