import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';

class _Booking {
  const _Booking({
    required this.name,
    required this.type,
    required this.status,
    required this.statusColor,
    required this.dateTime,
    required this.price,
    required this.image,
    // The flags below are set by API data once bookings are live.
    // ignore: unused_element_parameter
    this.canJoinCall = false,
    // ignore: unused_element_parameter
    this.past = false,
    // ignore: unused_element_parameter
    this.hasActions = true,
  });

  final String name;
  final String type;
  final String status;
  final Color statusColor;
  final String dateTime;
  final String price;
  final String image;
  final bool canJoinCall;

  /// Past bookings show View Notes / Rebook instead of Message / Cancel.
  final bool past;

  /// Cancelled bookings show no action row at all.
  final bool hasActions;
}

const List<_Booking> _upcomingBookings = [];

const List<_Booking> _pastBookings = [];

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, this.onBack});

  /// Overrides the default back behaviour; used when embedded as a tab.
  final VoidCallback? onBack;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final bookings = _selectedTab == 0 ? _upcomingBookings : _pastBookings;
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
          child: bookings.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _BookingCard(booking: bookings[index]),
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
          const Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Advocates you book will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
  const _BookingCard({required this.booking});

  final _Booking booking;

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
                  child: Image.asset(
                    booking.image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
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
          if (booking.hasActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: booking.past
                    ? [
                        Expanded(
                          child: _ActionPill(
                            label: 'View Notes',
                            background: AppColors.progressTrack,
                            borderColor: AppColors.borderGrey,
                            textColor: AppColors.textGrey555,
                            onTap: () {
                              // TODO: Show the consultation notes.
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionPill(
                            label: 'Rebook',
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
                              // TODO: Restart the booking flow.
                            },
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          child: _ActionPill(
                            label: 'Message',
                            background: AppColors.progressTrack,
                            borderColor: AppColors.borderGrey,
                            textColor: AppColors.textPrimary,
                            onTap: () {
                              // TODO: Open the conversation with this
                              // advocate.
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionPill(
                            label: 'Cancel',
                            background: const Color(0xFF1A1A1A)
                                .withValues(alpha: 0.09),
                            borderColor: const Color(0xFF1A1A1A)
                                .withValues(alpha: 0.19),
                            textColor: const Color(0xFF1A1A1A),
                            onTap: () {
                              // TODO: Cancel this booking.
                            },
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
