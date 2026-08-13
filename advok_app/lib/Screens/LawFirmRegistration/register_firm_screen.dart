import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../CommonWidgets/phone_number_limit_formatter.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import 'add_legal_team_screen.dart';
import 'firm_step_scaffold.dart';
import 'law_firm_registration_models.dart';

// States/provinces of the country chosen at login.
List<String> get _states => CountryCatalog.selected.states;
String get _stateLabel => CountryCatalog.selected.stateLabel;

class RegisterFirmScreen extends StatefulWidget {
  const RegisterFirmScreen({super.key});

  static const String routeName = 'law_firm_register';

  @override
  State<RegisterFirmScreen> createState() => _RegisterFirmScreenState();
}

class _RegisterFirmScreenState extends State<RegisterFirmScreen> {
  // Controllers keep the text alive when the lazy ListView disposes
  // off-screen fields while the user scrolls through the form.
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _foundedYearController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mainPhoneController = TextEditingController();
  final TextEditingController _receptionController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  String? _state;
  String? _logoFileName;

  static const int _maxLogoBytes = 2 * 1024 * 1024;

  @override
  void dispose() {
    _firmNameController.dispose();
    _foundedYearController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _mainPhoneController.dispose();
    _receptionController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  bool get _emailValid => _emailController.text.trim().contains('@');

  bool get _formValid =>
      _firmNameController.text.trim().isNotEmpty &&
      _foundedYearController.text.trim().isNotEmpty &&
      _contactPersonController.text.trim().isNotEmpty &&
      _emailValid &&
      _mainPhoneController.text.trim().isNotEmpty &&
      _address1Controller.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _zipController.text.trim().isNotEmpty &&
      _state != null;

  @override
  Widget build(BuildContext context) {
    return FirmStepScaffold(
      currentStep: 1,
      continueEnabled: _formValid,
      onContinue: () {
        final data = LawFirmRegistrationData(
          firmName: _firmNameController.text.trim(),
          foundedYear: _foundedYearController.text.trim(),
          contactPersonName: _contactPersonController.text.trim(),
          logoFileName: _logoFileName,
          officialEmail: _emailController.text.trim(),
          mainPhone: _mainPhoneController.text.trim(),
          receptionNumber: _receptionController.text.trim().isEmpty
              ? null
              : _receptionController.text.trim(),
          addressLine1: _address1Controller.text.trim(),
          addressLine2: _address2Controller.text.trim().isEmpty
              ? null
              : _address2Controller.text.trim(),
          city: _cityController.text.trim(),
          zipCode: _zipController.text.trim(),
          state: _state!,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddLegalTeamScreen(registrationData: data),
          ),
        );
      },
      children: [
        const Text(
          'Register Your Law Firm',
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
          "Create your firm's profile to connect with clients across the platform.",
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader('FIRM PROFILE'),
        const SizedBox(height: 12),
        const _FieldLabel('Firm Name', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _firmNameController,
          hint: 'e.g. Mitchell & Associates',
          onChanged: (_) => setState(() {}),
          showCheck: _firmNameController.text.trim().isNotEmpty,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Founded Year', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _foundedYearController,
          hint: 'e.g. 2005',
          onChanged: (_) => setState(() {}),
          showCheck: _foundedYearController.text.trim().isNotEmpty,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Contact Person Name', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _contactPersonController,
          hint: "Managing Partner's name",
          onChanged: (_) => setState(() {}),
          showCheck: _contactPersonController.text.trim().isNotEmpty,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionHeader('FIRM LOGO'),
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
        const SizedBox(height: 12),
        _buildLogoUploadBox(),
        const SizedBox(height: 24),
        const _SectionHeader('CONTACT INFORMATION'),
        const SizedBox(height: 12),
        const _FieldLabel('Official Email', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _emailController,
          hint: 'contact@yourfirm.com',
          onChanged: (_) => setState(() {}),
          showCheck: _emailValid,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Main Phone', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _mainPhoneController,
          hint: '(555) 000-0000',
          onChanged: (_) => setState(() {}),
          showCheck: _mainPhoneController.text.trim().isNotEmpty,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneNumberLimitFormatter()],
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Reception Number'),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _receptionController,
          hint: '(555) 000-0001',
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneNumberLimitFormatter()],
        ),
        const SizedBox(height: 24),
        const _SectionHeader('OFFICE ADDRESS'),
        const SizedBox(height: 12),
        const _FieldLabel('Address Line 1', required: true),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _address1Controller,
          hint: 'Street address',
          onChanged: (_) => setState(() {}),
          showCheck: _address1Controller.text.trim().isNotEmpty,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Address Line 2'),
        const SizedBox(height: 8),
        _TextInputField(
          controller: _address2Controller,
          hint: 'Suite, floor, etc.',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('City', required: true),
                  const SizedBox(height: 8),
                  _TextInputField(
                    controller: _cityController,
                    hint: 'City',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('ZIP Code', required: true),
                  const SizedBox(height: 8),
                  _TextInputField(
                    controller: _zipController,
                    hint: '10001',
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FieldLabel(_stateLabel, required: true),
        const SizedBox(height: 8),
        _buildStatePicker(),
      ],
    );
  }

  Future<void> _pickLogoFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'svg'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.size > _maxLogoBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large. Max size is 2MB.')),
      );
      return;
    }
    setState(() => _logoFileName = file.name);
  }

  Widget _buildLogoUploadBox() {
    if (_logoFileName != null) {
      return _buildLogoUploadedCard();
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _pickLogoFile,
        child: CustomPaint(
          foregroundPainter: const _DashedBorderPainter(
            color: AppColors.borderGrey,
            radius: 16,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.fillGrey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload Firm Logo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'PNG · SVG · Max 2MB',
                  style: TextStyle(
                    fontSize: 11,
                    height: 16 / 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoUploadedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 1.4),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_check.svg',
                width: 14,
                height: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _logoFileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 19.5 / 13,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Uploaded successfully',
                  style: TextStyle(
                    fontSize: 11,
                    height: 16 / 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _logoFileName = null),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  'assets/icons/ic_clear.svg',
                  width: 14,
                  height: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatePicker() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showStateSheet,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _state == null
                  ? AppColors.borderGrey
                  : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _state ?? 'Select ${_stateLabel.toLowerCase()}…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.23,
                    color: _state == null
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

  void _showStateSheet() {
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
                  'Select $_stateLabel',
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
                  itemCount: _states.length,
                  itemBuilder: (_, index) {
                    final state = _states[index];
                    final selected = state == _state;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        state,
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
                        setState(() => _state = state);
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 16 / 11,
        letterSpacing: 1.65,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.controller,
    required this.onChanged,
    this.hint,
    this.showCheck = false,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool showCheck;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.23,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.23,
                  color: AppColors.textGrey,
                ),
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
