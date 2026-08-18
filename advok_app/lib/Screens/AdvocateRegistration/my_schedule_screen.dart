import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Services/api_service.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'advocate_verification_submitted_screen.dart';

const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  final Set<int> _workingDays = {0, 1, 2, 3, 4};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  final List<String> _hearings = [];
  final List<String> _tasks = [];
  final TextEditingController _hearingController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  bool _showHearingInput = false;
  bool _showTaskInput = false;
  bool _submitting = false;

  Future<void> _finishSetup() async {
    AdvocateOnboardingData.current
      ..workingDays = _workingDays.map((i) => _dayLabels[i]).toList()
      ..startTime = _format(_startTime)
      ..endTime = _format(_endTime);
    setState(() => _submitting = true);
    try {
      await ApiService.submitAdvocateOnboarding(
        AdvocateOnboardingData.current.toPayload(),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AdvocateVerificationSubmittedScreen(),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _hearingController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 5,
      continueEnabled: _workingDays.isNotEmpty && !_submitting,
      continueLabel: _submitting ? 'Submitting…' : 'Finish Setup',
      continueSubLabel: 'Submit for verification',
      onContinue: _finishSetup,
      children: [
        const Text(
          'STEP 5 OF 5',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: 3.06,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'My Schedule',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 32.5 / 24,
            letterSpacing: -0.43,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configure your working schedule so clients can book at the right time.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Working Days'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < _dayLabels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _buildDayChip(i)),
            ],
          ],
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Available Time'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Start Time',
                value: _format(_startTime),
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeField(
                label: 'End Time',
                value: _format(_endTime),
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // US: "Court Events & Tasks" / "Add Court Event"; India keeps
        // "Hearings & Tasks" / "Add Hearing".
        _SectionLabel(CountryCatalog.terms.hearingSectionLabel),
        const SizedBox(height: 12),
        if (_showHearingInput)
          _AddEntryRow(
            controller: _hearingController,
            hintText: CountryCatalog.terms.hearingInputHint,
            onAdd: () {
              final text = _hearingController.text.trim();
              if (text.isEmpty) return;
              setState(() {
                _hearings.add(text);
                _hearingController.clear();
              });
            },
          )
        else
          _DashedButton(
            icon: 'assets/icons/ic_plus.svg',
            label: CountryCatalog.terms.addHearingLabel,
            labelColor: AppColors.textPrimary,
            onTap: () => setState(() => _showHearingInput = true),
          ),
        const SizedBox(height: 8),
        if (_showTaskInput)
          _AddEntryRow(
            controller: _taskController,
            hintText: 'Task description…',
            onAdd: () {
              final text = _taskController.text.trim();
              if (text.isEmpty) return;
              setState(() {
                _tasks.add(text);
                _taskController.clear();
              });
            },
          )
        else
          _DashedButton(
            icon: 'assets/icons/ic_plus.svg',
            label: 'Add Task',
            labelColor: AppColors.textPrimary,
            onTap: () => setState(() => _showTaskInput = true),
          ),
        const SizedBox(height: 8),
        _DashedButton(
          icon: 'assets/icons/ic_lock.svg',
          label: 'Block Time Slot',
          labelColor: AppColors.textGrey555,
          onTap: () {
            // TODO: Open the block-time-slot flow once designed.
          },
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildDayChip(int index) {
    final selected = _workingDays.contains(index);
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            if (selected) {
              _workingDays.remove(index);
            } else {
              _workingDays.add(index);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: 1.4,
            ),
          ),
          child: Center(
            child: Text(
              _dayLabels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.5,
                letterSpacing: 0.06,
                color: selected ? AppColors.white : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final days = [
      for (int i = 0; i < _dayLabels.length; i++)
        if (_workingDays.contains(i)) _dayLabels[i],
    ];
    return Container(
      width: double.infinity,
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
            'Schedule Summary',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final day in days)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      letterSpacing: 0.12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_format(_startTime)} – ${_format(_endTime)} · '
            '${_hearings.length} ${CountryCatalog.terms.hearingNoun}'
            '${_hearings.length == 1 ? '' : 's'} · '
            '${_tasks.length} task${_tasks.length == 1 ? '' : 's'}',
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

class _AddEntryRow extends StatelessWidget {
  const _AddEntryRow({
    required this.controller,
    required this.hintText,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.textPrimary, width: 1.4),
            ),
            child: Center(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onAdd,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
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
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 0.6,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: 0.06,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.fillGrey,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey, width: 1.4),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_clock.svg',
                    width: 15,
                    height: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.23,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: AppColors.borderGrey,
        strokeWidth: 1.4,
        radius: 16,
      ),
      child: Material(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            child: Row(
              children: [
                SvgPicture.asset(icon, width: 16, height: 16),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: labelColor,
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

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dashLength = 5;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height).deflate(
            strokeWidth / 2,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dashLength),
          paint,
        );
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius;
}
