import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/document_utils.dart';
import '../MessagesScreen/chat_screen.dart';
import 'advocate_cases_screen.dart';

/// Case workspace: details, timeline (court-API and attorney updates),
/// documents and actions. The attorney manages the case; the client views it
/// read-only ([isAttorney] false).
class CaseDetailsScreen extends StatefulWidget {
  const CaseDetailsScreen({
    super.key,
    required this.caseData,
    this.isAttorney = true,
  });

  final AdvocateCase caseData;
  final bool isAttorney;

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> with RealtimeRefresh {
  late AdvocateCase _caseData = widget.caseData;

  @override
  void initState() {
    super.initState();
    // Court-records sync, client uploads and attorney updates land here live.
    listenRealtime({'cases'}, (e) {
      final id = e.data?['caseId'];
      if (id == null || id == _caseData.id) _refresh();
    });
  }
  bool _uploadingDocument = false;
  bool _syncing = false;

  /// Attorney pulls the latest court records for a linked case.
  Future<void> _syncWithCourt() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final data = await ApiService.syncCaseWithCourt(_caseData.id);
      if (!mounted) return;
      final sync = data['sync'] as Map<String, dynamic>? ?? const {};
      setState(
        () => _caseData = AdvocateCase.fromApi(
          data['case'] as Map<String, dynamic>,
        ),
      );
      final error = sync['error'] as String?;
      final newEvents = (sync['newEvents'] as num?)?.toInt() ?? 0;
      final statusChanged = sync['statusChanged'] == true;
      final String message;
      if (error != null && error.isNotEmpty) {
        message = 'Court records sync failed: $error';
      } else if (newEvents == 0 && !statusChanged) {
        message = 'Court records are up to date.';
      } else {
        message = [
          if (newEvents > 0)
            '$newEvents new court record${newEvents == 1 ? '' : 's'} added',
          if (statusChanged) 'case closed by the court',
        ].join(' · ');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _openDocket(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the docket page.')),
      );
    }
  }

  Future<void> _refresh() async {
    try {
      final json = await ApiService.fetchCase(_caseData.id);
      if (!mounted) return;
      setState(() => _caseData = AdvocateCase.fromApi(json));
    } on ApiException {
      // Keep showing the data we already have.
    }
  }

  Future<void> _pickAndUploadDocument() async {
    if (_uploadingDocument) return;
    setState(() => _uploadingDocument = true);
    try {
      final picked = await pickCaseDocument();
      if (picked == null || !mounted) return;
      final json = await ApiService.addCaseDocument(
        _caseData.id,
        name: picked.name,
        fileDataUrl: picked.dataUrl,
      );
      if (!mounted) return;
      setState(() => _caseData = AdvocateCase.fromApi(json));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.name} added to the case.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _downloadDocument(CaseDocumentInfo doc) async {
    try {
      final bytes = await documentBytes(doc.url);
      final path = await saveDocumentToDevice(name: doc.name, bytes: bytes);
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${doc.name} saved.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _removeDocument(CaseDocumentInfo doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Remove document?'),
        content: Text('"${doc.name}" will be removed from this case.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final json = await ApiService.removeCaseDocument(_caseData.id, doc.id);
      if (!mounted) return;
      setState(() => _caseData = AdvocateCase.fromApi(json));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _openAddUpdate() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddUpdateSheet(caseData: _caseData),
    );
    if (saved == true) await _refresh();
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
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                      if (_caseData.courtRecord != null) ...[
                        const SizedBox(height: 16),
                        _buildCourtRecordCard(_caseData.courtRecord!),
                      ],
                      const SizedBox(height: 16),
                      const _SectionLabel('Case Timeline'),
                      const SizedBox(height: 12),
                      if (_caseData.timeline.isEmpty)
                        const _EmptyState(
                          icon: 'assets/icons/ic_clock.svg',
                          title: 'No timeline events yet',
                          message:
                              'Court updates and attorney notes will appear here.',
                        )
                      else
                        for (int i = 0; i < _caseData.timeline.length; i++)
                          _TimelineRow(
                            step: _caseData.timeline[i],
                            isLast: i == _caseData.timeline.length - 1,
                          ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionLabel('Documents'),
                          if (widget.isAttorney)
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _uploadingDocument
                                  ? null
                                  : _pickAndUploadDocument,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  _uploadingDocument
                                      ? 'Uploading…'
                                      : '+ Add Document',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                    letterSpacing: -0.08,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_caseData.documents.isEmpty)
                        _EmptyState(
                          icon: 'assets/icons/ic_file.svg',
                          title: 'No documents yet',
                          message: widget.isAttorney
                              ? 'Tap "+ Add Document" to attach case files '
                                  '(PDF, images, Word).'
                              : 'Files your attorney adds will appear here.',
                        )
                      else
                        for (int i = 0; i < _caseData.documents.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _DocumentRow(
                            document: _caseData.documents[i],
                            onDownload: () =>
                                _downloadDocument(_caseData.documents[i]),
                            onRemove: widget.isAttorney
                                ? () =>
                                    _removeDocument(_caseData.documents[i])
                                : null,
                          ),
                        ],
                      const SizedBox(height: 24),
                      _buildActions(context),
                    ],
                  ),
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
                'Case Details',
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

  Widget _buildSummaryCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _caseData.number.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: 1.16,
                  color: AppColors.textGrey,
                ),
              ),
              CaseBadge(
                label: _caseData.status.label,
                color: _caseData.status.badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _caseData.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 27 / 18,
              letterSpacing: -0.44,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isAttorney
                ? 'Client: ${_caseData.client}'
                : 'Attorney: ${_caseData.advocateName}',
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final judge = _caseData.courtRecord?.judge;
    final rows = <(String, String)>[
      ('Date Filed', _caseData.filed),
      if (_caseData.nextHearing != null)
        ('Next Court Event', _caseData.nextHearing!),
      if (_caseData.priority != null) ('Priority', _caseData.priority!.label),
      ('Practice Area', _caseData.practiceArea),
      ('Court', _caseData.court),
      if (judge != null && judge.isNotEmpty) ('Judge', judge),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 19.5 / 13,
                        letterSpacing: -0.08,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Court-records link: where the status and timeline sync from, when it
  /// last ran, and (for the attorney) a way to pull updates right now.
  Widget _buildCourtRecordCard(CourtRecordInfo record) {
    final synced = record.lastSyncedAt == null
        ? 'Not synced yet'
        : 'Last synced ${_formatSyncTime(record.lastSyncedAt!)}';
    final error = record.lastSyncError;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Court Records',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (record.dateTerminated != null)
                const CaseBadge(
                  label: 'Terminated',
                  color: Color(0xFF555555),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              'CourtListener · PACER docket #${record.docketId}',
              if (record.courtName != null && record.courtName!.isNotEmpty)
                record.courtName!,
              if (record.dateTerminated != null)
                'Closed by the court on '
                    '${formatCaseDay(record.dateTerminated!)}',
            ].join('\n'),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textGrey555,
            ),
          ),
          for (final row in _courtRows(record)) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    row.$1,
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
                    row.$2,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      letterSpacing: -0.08,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            error != null && error.isNotEmpty
                ? '$synced · last attempt failed: $error'
                : synced,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: error != null && error.isNotEmpty
                  ? const Color(0xFFB3261E)
                  : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      record.url.isEmpty ? null : () => _openDocket(record.url),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderGrey),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text(
                    'View Docket',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (widget.isAttorney) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _syncing ? null : _syncWithCourt,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.textPrimary,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _syncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.sync, size: 14),
                    label: Text(
                      _syncing ? 'Syncing…' : 'Sync Now',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Docket header fields worth a row of their own on the court card.
  List<(String, String)> _courtRows(CourtRecordInfo record) {
    return [
      if (record.natureOfSuit != null) ('Nature of suit', record.natureOfSuit!),
      if (record.cause != null) ('Cause', record.cause!),
      if (record.jurisdictionType != null)
        ('Jurisdiction', record.jurisdictionType!),
      if (record.parties.isNotEmpty)
        (
          'Parties',
          record.parties.length > 6
              ? '${record.parties.take(6).join(', ')} '
                  '+${record.parties.length - 6} more'
              : record.parties.join(', '),
        ),
    ];
  }

  /// 'Sep 11, 2026 at 11:02' in the device's local time.
  String _formatSyncTime(String iso) {
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return iso;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${formatCaseDay(parsed.toIso8601String())} at $hh:$mm';
  }

  Widget _buildActions(BuildContext context) {
    final chatName =
        widget.isAttorney ? _caseData.client : _caseData.advocateName;
    final messageButton = Material(
      color: AppColors.progressTrack,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final peerId =
              widget.isAttorney ? _caseData.clientId : _caseData.advocateId;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                name: chatName,
                peerId: peerId.isEmpty ? null : peerId,
                online: true,
                specialty: _caseData.title,
                caseId: _caseData.id,
                caseNumber: _caseData.number,
              ),
            ),
          );
        },
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_chat_bubble.svg',
                width: 15,
                height: 15,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isAttorney ? 'Message Client' : 'Message Attorney',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.isAttorney) {
      return messageButton;
    }

    return Row(
      children: [
        Expanded(child: messageButton),
        const SizedBox(width: 12),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openAddUpdate,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_plus.svg',
                        width: 15,
                        height: 15,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Update',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 20 / 14,
                          letterSpacing: -0.15,
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
      ],
    );
  }
}

/// Bottom sheet where the attorney posts a case update: a timeline note
/// and/or a status, priority or next-court-event change.
class _AddUpdateSheet extends StatefulWidget {
  const _AddUpdateSheet({required this.caseData});

  final AdvocateCase caseData;

  @override
  State<_AddUpdateSheet> createState() => _AddUpdateSheetState();
}

class _AddUpdateSheetState extends State<_AddUpdateSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late CaseStatus _status = widget.caseData.status;
  DateTime? _nextHearing;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty ||
      _status != widget.caseData.status ||
      _nextHearing != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      await ApiService.addCaseUpdate(
        widget.caseData.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status:
            _status == widget.caseData.status ? null : _status.apiValue,
        nextHearing: _nextHearing == null
            ? null
            : '${_nextHearing!.year}-'
                '${_nextHearing!.month.toString().padLeft(2, '0')}-'
                '${_nextHearing!.day.toString().padLeft(2, '0')}',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Case Update',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The client sees this on their case timeline.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: _titleController,
            hint: 'Update title (e.g. Motion filed)',
          ),
          const SizedBox(height: 10),
          _buildInput(
            controller: _descriptionController,
            hint: 'Details (optional)',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in CaseStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: _status == status,
                  selectedColor: AppColors.textPrimary,
                  backgroundColor: AppColors.fillGrey,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _status == status
                        ? AppColors.white
                        : AppColors.textGrey555,
                  ),
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) setState(() => _nextHearing = picked);
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_calendar_dark.svg',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _nextHearing == null
                          ? 'Set next court event (optional)'
                          : 'Next court event: ${_nextHearing!.month}/'
                              '${_nextHearing!.day}/${_nextHearing!.year}',
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: -0.08,
                        color: _nextHearing == null
                            ? AppColors.textGrey
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _canSave && !_saving
                      ? [AppColors.textPrimary, AppColors.gradientDarkEnd]
                      : [AppColors.progressTrack, AppColors.progressTrack],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _canSave && !_saving ? _save : null,
                  child: SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        _saving ? 'Saving…' : 'Post Update',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          color: _canSave && !_saving
                              ? AppColors.white
                              : AppColors.textGrey,
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
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 13.5,
          letterSpacing: -0.08,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            letterSpacing: -0.08,
            color: AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: -0.15,
        color: AppColors.textPrimary,
      ),
    );
  }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          SvgPicture.asset(icon, width: 20, height: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.08,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final CaseTimelineEvent step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimary,
                  border: Border.all(color: AppColors.borderGrey),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 19.5 / 13,
                            letterSpacing: -0.08,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (step.fromCourtApi)
                        const CaseBadge(
                          label: 'Court Record',
                          color: Color(0xFF555555),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.date,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                  if (step.description != null &&
                      step.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 18 / 12.5,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    this.onDownload,
    this.onRemove,
  });

  final CaseDocumentInfo document;

  /// Tapping the row (or the download icon) saves the file to the device.
  final VoidCallback? onDownload;

  /// Attorney-only; null hides the remove action (client view).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (document.sizeLabel.isNotEmpty) document.sizeLabel,
      if (document.dateLabel.isNotEmpty) 'Added ${document.dateLabel}',
      if (document.fromClient) 'From client',
    ].join(' · ');
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onDownload,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              SvgPicture.asset('assets/icons/ic_file.svg',
                  width: 16, height: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.08,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDownload != null)
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.download_outlined,
                    size: 16,
                    color: AppColors.textGrey,
                  ),
                ),
              if (onRemove != null)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textGrey,
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
