import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import 'mentorship_message_screen.dart';

const List<String> _dayOptions = ['Weekdays', 'Weekends', 'Any'];
const List<String> _timeOptions = ['Morning', 'Afternoon', 'Evening'];

const List<String> _monthNames = [
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

/// Step 2 of the mentorship request flow — availability preferences.
///
/// Pops with `true` when the rest of the flow completes so step 1 can
/// propagate the result back to the mentors list.
class MentorshipAvailabilityScreen extends StatefulWidget {
  const MentorshipAvailabilityScreen({
    super.key,
    required this.mentorName,
    required this.mentorSpecialty,
    required this.mentorImage,
  });

  final String mentorName;
  final String mentorSpecialty;
  final String mentorImage;

  @override
  State<MentorshipAvailabilityScreen> createState() =>
      _MentorshipAvailabilityScreenState();
}

class _MentorshipAvailabilityScreenState
    extends State<MentorshipAvailabilityScreen> {
  DateTime? _date;
  int _day = 0;
  int _time = 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  String get _dateLabel {
    final date = _date;
    if (date == null) return '';
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressBar(currentStep: 2),
                      const SizedBox(height: 20),
                      const Text(
                        'When are you available?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 26 / 18,
                          letterSpacing: -0.39,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Preferred Date'),
                      const SizedBox(height: 8),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      const _FieldLabel('Day Preference'),
                      const SizedBox(height: 8),
                      _buildChoiceChips(
                        options: _dayOptions,
                        selected: _day,
                        onSelect: (i) => setState(() => _day = i),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Time Preference'),
                      const SizedBox(height: 8),
                      _buildChoiceChips(
                        options: _timeOptions,
                        selected: _time,
                        onSelect: (i) => setState(() => _time = i),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const CircleBackButton(),
          const Expanded(
            child: Text(
              'Request Mentorship',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 24 / 17,
                letterSpacing: -0.34,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Balances the back button so the title stays centered.
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProgressBar({required int currentStep}) {
    return Row(
      children: [
        for (int step = 1; step <= 3; step++) ...[
          if (step > 1) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: step <= currentStep
                    ? AppColors.textPrimary
                    : AppColors.progressTrack,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateField() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickDate,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textPrimary, width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _date == null ? 'Select a date…' : _dateLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.23,
                    color: _date == null
                        ? AppColors.textGrey
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/ic_calendar_dark.svg',
                width: 16,
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    required int selected,
    required ValueChanged<int> onSelect,
  }) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: selected == i ? AppColors.textPrimary : AppColors.fillGrey,
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => onSelect(i),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected == i
                          ? AppColors.textPrimary
                          : AppColors.borderGrey,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 18 / 13,
                        letterSpacing: -0.08,
                        color: selected == i
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
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
            onTap: () async {
              final sent = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => MentorshipMessageScreen(
                    mentorName: widget.mentorName,
                    mentorSpecialty: widget.mentorSpecialty,
                    mentorImage: widget.mentorImage,
                  ),
                ),
              );
              if (sent == true && mounted) {
                Navigator.of(context).pop(true);
              }
            },
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 18 / 12,
        color: AppColors.textGrey555,
      ),
    );
  }
}
