import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Services/api_service.dart';
import '../../Utils/AppColors/app_colors.dart';
import 'firm_registration_submitted_screen.dart';
import 'firm_step_scaffold.dart';
import 'law_firm_registration_models.dart';

const List<String> _designations = [
  'Managing Partner',
  'Partner',
  'Senior Associate',
  'Associate',
  'Junior Advocate',
  'Consultant',
  'Intern',
];

const List<String> _expertiseOptions = [
  'Criminal',
  'Civil',
  'Corporate',
  'Family',
  'Tax',
  'Cyber Crime',
  'Property',
  'Immigration',
  'Labour & Employment',
];

/// Step 2 of the law-firm registration flow: add the lawyers at the firm.
class AddLegalTeamScreen extends StatefulWidget {
  const AddLegalTeamScreen({super.key, required this.registrationData});

  final LawFirmRegistrationData registrationData;

  @override
  State<AddLegalTeamScreen> createState() => _AddLegalTeamScreenState();
}

class _LawyerEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController barLicenseController = TextEditingController();
  final TextEditingController yearsController = TextEditingController();
  String? designation;
  final Set<String> expertise = <String>{};

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    barLicenseController.dispose();
    yearsController.dispose();
  }
}

class _AddLegalTeamScreenState extends State<AddLegalTeamScreen> {
  // Controllers keep the text alive when the lazy ListView disposes
  // off-screen fields while the user scrolls through the form.
  final TextEditingController _totalLawyersController =
      TextEditingController();
  final List<_LawyerEntry> _lawyers = [_LawyerEntry()];
  bool _submitting = false;

  @override
  void dispose() {
    _totalLawyersController.dispose();
    for (final lawyer in _lawyers) {
      lawyer.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final data = widget.registrationData;
    final lawyers = _lawyers
        .where((l) => l.nameController.text.trim().isNotEmpty)
        .map(
          (l) => {
            'fullName': l.nameController.text.trim(),
            'phone': l.phoneController.text.trim(),
            'barLicense': l.barLicenseController.text.trim(),
            'yearsExperience': l.yearsController.text.trim(),
            'designation': l.designation ?? '',
            'expertise': l.expertise.toList(),
          },
        )
        .toList();
    setState(() => _submitting = true);
    try {
      await ApiService.submitFirmOnboarding({
        'firmName': data.firmName,
        'foundedYear': data.foundedYear,
        'contactPerson': data.contactPersonName,
        'logoFileName': data.logoFileName ?? '',
        'officialEmail': data.officialEmail,
        'mainPhone': data.mainPhone,
        'receptionNumber': data.receptionNumber ?? '',
        'addressLine1': data.addressLine1,
        'addressLine2': data.addressLine2 ?? '',
        'city': data.city,
        'zip': data.zipCode,
        'state': data.state,
        'totalLawyers': _totalLawyersController.text.trim(),
        'lawyers': lawyers,
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const FirmRegistrationSubmittedScreen(),
        ),
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
  Widget build(BuildContext context) {
    return FirmStepScaffold(
      currentStep: 2,
      continueEnabled: !_submitting,
      continueLabel: _submitting ? 'Submitting…' : 'Submit Registration',
      onContinue: _submit,
      children: [
        const Text(
          'Add Your Legal Team',
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
          'Add the lawyers at your firm. You can edit or add more after registration.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('Total Lawyers at Firm'),
        const SizedBox(height: 8),
        _buildTotalLawyersField(),
        const SizedBox(height: 24),
        const _SectionHeader('LAWYER DETAILS'),
        const SizedBox(height: 12),
        for (int i = 0; i < _lawyers.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          _buildLawyerCard(i),
        ],
        const SizedBox(height: 24),
        _buildAddLawyerButton(),
      ],
    );
  }

  Widget _buildTotalLawyersField() {
    final filled = _totalLawyersController.text.trim().isNotEmpty;
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
          SvgPicture.asset(
            'assets/icons/ic_user.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _totalLawyersController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.23,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'e.g. 15',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.23,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerCard(int index) {
    final lawyer = _lawyers[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lawyer ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_lawyers.length > 1)
                Material(
                  color: AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() => _lawyers.removeAt(index).dispose());
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/ic_clear.svg',
                        width: 12,
                        height: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _FieldLabel('Full Name'),
          const SizedBox(height: 8),
          _CardInputField(
            controller: lawyer.nameController,
            hint: 'Full name',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _CardInputField(
                      controller: lawyer.phoneController,
                      hint: '(555) 000-0000',
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Bar License'),
                    const SizedBox(height: 8),
                    _CardInputField(
                      controller: lawyer.barLicenseController,
                      hint: 'NY/2021/000',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Years Experience'),
                    const SizedBox(height: 8),
                    _CardInputField(
                      controller: lawyer.yearsController,
                      hint: 'e.g. 5',
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Designation'),
                    const SizedBox(height: 8),
                    _buildDesignationPicker(lawyer),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Expertise'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _expertiseOptions)
                _ExpertiseChip(
                  label: option,
                  selected: lawyer.expertise.contains(option),
                  onTap: () {
                    setState(() {
                      if (!lawyer.expertise.remove(option)) {
                        lawyer.expertise.add(option);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesignationPicker(_LawyerEntry lawyer) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDesignationSheet(lawyer),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lawyer.designation == null
                  ? AppColors.borderGrey
                  : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lawyer.designation ?? 'Select…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                    color: lawyer.designation == null
                        ? AppColors.textGrey
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icons/ic_chevron_down.svg',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDesignationSheet(_LawyerEntry lawyer) {
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
                  'Designation',
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
                  itemCount: _designations.length,
                  itemBuilder: (_, index) {
                    final designation = _designations[index];
                    final selected = designation == lawyer.designation;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        designation,
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
                        setState(() => lawyer.designation = designation);
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

  Widget _buildAddLawyerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _lawyers.add(_LawyerEntry())),
        child: CustomPaint(
          foregroundPainter: const _DashedBorderPainter(
            color: AppColors.borderGrey,
            radius: 16,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: AppColors.fillGrey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_plus.svg',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Another Lawyer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
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

/// White input used inside the grey lawyer cards.
class _CardInputField extends StatelessWidget {
  const _CardInputField({
    required this.controller,
    required this.onChanged,
    this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.trim().isNotEmpty;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? AppColors.textPrimary : AppColors.borderGrey,
          width: 1.4,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.15,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpertiseChip extends StatelessWidget {
  const _ExpertiseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: selected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
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
