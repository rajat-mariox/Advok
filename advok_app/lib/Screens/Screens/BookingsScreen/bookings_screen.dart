import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';

class _Booking {
  const _Booking({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.statusColor,
    required this.dateTime,
    required this.price,
    required this.photoBytes,
    required this.past,
    required this.canCancel,
    this.canJoinCall = false,
  });

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

  /// Builds a card model from the backend's /bookings response.
  factory _Booking.fromApi(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'pending';
    final kind = json['consultationType'] as String? ?? 'video_call';
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final time = json['time'] as String? ?? '';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;

    final today = DateTime.now();
    final dateIsPast = date != null &&
        date.isBefore(DateTime(today.year, today.month, today.day));
    final upcoming =
        (status == 'pending' || status == 'confirmed') && !dateIsPast;

    final (label, color) = switch (status) {
      'pending' => ('Pending', const Color(0xFFB07A00)),
      'confirmed' => ('Confirmed', const Color(0xFF1E7A46)),
      'declined' => ('Declined', const Color(0xFF9A3B3B)),
      'cancelled' => ('Cancelled', AppColors.textGrey555),
      _ => (status, AppColors.textGrey555),
    };

    return _Booking(
      id: json['id'] as String? ?? '',
      name: json['advocateName'] as String? ?? 'Advocate',
      type: switch (kind) {
        'office_visit' => 'Office Visit · In-person',
        'phone_call' => 'Phone Call',
        _ => 'Video Call',
      },
      status: label,
      statusColor: color,
      dateTime: date == null
          ? time
          : '${_months[date.month - 1]} ${date.day} · $time',
      price: '\$${amount.toStringAsFixed(2)}',
      photoBytes: decodePhotoDataUrl(json['advocatePhoto'] as String?),
      past: !upcoming,
      canCancel: upcoming,
      canJoinCall: false,
    );
  }

  final String id;
  final String name;
  final String type;
  final String status;
  final Color statusColor;
  final String dateTime;
  final String price;
  final Uint8List? photoBytes;
  final bool canJoinCall;

  /// Declined/cancelled or already-passed bookings live in the Past tab.
  final bool past;

  /// Upcoming pending/confirmed bookings can still be cancelled.
  final bool canCancel;
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, this.onBack});

  /// Overrides the default back behaviour; used when embedded as a tab.
  final VoidCallback? onBack;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0;

  List<_Booking> _bookings = [];
  bool _loading = true;
  String _loadError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.fetchBookings();
      if (!mounted) return;
      setState(() {
        _bookings = result.map(_Booking.fromApi).toList();
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

  Future<void> _cancel(_Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Cancel booking?'),
        content: Text(
          'Your ${booking.type.split(' · ').first.toLowerCase()} with '
          '${booking.name} on ${booking.dateTime} will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.cancelBooking(booking.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = [
      for (final b in _bookings)
        if (b.past == (_selectedTab == 1)) b,
    ];
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleBackButton(onTap: widget.onBack),
              const Text(
                'My Bookings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  letterSpacing: -0.23,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _buildTab('Upcoming', 0)),
              const SizedBox(width: 4),
              Expanded(child: _buildTab('Past', 1)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: bookings.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [_buildEmptyState()],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: bookings.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _BookingCard(
                            booking: bookings[index],
                            onCancel: () => _cancel(bookings[index]),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
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
                'assets/icons/ic_qa_book.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _selectedTab == 0 ? 'No upcoming bookings' : 'No past bookings',
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
                : '${CountryCatalog.terms.lawyerPlural} you book will appear '
                    'here.',
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
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onCancel});

  final _Booking booking;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: booking.photoBytes != null
                      ? Image.memory(
                          booking.photoBytes!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : InitialsAvatar(name: booking.name, size: 48),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: -0.08,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.type,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.textGrey555,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: booking.statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      letterSpacing: 0.12,
                      color: booking.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_qa_book.svg',
                      width: 13,
                      height: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.dateTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
                Text(
                  booking.price,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (booking.canCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      label: 'Message',
                      background: AppColors.progressTrack,
                      borderColor: AppColors.borderGrey,
                      textColor: AppColors.textPrimary,
                      onTap: () {
                        // TODO: Open the conversation with this advocate.
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionPill(
                      label: 'Cancel',
                      background:
                          const Color(0xFF1A1A1A).withValues(alpha: 0.09),
                      borderColor:
                          const Color(0xFF1A1A1A).withValues(alpha: 0.19),
                      textColor: const Color(0xFF1A1A1A),
                      onTap: onCancel,
                    ),
                  ),
                  if (booking.canJoinCall) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionPill(
                        label: 'Join Call',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.textPrimary,
                            AppColors.gradientDarkEnd,
                          ],
                        ),
                        textColor: AppColors.white,
                        bold: true,
                        onTap: () {
                          // TODO: Join the video call.
                        },
                      ),
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

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.textColor,
    required this.onTap,
    this.background,
    this.borderColor,
    this.gradient,
    this.bold = false,
  });

  final String label;
  final Color textColor;
  final VoidCallback onTap;
  final Color? background;
  final Color? borderColor;
  final Gradient? gradient;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 33,
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              height: 16 / 12,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
