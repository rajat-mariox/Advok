import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';

/// One editable field of the Edit Profile form — free text, or a picker
/// when [options] is set.
class _FieldSpec {
  _FieldSpec({
    required this.label,
    required this.key,
    required String initial,
    this.required = false,
    this.isEmail = false,
    this.hint,
    this.options,
  }) : controller = TextEditingController(text: initial);

  final String label;

  /// Payload key sent to PUT /profile.
  final String key;
  final TextEditingController controller;
  final bool required;
  final bool isEmail;
  final String? hint;

  /// When set, the field is a fixed-choice picker instead of free text.
  final List<String>? options;
}

/// Edit Profile for every role — photo plus the display fields that role can
/// change (client: name/email, advocate: name/email/practice area, student:
/// name/college/course, firm: firm name/contact person/official email).
/// Saves via PUT /profile.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final List<_FieldSpec> _fields;

  /// Freshly picked photo (preview from file) or the saved one (bytes).
  File? _pickedPhoto;
  String _photoDataUrl = '';
  bool _photoRemoved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = Session.profile ?? const <String, dynamic>{};
    String at(Map<String, dynamic> map, String key) =>
        map[key] as String? ?? '';
    switch (Session.role) {
      case 'advocate':
        final professional =
            p['professional'] as Map<String, dynamic>? ?? const {};
        _fields = [
          _FieldSpec(
            label: 'Full Name',
            key: 'fullName',
            initial: at(professional, 'fullName'),
            required: true,
          ),
          _FieldSpec(
            label: 'Email Address',
            key: 'email',
            initial: at(professional, 'email'),
            required: true,
            isEmail: true,
          ),
          _FieldSpec(
            label: 'Practice Area',
            key: 'practiceArea',
            initial: at(professional, 'practiceArea'),
            hint: 'Select practice area…',
            // Same fixed list the home screen categories are built from.
            options: CountryCatalog.terms.practiceAreas,
          ),
        ];
      case 'law_student':
        _fields = [
          _FieldSpec(
            label: 'Full Name',
            key: 'fullName',
            initial: at(Map<String, dynamic>.from(p), 'fullName'),
            required: true,
          ),
          _FieldSpec(
            label: 'College / University',
            key: 'college',
            initial: at(Map<String, dynamic>.from(p), 'college'),
            required: true,
          ),
          _FieldSpec(
            label: 'Course',
            key: 'course',
            initial: at(Map<String, dynamic>.from(p), 'course'),
            hint: CountryCatalog.terms.degreeHint,
            required: true,
          ),
        ];
      case 'law_firm':
        _fields = [
          _FieldSpec(
            label: 'Firm Name',
            key: 'firmName',
            initial: at(Map<String, dynamic>.from(p), 'firmName'),
            required: true,
          ),
          _FieldSpec(
            label: 'Contact Person',
            key: 'contactPerson',
            initial: at(Map<String, dynamic>.from(p), 'contactPerson'),
            required: true,
          ),
          _FieldSpec(
            label: 'Official Email',
            key: 'officialEmail',
            initial: at(Map<String, dynamic>.from(p), 'officialEmail'),
            required: true,
            isEmail: true,
          ),
        ];
      default: // client
        _fields = [
          _FieldSpec(
            label: 'Full Name',
            key: 'fullName',
            initial: at(Map<String, dynamic>.from(p), 'fullName'),
            required: true,
          ),
          _FieldSpec(
            label: 'Email Address',
            key: 'email',
            initial: at(Map<String, dynamic>.from(p), 'email'),
            isEmail: true,
          ),
        ];
    }
    _photoDataUrl = Session.photo ?? '';
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  Uint8List? get _savedPhotoBytes {
    if (_photoDataUrl.isEmpty) return null;
    final comma = _photoDataUrl.indexOf(',');
    try {
      return base64Decode(
        comma >= 0 ? _photoDataUrl.substring(comma + 1) : _photoDataUrl,
      );
    } catch (_) {
      return null;
    }
  }

  bool get _canSave {
    if (_saving) return false;
    for (final field in _fields) {
      final text = field.controller.text.trim();
      if (field.required && text.isEmpty) return false;
      if (field.isEmail &&
          (field.required || text.isNotEmpty) &&
          !text.contains('@')) {
        return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateProfile({
        for (final field in _fields) field.key: field.controller.text.trim(),
        // '' clears the photo on the backend; otherwise send the new data
        // URL only when the user actually changed it.
        if (_photoRemoved)
          'photo': ''
        else if (_pickedPhoto != null)
          'photo': _photoDataUrl,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
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
      _pickedPhoto = File(picked.path);
      _photoDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      _photoRemoved = false;
    });
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
        final hasPhoto =
            _pickedPhoto != null || (!_photoRemoved && _savedPhotoBytes != null);
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
                if (hasPhoto)
                  option('Remove Photo', () {
                    setState(() {
                      _pickedPhoto = null;
                      _photoDataUrl = '';
                      _photoRemoved = true;
                    });
                  }),
              ],
            ),
          ),
        );
      },
    );
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    Center(child: _buildPhoto()),
                    const SizedBox(height: 24),
                    for (int i = 0; i < _fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _FieldLabel(
                        _fields[i].label,
                        required: _fields[i].required,
                      ),
                      const SizedBox(height: 8),
                      if (_fields[i].options != null)
                        _buildOptionPicker(_fields[i])
                      else
                        _buildInput(
                          _fields[i].controller,
                          hint: _fields[i].hint,
                          keyboardType: _fields[i].isEmail
                              ? TextInputType.emailAddress
                              : null,
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picker-style field: shows the current value and opens a bottom sheet
  /// with the fixed options (matches the onboarding pickers).
  Widget _buildOptionPicker(_FieldSpec field) {
    final value = field.controller.text.trim();
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOptionsSheet(field),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  value.isEmpty ? AppColors.borderGrey : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? (field.hint ?? 'Select…') : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.23,
                    color: value.isEmpty
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

  void _showOptionsSheet(_FieldSpec field) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final options = field.options ?? const <String>[];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  field.label,
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
                    final selected = option == field.controller.text.trim();
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        option,
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
                        setState(() => field.controller.text = option);
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

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleBackButton(),
          const Text(
            'Edit Profile',
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
    );
  }

  Widget _buildPhoto() {
    final saved = _photoRemoved ? null : _savedPhotoBytes;
    Widget avatar;
    if (_pickedPhoto != null) {
      avatar = Image.file(
        _pickedPhoto!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      );
    } else if (saved != null) {
      avatar = Image.memory(saved, width: 96, height: 96, fit: BoxFit.cover);
    } else {
      avatar = Center(
        child: SvgPicture.asset(
          'assets/icons/ic_user.svg',
          width: 32,
          height: 32,
        ),
      );
    }
    return GestureDetector(
      onTap: _showPhotoSheet,
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderGrey, width: 1.4),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatar,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_edit.svg',
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
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: controller.text.trim().isEmpty
              ? AppColors.borderGrey
              : AppColors.textPrimary,
          width: 1.4,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          keyboardType: keyboardType,
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
    );
  }

  Widget _buildSaveButton() {
    final enabled = _canSave;
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
              onTap: enabled ? _save : null,
              child: Center(
                child: Text(
                  _saving ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.31,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
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
