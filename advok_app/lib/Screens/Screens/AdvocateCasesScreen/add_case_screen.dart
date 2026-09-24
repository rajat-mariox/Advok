import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../AdvocateListScreen/advocate_list_screen.dart'
    show InitialsAvatar, decodePhotoDataUrl;
import 'advocate_cases_screen.dart' show CasePriority, CasePriorityLabel;

/// An existing Advok client of this attorney, from the /clients response.
class _ClientOption {
  const _ClientOption({
    required this.id,
    required this.name,
    this.photoBytes,
  });

  factory _ClientOption.fromApi(Map<String, dynamic> json) {
    return _ClientOption(
      id: json['clientId'] as String? ?? '',
      name: json['clientName'] as String? ?? 'Client',
      photoBytes: decodePhotoDataUrl(json['clientPhoto'] as String?),
    );
  }

  final String id;
  final String name;
  final Uint8List? photoBytes;
}

/// A docket match from the court-records lookup (CourtListener / PACER).
class _DocketMatch {
  const _DocketMatch({
    required this.docketId,
    required this.caseName,
    required this.docketNumber,
    required this.court,
    this.judge,
    this.dateFiled,
    this.dateTerminated,
    this.natureOfSuit,
    this.cause,
    this.jurisdictionType,
    this.parties = const [],
    this.practiceArea,
  });

  factory _DocketMatch.fromApi(Map<String, dynamic> json) {
    return _DocketMatch(
      docketId: (json['docketId'] as num?)?.toInt() ?? 0,
      caseName: json['caseName'] as String? ?? '',
      docketNumber: json['docketNumber'] as String? ?? '',
      court: json['court'] as String? ?? '',
      judge: json['judge'] as String?,
      dateFiled: json['dateFiled'] as String?,
      dateTerminated: json['dateTerminated'] as String?,
      natureOfSuit: json['natureOfSuit'] as String?,
      cause: json['cause'] as String?,
      jurisdictionType: json['jurisdictionType'] as String?,
      parties: (json['parties'] as List<dynamic>? ?? const [])
          .map((p) => p.toString())
          .toList(),
      practiceArea: json['practiceArea'] as String?,
    );
  }

  /// 'Plaintiff v. Defendant' from the first two parties, when the docket
  /// has no case name of its own.
  String get displayName {
    if (caseName.isNotEmpty) return caseName;
    if (parties.length >= 2) return '${parties[0]} v. ${parties[1]}';
    return docketNumber;
  }

  /// Provider's docket id — linking the case to it enables status sync.
  final int docketId;
  final String caseName;
  final String docketNumber;
  final String court;
  final String? judge;
  final String? dateFiled;

  /// Set when the court has already closed the docket.
  final String? dateTerminated;

  /// PACER nature of suit, e.g. '410 Anti-Trust'.
  final String? natureOfSuit;

  /// Statutory cause of action, e.g. '15:1 Antitrust Litigation'.
  final String? cause;
  final String? jurisdictionType;
  final List<String> parties;

  /// Practice area the backend suggests from the nature of suit; applied
  /// only when it is one of this country's practice areas.
  final String? practiceArea;
}

/// Attorney opens a case for an existing Advok client: pick the client,
/// enter the case/docket number (with an optional court-records search),
/// confirm or complete the details manually, and create the case.
class AddCaseScreen extends StatefulWidget {
  const AddCaseScreen({super.key});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final TextEditingController _caseNumberController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  List<_ClientOption> _clients = [];
  bool _clientsLoading = true;
  String _clientsError = '';
  String? _clientId;

  bool _searching = false;
  bool _searched = false;
  bool _lookupAvailable = true;
  List<_DocketMatch> _matches = [];

  /// The docket the case will sync from, once the attorney picks a match.
  _DocketMatch? _linked;

  /// Narrow the court-records search to one state's federal courts, and
  /// optionally to one court, so the same docket number in other courts
  /// doesn't show up.
  String? _searchState;
  String? _searchCourtId;
  List<({String id, String name})> _stateCourts = const [];

  /// Every federal district/bankruptcy court, from the backend (55 states
  /// and territories incl. District of Columbia and Puerto Rico). Loaded
  /// once; the state list is derived from it, not from the country catalog.
  List<({String id, String name, String state})> _allCourts = const [];

  List<String> get _searchStates {
    if (_allCourts.isEmpty) return CountryCatalog.selected.states;
    final states = _allCourts.map((c) => c.state).toSet().toList()..sort();
    return states;
  }

  String? _court;
  String? _practiceArea;
  CasePriority? _priority;
  DateTime? _filedDate;
  DateTime? _nextHearing;
  bool _submitting = false;

  /// State + federal courts of the country chosen at login, plus the exact
  /// court name from the linked docket when it isn't already in the list.
  List<String> get _courts {
    final base = [
      ...CountryCatalog.terms.courts,
      ...CountryCatalog.terms.federalCourts,
    ];
    final linkedCourt = _linked?.court ?? '';
    if (linkedCourt.isNotEmpty &&
        !base.any((c) => c.toLowerCase() == linkedCourt.toLowerCase())) {
      base.add(linkedCourt);
    }
    return base;
  }

  @override
  void initState() {
    super.initState();
    _caseNumberController.addListener(_onDocketNumberChanged);
    _loadClients();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    try {
      final rows = await ApiService.fetchCourts();
      if (!mounted) return;
      setState(() {
        _allCourts = rows
            .map((c) => (
                  id: c['id'] as String? ?? '',
                  name: c['name'] as String? ?? '',
                  state: c['state'] as String? ?? '',
                ))
            .where((c) => c.id.isNotEmpty && c.state.isNotEmpty)
            .toList();
      });
    } on ApiException {
      // Falls back to the country catalog's state list.
    }
  }

  /// Editing the docket number after linking breaks the link — the sync
  /// would otherwise follow a docket that no longer matches what's typed.
  void _onDocketNumberChanged() {
    final linked = _linked;
    if (linked == null) return;
    if (_caseNumberController.text.trim() != linked.docketNumber) {
      setState(() {
        _linked = null;
        if (!_courts.contains(_court)) _court = null;
      });
    }
  }

  @override
  void dispose() {
    _caseNumberController.removeListener(_onDocketNumberChanged);
    _caseNumberController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final result = await ApiService.fetchClients();
      if (!mounted) return;
      setState(() {
        _clients = result.map(_ClientOption.fromApi).toList();
        _clientsError = '';
        _clientsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _clientsError = e.message;
        _clientsLoading = false;
      });
    }
  }

  /// Court API search per the case flow: when a court-records provider is
  /// configured the matches prefill the form; otherwise the attorney enters
  /// the details manually.
  Future<void> _searchCourtRecords() async {
    final number = _caseNumberController.text.trim();
    if (number.isEmpty || _searching) return;
    setState(() => _searching = true);
    try {
      final data = await ApiService.docketLookup(
        number,
        state: _searchState,
        courtId: _searchCourtId,
      );
      if (!mounted) return;
      final matches = (data['results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_DocketMatch.fromApi)
          .toList();
      setState(() {
        _searched = true;
        _lookupAvailable = data['available'] == true;
        _matches = matches;
      });
      // Exactly one docket matched (or a CourtListener link was pasted):
      // link it straight away instead of asking the attorney to tap it.
      if (matches.length == 1 && matches.first.docketId > 0) {
        _applyMatch(matches.first);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pickSearchState(String? state) {
    setState(() {
      _searchState = state;
      _searchCourtId = null;
      _stateCourts = state == null
          ? const []
          : _allCourts
              .where((c) => c.state == state)
              .map((c) => (id: c.id, name: c.name))
              .toList();
    });
  }

  void _applyMatch(_DocketMatch match) {
    setState(() {
      _linked = match.docketId > 0 ? match : null;
      if (match.caseName.isNotEmpty) _titleController.text = match.caseName;
      if (match.docketNumber.isNotEmpty) {
        _caseNumberController.text = match.docketNumber;
      }
      if (match.court.isNotEmpty) {
        // Use the court exactly as the records name it; `_courts` adds it to
        // the picker when it isn't one of the generic labels.
        _court = _courts.firstWhere(
          (c) => c.toLowerCase() == match.court.toLowerCase(),
          orElse: () => match.court,
        );
      }
      final filed = DateTime.tryParse(match.dateFiled ?? '');
      if (filed != null) _filedDate = filed;
      final suggested = match.practiceArea;
      if (suggested != null &&
          CountryCatalog.terms.practiceAreas.contains(suggested)) {
        _practiceArea = suggested;
      }
    });
  }

  bool get _formValid =>
      _clientId != null &&
      _caseNumberController.text.trim().isNotEmpty &&
      _titleController.text.trim().isNotEmpty &&
      _court != null;

  String? _isoDay(DateTime? day) => day == null
      ? null
      : '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await ApiService.createCase(
        clientId: _clientId!,
        title: _titleController.text.trim(),
        caseNumber: _caseNumberController.text.trim(),
        court: _court!,
        practiceArea: _practiceArea,
        priority: _priority?.apiValue,
        filedDate: _isoDay(_filedDate),
        nextHearing: _isoDay(_nextHearing),
        courtDocketId: _linked?.docketId,
      );
      if (!mounted) return;
      final created = result;
      final events = (created['timeline'] as List<dynamic>? ?? const [])
          .where((e) => e is Map && e['source'] == 'court_api')
          .length;
      final status = created['status'] as String? ?? 'active';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _linked == null
                ? 'Case created.'
                : events > 0
                    ? 'Case created and linked — $events court filings added to the '
                        'timeline${status == 'closed' ? ', marked Closed by the court' : ''}.'
                    : 'Case created and linked — no filings on record yet; it will sync automatically.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    const _SectionHeader('CLIENT'),
                    const SizedBox(height: 4),
                    const Text(
                      'Cases are linked to an existing ADVOK client.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 18 / 12.5,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildClientPicker(),
                    const SizedBox(height: 24),
                    const _SectionHeader('CASE / DOCKET NUMBER'),
                    const SizedBox(height: 12),
                    _buildDocketField(),
                    if (_linked != null) ...[
                      const SizedBox(height: 12),
                      _buildLinkedBanner(_linked!),
                    ] else if (_searched) ...[
                      const SizedBox(height: 12),
                      _buildSearchOutcome(),
                    ],
                    const SizedBox(height: 24),
                    const _SectionHeader('CASE DETAILS'),
                    const SizedBox(height: 12),
                    const _FieldLabel('Case Title', required: true),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g. Smith v. Jones',
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Court', required: true),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _court,
                      hint: 'Select court',
                      options: _courts,
                      onChanged: (v) => setState(() => _court = v),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Practice Area'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _practiceArea,
                      hint: 'Select practice area',
                      options: CountryCatalog.terms.practiceAreas,
                      onChanged: (v) => setState(() => _practiceArea = v),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Priority'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _priority?.label,
                      hint: 'Select priority',
                      options: CasePriority.values.map((p) => p.label).toList(),
                      onChanged: (v) => setState(() {
                        _priority = CasePriority.values
                            .where((p) => p.label == v)
                            .firstOrNull;
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Date Filed',
                            value: _filedDate,
                            onPicked: (d) => setState(() => _filedDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'Next Court Event',
                            value: _nextHearing,
                            onPicked: (d) => setState(() => _nextHearing = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
      child: Row(
        children: [
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_arrow_back.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Add Case',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildClientPicker() {
    if (_clientsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_clientsError.isNotEmpty || _clients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Text(
          _clientsError.isNotEmpty
              ? _clientsError
              : 'No ADVOK clients yet. Accept a consultation request first — '
                  'accepted clients appear here automatically.',
          style: const TextStyle(
            fontSize: 12.5,
            height: 18 / 12.5,
            color: AppColors.textGrey555,
          ),
        ),
      );
    }
    // Tap the field, pick a client from a bottom sheet (photo + name).
    final selected = _clients.where((c) => c.id == _clientId).firstOrNull;
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showClientPicker,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected != null ? AppColors.textPrimary : AppColors.borderGrey,
            ),
          ),
          child: Row(
            children: [
              if (selected == null) ...[
                const Icon(Icons.person_outline, size: 20, color: AppColors.textGrey),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Select client',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.15,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ] else
                Expanded(child: _clientRow(selected, compact: true)),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey555),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientPicker() {
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
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Select Client',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 24 / 17,
                  letterSpacing: -0.34,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Clients whose consultation you accepted.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final client in _clients)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipOval(
                          child: client.photoBytes == null
                              ? InitialsAvatar(name: client.name, size: 40)
                              : Image.memory(client.photoBytes!, fit: BoxFit.cover),
                        ),
                      ),
                      title: Text(
                        client.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: client.id == _clientId
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 20 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: client.id == _clientId
                          ? const Icon(Icons.check_rounded, size: 18, color: AppColors.textPrimary)
                          : null,
                      onTap: () {
                        setState(() => _clientId = client.id);
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

  /// Photo + name row shown in the field once a client is selected.
  Widget _clientRow(_ClientOption client, {bool compact = false}) {
    final size = compact ? 30.0 : 36.0;
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ClipOval(
            child: client.photoBytes == null
                ? InitialsAvatar(name: client.name, size: size)
                : Image.memory(client.photoBytes!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            client.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocketField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Case / Docket Number', required: true),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _caseNumberController,
          hint: 'e.g. 1:24-cv-01234, or paste a CourtListener docket link',
        ),
        const SizedBox(height: 10),
        const _FieldLabel('Search in (state / court)'),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _searchState,
          hint: 'Any state',
          options: _searchStates,
          onChanged: _pickSearchState,
        ),
        if (_searchState != null) ...[
          const SizedBox(height: 8),
          _buildDropdown(
                  value: _stateCourts
                          .any((c) => c.id == _searchCourtId)
                      ? _stateCourts
                          .firstWhere((c) => c.id == _searchCourtId)
                          .name
                      : null,
                  hint: 'All federal courts in $_searchState',
                  options: _stateCourts.map((c) => c.name).toList(),
                  onChanged: (name) => setState(() {
                    _searchCourtId = _stateCourts
                        .where((c) => c.name == name)
                        .map((c) => c.id)
                        .firstOrNull;
                  }),
                ),
        ],
        const SizedBox(height: 4),
        const Text(
          'The same docket number exists in many courts. Pick the state or '
          'court to get one exact match, which links automatically.',
          style: TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textGrey),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _caseNumberController.text.trim().isEmpty || _searching
                ? null
                : _searchCourtRecords,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderGrey),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _searching
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : SvgPicture.asset(
                    'assets/icons/ic_search.svg',
                    width: 14,
                    height: 14,
                  ),
            label: Text(
              _searching ? 'Searching…' : 'Search Court Records',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchOutcome() {
    if (!_lookupAvailable) {
      return _buildNotice(
        'Court records (CourtListener / PACER) couldn\'t be reached right '
        'now. Enter the case details manually below — you can update them '
        'anytime.',
      );
    }
    if (_matches.isEmpty) {
      return _buildNotice(
        'No US federal court records matched this docket number. State '
        'court cases aren\'t covered — enter the details manually below.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_matches.length} dockets share this number — tap the right court to link it '
          '(or narrow the search by state above):',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _matches.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _applyMatch(_matches[i]),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _matches[i].displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        _matches[i].docketNumber,
                        if (_matches[i].court.isNotEmpty) _matches[i].court,
                        if (_matches[i].dateFiled != null)
                          'Filed ${_matches[i].dateFiled}',
                        if (_matches[i].dateTerminated != null)
                          'Closed ${_matches[i].dateTerminated}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    if (_matches[i].natureOfSuit != null ||
                        (_matches[i].judge ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (_matches[i].natureOfSuit != null)
                            _matches[i].natureOfSuit!,
                          if ((_matches[i].judge ?? '').isNotEmpty)
                            'Judge ${_matches[i].judge}',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Everything the court records tell us about the linked docket, as
  /// label/value rows for the banner.
  List<(String, String)> _linkedRows(_DocketMatch match) {
    final parties = match.parties;
    return [
      ('Case', match.displayName),
      if (match.court.isNotEmpty) ('Court', match.court),
      if ((match.judge ?? '').isNotEmpty) ('Judge', match.judge!),
      if (match.dateFiled != null) ('Filed', match.dateFiled!),
      ('Status', match.dateTerminated != null
          ? 'Closed ${match.dateTerminated}'
          : 'Open'),
      if (match.natureOfSuit != null) ('Nature of suit', match.natureOfSuit!),
      if (match.cause != null) ('Cause', match.cause!),
      if (match.jurisdictionType != null)
        ('Jurisdiction', match.jurisdictionType!),
      if (parties.isNotEmpty)
        (
          'Parties',
          parties.length > 4
              ? '${parties.take(4).join(', ')} +${parties.length - 4} more'
              : parties.join(', '),
        ),
    ];
  }

  /// Shown once a docket match is applied: the case will sync its status and
  /// timeline from this docket after it is created.
  Widget _buildLinkedBanner(_DocketMatch match) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.link, size: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Linked to court records',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                for (final row in _linkedRows(match)) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            row.$1,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.$2,
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  match.dateTerminated != null
                      ? 'The court has closed this docket — the case will be '
                          'created as Closed with its filings on the timeline.'
                      : 'Filings and status will be pulled from the court '
                          'records automatically.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.textGrey555,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              _linked = null;
              if (!_courts.contains(_court)) _court = null;
            }),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                'Unlink',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12.5,
          height: 18 / 12.5,
          color: AppColors.textGrey555,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontSize: 14,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
          dropdownColor: AppColors.white,
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        Material(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 20),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) onPicked(picked);
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null
                          ? 'Select date'
                          : '${value.month}/${value.day}/${value.year}',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: -0.15,
                        color: value == null
                            ? AppColors.textGrey
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/ic_calendar_dark.svg',
                    width: 14,
                    height: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final enabled = _formValid && !_submitting;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: enabled
              ? [AppColors.textPrimary, AppColors.gradientDarkEnd]
              : [AppColors.progressTrack, AppColors.progressTrack],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? _submit : null,
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(
                _submitting ? 'Creating…' : 'Create Case',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: enabled ? AppColors.white : AppColors.textGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 1.16,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 19.5 / 13,
          letterSpacing: -0.08,
          color: AppColors.textPrimary,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFF9A3B3B)),
            ),
        ],
      ),
    );
  }
}
