import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utils/AppColors/app_colors.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'describe_yourself_screen.dart';
import 'my_schedule_screen.dart';

const List<String> _courts = [
  'Supreme Court',
  'High Court',
  'District Court',
  'Family Court',
  'Consumer Court',
  'Tribunal',
];

class ProfessionalDetailsScreen extends StatefulWidget {
  const ProfessionalDetailsScreen({super.key, required this.advocateType});

  final AdvocateType advocateType;

  @override
  State<ProfessionalDetailsScreen> createState() =>
      _ProfessionalDetailsScreenState();
}

class _ProfessionalDetailsScreenState extends State<ProfessionalDetailsScreen> {
  // Controllers keep the text alive when the lazy ListView disposes
  // off-screen fields while the user scrolls through the form.
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _seniorNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _barNumberController = TextEditingController();
  final TextEditingController _practiceAreaController =
      TextEditingController();
  String? _court;

  String get _fullName => _fullNameController.text;
  String get _seniorName => _seniorNameController.text;
  String get _email => _emailController.text;
  String get _barNumber => _barNumberController.text;

  @override
  void dispose() {
    _fullNameController.dispose();
    _seniorNameController.dispose();
    _emailController.dispose();
    _barNumberController.dispose();
    _practiceAreaController.dispose();
    super.dispose();
  }

  bool get _isJunior => widget.advocateType == AdvocateType.junior;

  bool get _emailValid => _email.trim().contains('@');

  bool get _formValid =>
      _fullName.trim().isNotEmpty &&
      _emailValid &&
      _barNumber.trim().isNotEmpty &&
      _court != null &&
      (!_isJunior || _seniorName.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 4,
      continueEnabled: _formValid,
      onContinue: () {
        AdvocateOnboardingData.current
          ..fullName = _fullName.trim()
          ..seniorAdvocateName = _isJunior ? _seniorName.trim() : ''
          ..email = _email.trim()
          ..barRegistrationNumber = _barNumber.trim()
          ..primaryCourt = _court ?? ''
          ..practiceArea = _practiceAreaController.text.trim();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MyScheduleScreen(),
          ),
        );
      },
      children: [
        const Text(
          'STEP 4 OF 5',
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
          'Professional\nDetails',
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
          'Fill in your credentials. These are verified before your profile goes live.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        _buildRegistrationTypeBar(),
        const SizedBox(height: 20),
        const _FieldLabel('Full Name', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _fullNameController,
          onChanged: (_) => setState(() {}),
          showCheck: _fullName.trim().isNotEmpty,
        ),
        if (_isJunior) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const _FieldLabel('Senior Advocate Name', required: true),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Mandatory for Juniors',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TextInputField(
            controller: _seniorNameController,
            onChanged: (_) => setState(() {}),
            prefixIcon: 'assets/icons/ic_award.svg',
          ),
        ],
        const SizedBox(height: 16),
        const _FieldLabel('Email Address', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _emailController,
          onChanged: (_) => setState(() {}),
          showCheck: _emailValid,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Bar Registration Number', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _barNumberController,
          onChanged: (_) => setState(() {}),
          showCheck: _barNumber.trim().isNotEmpty,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Primary Practice Court', required: true),
        const SizedBox(height: 8),
        _buildCourtPicker(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _FieldLabel('Practice Area'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.progressTrack,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Optional',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.12,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _practiceAreaController,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildRegistrationTypeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_briefcase.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.advocateType.label} registration',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 19.5 / 13,
                letterSpacing: -0.08,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).popUntil(
                (route) =>
                    route.settings.name == DescribeYourselfScreen.routeName ||
                    route.isFirst,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Change',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: AppColors.textGrey555,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtPicker() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showCourtSheet,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _court == null
                  ? AppColors.borderGrey
                  : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _court ?? 'Select court…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.23,
                    color: _court == null
                        ? AppColors.textGrey
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/ic_chevron_down.svg',
                width: 16,
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourtSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Primary Practice Court',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.31,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: _courts.length,
                  itemBuilder: (_, index) {
                    final court = _courts[index];
                    final selected = court == _court;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        court,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: selected
                          ? SvgPicture.asset(
                              'assets/icons/ic_check.svg',
                              width: 14,
                              height: 14,
                            )
                          : null,
                      onTap: () {
                        setState(() => _court = court);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.controller,
    required this.onChanged,
    this.showCheck = false,
    this.prefixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool showCheck;
  final String? prefixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.trim().isNotEmpty;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled ? AppColors.textPrimary : AppColors.borderGrey,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            SvgPicture.asset(prefixIcon!, width: 15, height: 15),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.23,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          ),
          if (showCheck) ...[
            const SizedBox(width: 10),
            SvgPicture.asset(
              'assets/icons/ic_check_circle_dark.svg',
              width: 16,
              height: 16,
            ),
          ],
        ],
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 18 / 12,
          color: AppColors.textGrey555,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFF1A1A1A)),
            ),
        ],
      ),
    );
  }
}
