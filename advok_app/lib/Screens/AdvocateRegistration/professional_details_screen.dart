import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'describe_yourself_screen.dart';
import 'my_schedule_screen.dart';

// Courts differ per country (Indian vs US court system).
List<String> get _courts => CountryCatalog.terms.courts;

class ProfessionalDetailsScreen extends StatefulWidget {
  const ProfessionalDetailsScreen({super.key, required this.advocateType});

  final AdvocateType advocateType;

  @override
  State<ProfessionalDetailsScreen> createState() =>
      _ProfessionalDetailsScreenState();
}

/// One editable US state bar admission row: State + Bar Number + License
/// Status. The controller lives here so text survives ListView recycling.
class _BarAdmissionEntry {
  final TextEditingController numberController = TextEditingController();
  String? state;
  String? licenseStatus;

  bool get complete =>
      state != null &&
      numberController.text.trim().isNotEmpty &&
      licenseStatus != null;

  void dispose() => numberController.dispose();
}

class _ProfessionalDetailsScreenState extends State<ProfessionalDetailsScreen> {
  // Controllers keep the text alive when the lazy ListView disposes
  // off-screen fields while the user scrolls through the form.
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _seniorNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _barNumberController = TextEditingController();
  String? _court;
  String? _practiceArea;

  /// US flow: state bar admissions (at least one) + optional federal courts.
  final List<_BarAdmissionEntry> _barAdmissions = [_BarAdmissionEntry()];
  final Set<String> _federalCourts = <String>{};

  /// Local preview + base64 data URL sent to the backend.
  File? _photoFile;
  String _photoDataUrl = '';

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
    for (final entry in _barAdmissions) {
      entry.dispose();
    }
    super.dispose();
  }

  /// US collects structured bar admissions instead of a single bar number +
  /// primary court pair.
  bool get _usesBarAdmissions => CountryCatalog.terms.usesBarAdmissions;

  bool get _isJunior => widget.advocateType == AdvocateType.junior;

  /// India: a junior must name their senior advocate. US: the supervising
  /// attorney field is optional.
  bool get _mentorRequired =>
      _isJunior && CountryCatalog.terms.mentorRequiredForJunior;

  bool get _emailValid => _email.trim().contains('@');

  bool get _formValid =>
      _fullName.trim().isNotEmpty &&
      _emailValid &&
      (_usesBarAdmissions
          ? _barAdmissions.isNotEmpty &&
              _barAdmissions.every((entry) => entry.complete)
          : _barNumber.trim().isNotEmpty && _court != null) &&
      (!_mentorRequired || _seniorName.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 4,
      continueEnabled: _formValid,
      onContinue: () {
        final admissions = _usesBarAdmissions
            ? _barAdmissions
                .where((entry) => entry.complete)
                .map(
                  (entry) => BarAdmission(
                    state: entry.state!,
                    barNumber: entry.numberController.text.trim(),
                    licenseStatus: entry.licenseStatus!,
                  ),
                )
                .toList()
            : <BarAdmission>[];
        AdvocateOnboardingData.current
          ..fullName = _fullName.trim()
          ..seniorAdvocateName = _isJunior ? _seniorName.trim() : ''
          ..email = _email.trim()
          // US: mirror the first state bar admission into the legacy
          // licenseNumber/primaryCourt fields so older backend/admin views
          // keep displaying something meaningful.
          ..licenseNumber = _usesBarAdmissions
              ? admissions.first.barNumber
              : _barNumber.trim()
          ..primaryCourt = _usesBarAdmissions
              ? '${admissions.first.state} State Bar'
              : _court ?? ''
          ..barAdmissions = admissions
          ..federalCourtAdmissions = _federalCourts.toList()
          ..practiceArea = _practiceArea ?? ''
          ..photo = _photoDataUrl;
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
        _buildPhotoPicker(),
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
              _FieldLabel(
                CountryCatalog.terms.mentorFieldLabel,
                required: _mentorRequired,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _mentorRequired ? 'Mandatory for Juniors' : 'Optional',
                  style: const TextStyle(
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
        if (_usesBarAdmissions) ...[
          // US: Bar Admissions / Court Admissions — one or more state bar
          // entries (State + Bar Number + License Status) + optional
          // federal court admissions.
          const SizedBox(height: 16),
          _FieldLabel(CountryCatalog.terms.courtFieldLabel, required: true),
          const SizedBox(height: 8),
          for (var i = 0; i < _barAdmissions.length; i++) ...[
            _buildBarAdmissionCard(i),
            const SizedBox(height: 12),
          ],
          _buildAddBarAdmissionButton(),
          const SizedBox(height: 16),
          _buildFederalCourtsSection(),
        ] else ...[
          const SizedBox(height: 16),
          _FieldLabel(CountryCatalog.terms.licenseLabel, required: true),
          const SizedBox(height: 8),
          _TextInputField(
            controller: _barNumberController,
            onChanged: (_) => setState(() {}),
            showCheck: _barNumber.trim().isNotEmpty,
          ),
          const SizedBox(height: 16),
          _FieldLabel(CountryCatalog.terms.courtFieldLabel, required: true),
          const SizedBox(height: 8),
          _buildCourtPicker(),
        ],
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
        _buildPracticeAreaPicker(),
      ],
    );
  }

  /// Optional profile photo shown to clients on the browse/profile cards.
  Widget _buildPhotoPicker() {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGrey, width: 1.4),
          ),
          child: _photoFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Image.file(
                    _photoFile!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_user.svg',
                    width: 26,
                    height: 26,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('Profile Photo'),
              const SizedBox(height: 2),
              const Text(
                'Shown to clients on your profile',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: _showPhotoSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Text(
                      _photoFile == null ? 'Add Photo' : 'Change Photo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPhotoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        ListTile option(String title, VoidCallback onTap) => ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onTap();
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                option('Take Photo', () => _pickPhoto(ImageSource.camera)),
                option(
                  'Choose from Gallery',
                  () => _pickPhoto(ImageSource.gallery),
                ),
                if (_photoFile != null)
                  option('Remove Photo', () {
                    setState(() {
                      _photoFile = null;
                      _photoDataUrl = '';
                    });
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    // Small + compressed so the base64 payload stays well under the
    // backend's JSON size limit.
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoFile = File(picked.path);
      _photoDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Widget _buildRegistrationTypeBar() {
    // US flow shows the picked firm role (Partner, Associate…); the tier
    // label (Junior/Senior Advocate) is the India flow.
    final firmRole = AdvocateOnboardingData.current.firmRole;
    final typeLabel =
        firmRole.isNotEmpty ? firmRole : widget.advocateType.label;
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
              '$typeLabel registration',
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
    return _buildPickerField(
      value: _court,
      hint: 'Select court…',
      onTap: () => _showOptionSheet(
        title: 'Primary Practice Court',
        options: _courts,
        selected: _court,
        onSelect: (value) => setState(() => _court = value),
      ),
    );
  }

  /// One state bar admission entry: State + Bar Number + License Status.
  Widget _buildBarAdmissionCard(int index) {
    final entry = _barAdmissions[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.complete ? AppColors.textPrimary : AppColors.borderGrey,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'State Bar Admission ${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 18 / 12,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_barAdmissions.length > 1)
                InkWell(
                  onTap: () => setState(() {
                    _barAdmissions.removeAt(index).dispose();
                  }),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Remove',
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
          const SizedBox(height: 10),
          const _FieldLabel('State', required: true),
          const SizedBox(height: 8),
          _buildPickerField(
            value: entry.state,
            hint: 'Select state…',
            onTap: () => _showOptionSheet(
              title: 'State',
              options: CountryCatalog.selected.states,
              selected: entry.state,
              onSelect: (value) => setState(() => entry.state = value),
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(CountryCatalog.terms.licenseLabel, required: true),
          const SizedBox(height: 8),
          _TextInputField(
            controller: entry.numberController,
            onChanged: (_) => setState(() {}),
            showCheck: entry.numberController.text.trim().isNotEmpty,
          ),
          const SizedBox(height: 12),
          const _FieldLabel('License Status', required: true),
          const SizedBox(height: 8),
          _buildPickerField(
            value: entry.licenseStatus,
            hint: 'Select license status…',
            onTap: () => _showOptionSheet(
              title: 'License Status',
              options: CountryCatalog.terms.licenseStatuses,
              selected: entry.licenseStatus,
              onSelect: (value) => setState(() => entry.licenseStatus = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBarAdmissionButton() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _barAdmissions.add(_BarAdmissionEntry())),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: const Text(
            '+ Add Another State Bar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 19.5 / 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Optional multi-select of federal courts the attorney is admitted to.
  Widget _buildFederalCourtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _FieldLabel('Federal Court Admissions'),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final court in CountryCatalog.terms.federalCourts)
              _buildFederalCourtChip(court),
          ],
        ),
      ],
    );
  }

  Widget _buildFederalCourtChip(String court) {
    final selected = _federalCourts.contains(court);
    return Material(
      color: selected ? AppColors.fillGrey : AppColors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => setState(() {
          if (!_federalCourts.remove(court)) _federalCourts.add(court);
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                court,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 18 / 12,
                  color: AppColors.textPrimary,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                SvgPicture.asset(
                  'assets/icons/ic_check.svg',
                  width: 12,
                  height: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeAreaPicker() {
    return _buildPickerField(
      value: _practiceArea,
      hint: 'Select practice area…',
      onTap: () => _showOptionSheet(
        title: 'Practice Area',
        options: CountryCatalog.terms.practiceAreas,
        selected: _practiceArea,
        onSelect: (value) => setState(() => _practiceArea = value),
      ),
    );
  }

  Widget _buildPickerField({
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value == null
                  ? AppColors.borderGrey
                  : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.23,
                    color: value == null
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

  void _showOptionSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  title,
                  style: const TextStyle(
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
                  itemCount: options.length,
                  itemBuilder: (_, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? SvgPicture.asset(
                              'assets/icons/ic_check.svg',
                              width: 14,
                              height: 14,
                            )
                          : null,
                      onTap: () {
                        onSelect(option);
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
