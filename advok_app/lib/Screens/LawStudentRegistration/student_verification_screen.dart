import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../CommonWidgets/circle_back_button.dart';
import '../../Services/api_service.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import 'verification_submitted_screen.dart';

const List<String> _academicYears = [
  '1st Year',
  '2nd Year',
  '3rd Year',
  '4th Year',
  '5th Year',
  'Final Year',
];

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  String? _academicYear;
  File? _profilePhoto;
  String? _idFileName;

  static const int _maxIdFileBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _fullNameController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  bool _submitting = false;

  bool get _formValid =>
      _fullNameController.text.trim().isNotEmpty &&
      _collegeController.text.trim().isNotEmpty &&
      _courseController.text.trim().isNotEmpty &&
      _academicYear != null &&
      !_submitting;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.submitStudentOnboarding({
        'fullName': _fullNameController.text.trim(),
        'college': _collegeController.text.trim(),
        'course': _courseController.text.trim(),
        'academicYear': _academicYear,
        'idCardFileName': _idFileName ?? '',
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const VerificationSubmittedScreen(),
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
                      _buildInfoBanner(),
                      const SizedBox(height: 24),
                      _buildProfilePhoto(),
                      const SizedBox(height: 24),
                      const _FieldLabel('Full Name', required: true),
                      const SizedBox(height: 8),
                      _TextInputField(
                        controller: _fullNameController,
                        hint: 'As per college records',
                        onChanged: (_) => setState(() {}),
                        showCheck:
                            _fullNameController.text.trim().isNotEmpty,
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('College / University', required: true),
                      const SizedBox(height: 8),
                      _TextInputField(
                        controller: _collegeController,
                        hint: 'e.g. Harvard Law School',
                        prefixIcon: 'assets/icons/ic_office.svg',
                        onChanged: (_) => setState(() {}),
                        showCheck: _collegeController.text.trim().isNotEmpty,
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Course', required: true),
                      const SizedBox(height: 8),
                      _TextInputField(
                        controller: _courseController,
                        hint: CountryCatalog.terms.degreeHint,
                        prefixIcon: 'assets/icons/ic_book_open.svg',
                        onChanged: (_) => setState(() {}),
                        showCheck: _courseController.text.trim().isNotEmpty,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _FieldLabel('Academic Year'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                      _buildYearPicker(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _FieldLabel('College ID Card'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                      const SizedBox(height: 4),
                      const Text(
                        'Supported: JPG, PNG, PDF',
                        style: TextStyle(
                          fontSize: 11,
                          height: 16 / 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildIdUploadBox(),
                      const SizedBox(height: 16),
                      _buildPrivacyNote(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildSubmitButton(),
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
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'LAW STUDENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: 2.4,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                'Student Verification',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 24 / 17,
                  letterSpacing: -0.34,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_role_student.svg',
            width: 18,
            height: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Verify your student status to access learning resources, '
              'AI tools, legal case studies, and internships.',
              style: TextStyle(
                fontSize: 13,
                height: 19.5 / 13,
                letterSpacing: -0.08,
                color: AppColors.textGrey555,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _showPhotoSourceSheet,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.fillGrey,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: _profilePhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: Image.file(
                              _profilePhoto!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: SvgPicture.asset(
                              'assets/icons/ic_user.svg',
                              width: 28,
                              height: 28,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: _showPhotoSourceSheet,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/ic_camera.svg',
                          width: 13,
                          height: 13,
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
          ),
          const SizedBox(height: 8),
          const Text(
            'Profile Photo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showYearSheet,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _academicYear == null
                  ? AppColors.borderGrey
                  : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _academicYear ?? 'Select year…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.23,
                    color: _academicYear == null
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

  void _showYearSheet() {
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
                  'Academic Year',
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
                  itemCount: _academicYears.length,
                  itemBuilder: (_, index) {
                    final year = _academicYears[index];
                    final selected = year == _academicYear;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        year,
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
                        setState(() => _academicYear = year);
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

  void _showPhotoSourceSheet() {
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
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.31,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: SvgPicture.asset(
                        'assets/icons/ic_camera.svg',
                        width: 18,
                        height: 18,
                      ),
                      title: const Text(
                        'Take Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickProfilePhoto(ImageSource.camera);
                      },
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      title: const Text(
                        'Choose from Gallery',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickProfilePhoto(ImageSource.gallery);
                      },
                    ),
                    if (_profilePhoto != null)
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: SvgPicture.asset(
                          'assets/icons/ic_trash.svg',
                          width: 18,
                          height: 18,
                        ),
                        title: const Text(
                          'Remove Photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _profilePhoto = null);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _profilePhoto = File(picked.path));
  }

  Future<void> _pickIdFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.single;
    if (file.size > _maxIdFileBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large. Max size is 5MB.')),
      );
      return;
    }
    setState(() => _idFileName = file.name);
  }

  Widget _buildIdUploadBox() {
    if (_idFileName != null) {
      return _buildIdUploadedCard();
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _pickIdFile,
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
                  'Tap to Upload College ID',
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
                  'JPG · PNG · PDF · Max 5MB',
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

  Widget _buildIdUploadedCard() {
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
                  _idFileName!,
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
              onTap: () => setState(() => _idFileName = null),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  'assets/icons/ic_trash.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_lock.svg',
            width: 14,
            height: 14,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Your documents are encrypted and only used for verification. '
              'They are never shared publicly.',
              style: TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = _formValid;
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
              onTap: enabled ? _submit : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _submitting ? 'Submitting…' : 'Submit for Verification',
                    style: const TextStyle(
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

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.controller,
    required this.onChanged,
    this.hint,
    this.showCheck = false,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool showCheck;
  final String? prefixIcon;

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
