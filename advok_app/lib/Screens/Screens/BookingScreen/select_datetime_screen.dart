import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';
import 'booking_summary_screen.dart';
import 'consultation_type_screen.dart';

class _DateOption {
  const _DateOption(this.date, {required this.available});

  final DateTime date;
  final bool available;

  static const List<String> dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _fullDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get day => dayLabels[date.weekday - 1];

  String get dayNumber => '${date.day}';

  String get fullLabel => '${_fullDayNames[date.weekday - 1]}, '
      '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

class SelectDateTimeScreen extends StatefulWidget {
  const SelectDateTimeScreen({
    super.key,
    required this.advocate,
    required this.consultationType,
  });

  final Advocate advocate;
  final ConsultationType consultationType;

  @override
  State<SelectDateTimeScreen> createState() => _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends State<SelectDateTimeScreen> {
  late final List<_DateOption> _dates = _buildDates();
  late final List<String> _slots = _buildSlots();
  late int _selectedDate =
      _dates.indexWhere((d) => d.available).clamp(0, 1 << 30);
  int? _selectedSlot;

  /// The next two weeks, marking the advocate's working days as bookable.
  /// Empty when the advocate has no schedule, which shows the empty state.
  List<_DateOption> _buildDates() {
    final working = widget.advocate.workingDays.toSet();
    if (working.isEmpty) return const [];
    final today = DateTime.now();
    return [
      for (int i = 1; i <= 14; i++)
        _DateOption(
          DateTime(today.year, today.month, today.day + i),
          available: working
              .contains(_DateOption.dayLabels[(today.weekday - 1 + i) % 7]),
        ),
    ];
  }

  /// Hourly slots between the advocate's office hours ('HH:mm' 24h strings),
  /// e.g. 09:00–18:00 becomes 9:00 AM … 5:00 PM.
  List<String> _buildSlots() {
    final start = _parseMinutes(widget.advocate.startTime);
    final end = _parseMinutes(widget.advocate.endTime);
    if (start == null || end == null || start >= end) return const [];
    return [
      for (int m = start; m + 60 <= end; m += 60) _formatSlot(m),
    ];
  }

  static int? _parseMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final min = int.tryParse(parts[1]);
    if (h == null || min == null) return null;
    return h * 60 + min;
  }

  static String _formatSlot(int minutes) {
    final h24 = minutes ~/ 60;
    final min = minutes % 60;
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:${min.toString().padLeft(2, '0')} $period';
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < 2
                                ? AppColors.textPrimary
                                : AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'Step 2 of 3',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 28 / 20,
                        letterSpacing: -0.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateChips(),
                    const SizedBox(height: 20),
                    const Text(
                      'Available Slots',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: -0.23,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSlotGrid(),
                    const SizedBox(height: 20),
                    _buildContinueButton(),
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
        children: const [
          CircleBackButton(),
          Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
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
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChips() {
    if (_dates.isEmpty) {
      return _buildEmptyState(
        'No dates available',
        'Available dates will appear here once the advocate sets their schedule.',
      );
    }
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = index == _selectedDate;
          return Opacity(
            opacity: date.available ? 1 : 0.35,
            child: GestureDetector(
              onTap: date.available
                  ? () => setState(() {
                        _selectedDate = index;
                        _selectedSlot = null;
                      })
                  : null,
              child: Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.textPrimary
                      : date.available
                          ? AppColors.fillGrey
                          : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                  border: selected
                      ? null
                      : Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.12,
                        color:
                            selected ? AppColors.white : AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.dayNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                        letterSpacing: -0.31,
                        color: selected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: !date.available
                            ? Colors.transparent
                            : selected
                                ? AppColors.white.withValues(alpha: 0.4)
                                : const Color(0xFF2A2A2A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid() {
    if (_slots.isEmpty) {
      return _buildEmptyState(
        'No slots available',
        'Available time slots will appear here.',
      );
    }
    final rows = (_slots.length + 2) ~/ 3;
    return Column(
      children: [
        for (int row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (int col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 8),
                Expanded(
                  child: row * 3 + col < _slots.length
                      ? _buildSlot(row * 3 + col)
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSlot(int index) {
    final selected = index == _selectedSlot;
    return GestureDetector(
      onTap: () => setState(() => _selectedSlot = index),
      child: Container(
        height: 47,
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.fillGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.borderGrey,
            width: 1.4,
          ),
        ),
        child: Center(
          child: Text(
            _slots[index],
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

  Widget _buildContinueButton() {
    final enabled = _selectedSlot != null &&
        _selectedDate < _dates.length &&
        _dates[_selectedDate].available &&
        _selectedSlot! < _slots.length;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
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
              onTap: enabled
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingSummaryScreen(
                            advocate: widget.advocate,
                            consultationType: widget.consultationType,
                            date: _dates[_selectedDate].date,
                            dateLabel: _dates[_selectedDate].fullLabel,
                            timeLabel: _slots[_selectedSlot!],
                          ),
                        ),
                      );
                    }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.31,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    'assets/icons/ic_chevron_right.svg',
                    width: 18,
                    height: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
