import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Services/realtime_service.dart';
import '../../../Utils/AppColors/app_colors.dart';

const _categories = <(String, String)>[
  ('account', 'Account'),
  ('booking', 'Booking'),
  ('payment', 'Payment'),
  ('case', 'Case'),
  ('technical', 'Technical'),
  ('other', 'Other'),
];

String _categoryLabel(String? key) =>
    _categories.where((c) => c.$1 == key).map((c) => c.$2).firstOrNull ??
    'Other';

String _statusLabel(String? status) => switch (status) {
      'in_progress' => 'In Progress',
      'resolved' => 'Resolved',
      _ => 'Open',
    };

Color _statusColor(String? status) => switch (status) {
      'in_progress' => const Color(0xFF555555),
      'resolved' => const Color(0xFF999999),
      _ => const Color(0xFF2A2A2A),
    };

String _ago(String? iso) {
  final at = DateTime.tryParse(iso ?? '')?.toLocal();
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[at.month - 1]} ${at.day}, ${at.year}';
}

/// The user's support tickets, with a button to raise a new one.
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> with RealtimeRefresh {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    listenRealtime({'support'}, (_) {
      _load();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchSupportTickets();
      if (!mounted) return;
      setState(() {
        _tickets = result.tickets;
        _error = '';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _newTicket() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewTicketSheet(),
    );
    if (created == true) await _load();
  }

  Future<void> _open(Map<String, dynamic> ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportTicketDetailScreen(ticketId: ticket['id'] as String),
      ),
    );
    await _load();
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
              _SheetHeader(title: 'Contact Support', onClose: () => Navigator.of(context).pop()),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          children: [
                            _buildNewTicketCard(),
                            const SizedBox(height: 20),
                            const Text(
                              'My Tickets',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                                letterSpacing: -0.15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_error.isNotEmpty)
                              _EmptyCard(
                                title: "Couldn't load tickets",
                                message: _error,
                              )
                            else if (_tickets.isEmpty)
                              const _EmptyCard(
                                title: 'No tickets yet',
                                message:
                                    'Raise a ticket and our team will reply '
                                    'here. You\'ll get a notification when '
                                    'they do.',
                              )
                            else
                              for (int i = 0; i < _tickets.length; i++) ...[
                                if (i > 0) const SizedBox(height: 8),
                                _TicketCard(
                                  ticket: _tickets[i],
                                  onTap: () => _open(_tickets[i]),
                                ),
                              ],
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

  Widget _buildNewTicketCard() {
    return DecoratedBox(
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
          onTap: _newTicket,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_plus.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raise a new ticket',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: -0.15,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Tell us what went wrong and we\'ll reply in-app.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: Color(0xFFD9D3D3),
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
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});

  final Map<String, dynamic> ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = (ticket['userUnread'] as num?)?.toInt() ?? 0;
    final replies = (ticket['replies'] as List<dynamic>? ?? []);
    final last = replies.isEmpty
        ? ticket['message'] as String? ?? ''
        : (replies.last as Map<String, dynamic>)['text'] as String? ?? '';
    final lastFromAdmin = replies.isNotEmpty &&
        ((replies.last as Map<String, dynamic>)['fromAdmin'] == true);
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket['subject'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
                        height: 1.5,
                        letterSpacing: -0.08,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(status: ticket['status'] as String?),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${lastFromAdmin ? 'Support: ' : ''}$last',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 18 / 12.5,
                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                  color: unread > 0 ? AppColors.textPrimary : AppColors.textGrey555,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${_categoryLabel(ticket['category'] as String?)} · '
                    '${_ago(ticket['updatedAt'] as String?)}',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const Spacer(),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$unread new',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: AppColors.white,
                        ),
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
}

/// Bottom sheet where the user describes their issue.
class _NewTicketSheet extends StatefulWidget {
  const _NewTicketSheet();

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  String _category = 'account';
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty) {
      setState(() => _error = 'Add a short subject.');
      return;
    }
    if (message.length < 10) {
      setState(() => _error = 'Describe the issue in a little more detail.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = '';
    });
    try {
      await ApiService.createSupportTicket(
        category: _category,
        subject: subject,
        message: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket raised — our team will reply in-app.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'New Support Ticket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 24 / 16,
                letterSpacing: -0.31,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _label('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (key, label) in _categories)
                  _Chip(
                    label: label,
                    selected: _category == key,
                    onTap: () => setState(() => _category = key),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _label('Subject'),
            const SizedBox(height: 6),
            _input(
              controller: _subject,
              hint: 'e.g. Cannot cancel my booking',
              maxLength: 120,
            ),
            const SizedBox(height: 14),
            _label('What happened?'),
            const SizedBox(height: 6),
            _input(
              controller: _message,
              hint: 'Describe the issue and what you expected to happen.',
              minLines: 4,
              maxLines: 8,
              maxLength: 4000,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _error,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _PrimaryButton(
              label: _submitting ? 'Sending…' : 'Submit Ticket',
              onTap: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.5,
          color: AppColors.textGrey555,
        ),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontSize: 13.5,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: AppColors.fillGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// One ticket: the original message, the reply thread and a reply box.
class SupportTicketDetailScreen extends StatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> with RealtimeRefresh {
  Map<String, dynamic>? _ticket;
  String _error = '';
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    listenRealtime({'support'}, (_) {
      _load();
    });
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ticket = await ApiService.fetchSupportTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _error = '';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final ticket = await ApiService.replySupportTicket(widget.ticketId, text);
      if (!mounted) return;
      _reply.clear();
      setState(() {
        _ticket = ticket;
        _sending = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _ticket;
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
              _SheetHeader(title: 'Ticket', onClose: () => Navigator.of(context).pop()),
              Expanded(
                child: t == null
                    ? Center(
                        child: _error.isEmpty
                            ? const CircularProgressIndicator()
                            : Padding(
                                padding: const EdgeInsets.all(32),
                                child: _EmptyCard(
                                  title: "Couldn't load ticket",
                                  message: _error,
                                ),
                              ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t['subject'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      height: 24 / 16,
                                      letterSpacing: -0.31,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusPill(status: t['status'] as String?),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_categoryLabel(t['category'] as String?)} · '
                              'Raised ${_ago(t['createdAt'] as String?)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.5,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _Bubble(
                              text: t['message'] as String? ?? '',
                              fromAdmin: false,
                              when: t['createdAt'] as String?,
                            ),
                            for (final r in (t['replies'] as List<dynamic>? ?? [])
                                .cast<Map<String, dynamic>>()) ...[
                              const SizedBox(height: 8),
                              _Bubble(
                                text: r['text'] as String? ?? '',
                                fromAdmin: r['fromAdmin'] == true,
                                when: r['createdAt'] as String?,
                              ),
                            ],
                            if (t['status'] == 'resolved') ...[
                              const SizedBox(height: 14),
                              const _EmptyCard(
                                title: 'This ticket is resolved',
                                message:
                                    'Reply below if the issue is not fixed and '
                                    'it will be reopened.',
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
              if (t != null) _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderGrey)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _reply,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Write a reply…',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: AppColors.fillGrey,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.textPrimary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sending ? null : _send,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/icons/ic_send.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            AppColors.white,
                            BlendMode.srcIn,
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
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.fromAdmin, this.when});

  final String text;
  final bool fromAdmin;
  final String? when;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fromAdmin ? AppColors.white : AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fromAdmin ? AppColors.textPrimary : AppColors.borderGrey,
          width: fromAdmin ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fromAdmin ? 'ADVOK Support' : 'You'} · ${_ago(when)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 20 / 13.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.5,
          color: color,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              color: selected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

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
          SvgPicture.asset('assets/icons/ic_help.svg', width: 20, height: 20),
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderGrey)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 24 / 16,
              letterSpacing: -0.31,
              color: AppColors.textPrimary,
            ),
          ),
          Material(
            color: AppColors.progressTrack,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_clear.svg',
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
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
}
