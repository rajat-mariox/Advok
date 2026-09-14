import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import 'add_case_screen.dart';
import 'case_details_screen.dart';

enum CaseStatus { active, hearing, discovery, closed }

extension CaseStatusLabel on CaseStatus {
  String get label => switch (this) {
        CaseStatus.active => 'Active',
        CaseStatus.hearing => CountryCatalog.terms.hearingStatusLabel,
        CaseStatus.discovery => 'Discovery',
        CaseStatus.closed => 'Closed',
      };

  /// The backend's status identifier.
  String get apiValue => switch (this) {
        CaseStatus.active => 'active',
        CaseStatus.hearing => 'hearing',
        CaseStatus.discovery => 'discovery',
        CaseStatus.closed => 'closed',
      };

  Color get badgeColor => switch (this) {
        CaseStatus.active => const Color(0xFF2A2A2A),
        CaseStatus.hearing => const Color(0xFF555555),
        CaseStatus.discovery => const Color(0xFF333333),
        CaseStatus.closed => const Color(0xFF999999),
      };
}

enum CasePriority { high, medium, low }

extension CasePriorityLabel on CasePriority {
  String get label => switch (this) {
        CasePriority.high => 'High',
        CasePriority.medium => 'Medium',
        CasePriority.low => 'Low',
      };

  String get apiValue => switch (this) {
        CasePriority.high => 'high',
        CasePriority.medium => 'medium',
        CasePriority.low => 'low',
      };

  Color get badgeColor => switch (this) {
        CasePriority.high => const Color(0xFF1A1A1A),
        CasePriority.medium => const Color(0xFF555555),
        CasePriority.low => const Color(0xFF999999),
      };
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 'YYYY-MM-DD' (or full ISO timestamp) → 'Mar 4, 2026'. Falls back to the
/// raw string when it isn't a date.
String formatCaseDay(String value) {
  final day = DateTime.tryParse(value);
  if (day == null) return value;
  return '${_months[day.month - 1]} ${day.day}, ${day.year}';
}

/// A file attached to the case, from the backend's /cases response.
class CaseDocumentInfo {
  const CaseDocumentInfo({
    required this.id,
    required this.name,
    required this.sizeLabel,
    required this.dateLabel,
    this.url = '',
    this.fromClient = false,
  });

  factory CaseDocumentInfo.fromApi(Map<String, dynamic> json) {
    final size = (json['sizeBytes'] as num?)?.toDouble() ?? 0;
    final sizeLabel = size <= 0
        ? ''
        : size < 1024 * 1024
            ? '${(size / 1024).toStringAsFixed(0)} KB'
            : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return CaseDocumentInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Document',
      sizeLabel: sizeLabel,
      dateLabel: formatCaseDay(json['uploadedAt'] as String? ?? ''),
      url: json['url'] as String? ?? '',
      fromClient: json['uploadedBy'] == 'client',
    );
  }

  final String id;
  final String name;
  final String sizeLabel;
  final String dateLabel;

  /// Data URL (local dev) or S3 URL of the file content, for download.
  final String url;

  /// True when the client uploaded this file against a document request.
  final bool fromClient;
}

/// One entry on the case timeline, from the backend's /cases response.
class CaseTimelineEvent {
  const CaseTimelineEvent({
    required this.title,
    required this.date,
    required this.fromCourtApi,
    this.description,
  });

  factory CaseTimelineEvent.fromApi(Map<String, dynamic> json) {
    return CaseTimelineEvent(
      title: json['title'] as String? ?? '',
      date: formatCaseDay(json['date'] as String? ?? ''),
      description: json['description'] as String?,
      fromCourtApi: json['source'] == 'court_api',
    );
  }

  final String title;
  final String date;
  final String? description;

  /// True when the update came from a court-records lookup rather than the
  /// attorney.
  final bool fromCourtApi;
}

/// The court docket a case is linked to, from the backend's `courtRecord`.
class CourtRecordInfo {
  const CourtRecordInfo({
    required this.docketId,
    required this.url,
    this.courtName,
    this.judge,
    this.dateFiled,
    this.dateTerminated,
    this.natureOfSuit,
    this.cause,
    this.jurisdictionType,
    this.parties = const [],
    this.lastSyncedAt,
    this.lastSyncError,
  });

  factory CourtRecordInfo.fromApi(Map<String, dynamic> json) {
    return CourtRecordInfo(
      docketId: (json['docketId'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
      courtName: json['courtName'] as String?,
      judge: json['judge'] as String?,
      dateFiled: json['dateFiled'] as String?,
      dateTerminated: json['dateTerminated'] as String?,
      natureOfSuit: json['natureOfSuit'] as String?,
      cause: json['cause'] as String?,
      jurisdictionType: json['jurisdictionType'] as String?,
      parties: (json['parties'] as List<dynamic>? ?? const [])
          .map((p) => p.toString())
          .toList(),
      lastSyncedAt: json['lastSyncedAt'] as String?,
      lastSyncError: json['lastSyncError'] as String?,
    );
  }

  final int docketId;

  /// Public docket page on CourtListener.
  final String url;
  final String? courtName;
  final String? judge;
  final String? dateFiled;

  /// Set once the court closed the docket.
  final String? dateTerminated;

  /// PACER nature of suit, e.g. '410 Anti-Trust'.
  final String? natureOfSuit;

  /// Statutory cause of action, e.g. '15:1 Antitrust Litigation'.
  final String? cause;
  final String? jurisdictionType;

  /// Named parties as the court lists them.
  final List<String> parties;
  final String? lastSyncedAt;
  final String? lastSyncError;
}

class AdvocateCase {
  const AdvocateCase({
    required this.id,
    this.clientId = '',
    this.advocateId = '',
    required this.number,
    required this.title,
    required this.client,
    required this.advocateName,
    required this.status,
    required this.filed,
    this.nextHearing,
    this.nextHearingIso,
    this.priority,
    required this.practiceArea,
    required this.court,
    this.timeline = const [],
    this.documents = const [],
    this.courtRecord,
  });

  /// Builds a card model from the backend's /cases response.
  factory AdvocateCase.fromApi(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'hearing' => CaseStatus.hearing,
      'discovery' => CaseStatus.discovery,
      'closed' => CaseStatus.closed,
      _ => CaseStatus.active,
    };
    final priority = switch (json['priority'] as String?) {
      'high' => CasePriority.high,
      'medium' => CasePriority.medium,
      'low' => CasePriority.low,
      _ => null,
    };
    final filed =
        json['filedDate'] as String? ?? json['createdAt'] as String? ?? '';
    final hearing = json['nextHearing'] as String?;
    final area = (json['practiceArea'] as String?)?.trim() ?? '';
    final timeline = (json['timeline'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(CaseTimelineEvent.fromApi)
        .toList();
    final documents = (json['documents'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(CaseDocumentInfo.fromApi)
        .toList();
    final courtJson = json['courtRecord'];
    return AdvocateCase(
      id: json['id'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      advocateId: json['advocateId'] as String? ?? '',
      number: json['caseNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      client: json['clientName'] as String? ?? 'Client',
      advocateName: json['advocateName'] as String? ?? 'Attorney',
      status: status,
      filed: formatCaseDay(filed),
      nextHearing: hearing == null ? null : formatCaseDay(hearing),
      nextHearingIso: hearing,
      priority: priority,
      practiceArea: area.isEmpty ? 'General Practice' : area,
      court: json['court'] as String? ?? '',
      timeline: timeline,
      documents: documents,
      courtRecord: courtJson is Map<String, dynamic>
          ? CourtRecordInfo.fromApi(courtJson)
          : null,
    );
  }

  final String id;

  /// Backend user ids of both parties, for opening the chat.
  final String clientId;
  final String advocateId;
  final String number;
  final String title;
  final String client;

  /// Shown instead of the client name on the client's own case view.
  final String advocateName;
  final CaseStatus status;
  final String filed;

  /// Null for closed cases with no upcoming hearing.
  final String? nextHearing;

  /// The same date as [nextHearing] but raw 'YYYY-MM-DD', for sorting.
  final String? nextHearingIso;

  /// Null for closed cases.
  final CasePriority? priority;
  final String practiceArea;
  final String court;

  /// Timeline of court-API and attorney updates, oldest first.
  final List<CaseTimelineEvent> timeline;

  /// Files the attorney attached to the case.
  final List<CaseDocumentInfo> documents;

  /// Court docket this case syncs from; null for manually entered cases.
  final CourtRecordInfo? courtRecord;
}

class AdvocateCasesScreen extends StatefulWidget {
  const AdvocateCasesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AdvocateCasesScreen> createState() => _AdvocateCasesScreenState();
}

class _AdvocateCasesScreenState extends State<AdvocateCasesScreen> with RealtimeRefresh {
  CaseStatus? _filter;
  List<AdvocateCase> _cases = [];
  bool _loading = true;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    listenRealtime({'cases'}, (_) {
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchCases();
      if (!mounted) return;
      setState(() {
        _cases = result.map(AdvocateCase.fromApi).toList();
        _loadError = '';
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

  Future<void> _openAddCase() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCaseScreen()),
    );
    if (created == true) await _load();
  }

  List<AdvocateCase> get _filtered => _filter == null
      ? _cases
      : _cases.where((c) => c.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterChips(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      if (_loadError.isNotEmpty)
                        _buildEmptyState(
                          title: 'Couldn\'t load cases',
                          message: _loadError,
                        )
                      else if (_filtered.isEmpty)
                        _buildEmptyState(
                          title: 'No cases yet',
                          message:
                              'Tap + to open a case for one of your clients.',
                        )
                      else
                        for (int i = 0; i < _filtered.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _CaseCard(
                            caseData: _filtered[i],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CaseDetailsScreen(
                                    caseData: _filtered[i],
                                  ),
                                ),
                              );
                              await _load();
                            },
                          ),
                        ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
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
                'assets/icons/ic_briefcase.svg',
                width: 24,
                height: 24,
              ),
            ),
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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HeaderButton(
            icon: 'assets/icons/ic_arrow_back.svg',
            onTap: widget.onBack,
          ),
          const Text(
            'My Cases',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 22.5 / 15,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          _HeaderButton(
            icon: 'assets/icons/ic_plus.svg',
            onTap: _openAddCase,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <(CaseStatus?, String)>[
      (null, 'All'),
      for (final status in CaseStatus.values) (status, status.label),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (final (status, label) in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: label,
                selected: _filter == status,
                onTap: () => setState(() => _filter = status),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onTap});

  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Center(
            child: SvgPicture.asset(icon, width: 16, height: 16),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
            ),
          ),
          child: Text(
            label,
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
  }
}

class CaseBadge extends StatelessWidget {
  const CaseBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.5,
          letterSpacing: 0.12,
          color: color,
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.caseData, required this.onTap});

  final AdvocateCase caseData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CaseCard(caseData: caseData, onTap: onTap);
  }
}

/// Case summary card, shared with the client's My Cases screen.
class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.caseData,
    required this.onTap,
    this.showClient = true,
  });

  final AdvocateCase caseData;
  final VoidCallback onTap;

  /// True on the attorney side (shows the client), false on the client side
  /// (shows the attorney).
  final bool showClient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caseData.number.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: 1.16,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caseData.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          showClient
                              ? 'Client: ${caseData.client}'
                              : 'Attorney: ${caseData.advocateName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 16 / 12,
                            color: AppColors.textGrey555,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CaseBadge(
                    label: caseData.status.label,
                    color: caseData.status.badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: SvgPicture.asset(
                      'assets/icons/ic_chevron_right_grey.svg',
                      width: 14,
                      height: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 13),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_calendar_dark.svg',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Filed ${caseData.filed}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: 0.06,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ),
                    if (caseData.nextHearing != null) ...[
                      const SizedBox(width: 12),
                      SvgPicture.asset(
                        'assets/icons/ic_clock.svg',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Next: ${caseData.nextHearing}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            letterSpacing: 0.06,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                    if (caseData.priority != null) ...[
                      const SizedBox(width: 8),
                      const Spacer(),
                      CaseBadge(
                        label: '${caseData.priority!.label} Priority',
                        color: caseData.priority!.badgeColor,
                      ),
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
}
