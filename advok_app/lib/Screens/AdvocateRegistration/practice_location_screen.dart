import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'professional_details_screen.dart';

class PracticeLocationScreen extends StatefulWidget {
  const PracticeLocationScreen({super.key, required this.advocateType});

  final AdvocateType advocateType;

  @override
  State<PracticeLocationScreen> createState() =>
      _PracticeLocationScreenState();
}

class _PracticeLocationScreenState extends State<PracticeLocationScreen> {
  String? _state;
  // Controllers keep the text alive when the lazy ListView disposes
  // off-screen fields while the user scrolls (e.g. with the keyboard open).
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _officeController = TextEditingController();

  // States/provinces of the country chosen at login.
  List<String> get _states => CountryCatalog.selected.states;
  String get _stateLabel => CountryCatalog.selected.stateLabel;

  String get _district => _districtController.text;
  String get _office => _officeController.text;

  @override
  void dispose() {
    _districtController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 3,
      continueEnabled: _state != null && _district.trim().isNotEmpty,
      onContinue: () {
        AdvocateOnboardingData.current
          ..state = _state ?? ''
          ..district = _district.trim()
          ..officeAddress = _office.trim();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfessionalDetailsScreen(
              advocateType: widget.advocateType,
            ),
          ),
        );
      },
      children: [
        const Text(
          'STEP 3 OF 5',
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
          'Where do you\npractice?',
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
          'Your location helps clients find advocates in their area.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        _FieldLabel(_stateLabel, required: true),
        const SizedBox(height: 8),
        _buildStatePicker(),
        const SizedBox(height: 16),
        const _FieldLabel('District / City', required: true),
        const SizedBox(height: 8),
        _buildDistrictField(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _FieldLabel('Office Address'),
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
        _buildOfficeAddressField(),
        const SizedBox(height: 16),
        _buildPrivacyNote(),
      ],
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

  Widget _buildDistrictField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _district.trim().isEmpty
              ? AppColors.borderGrey
              : AppColors.textPrimary,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_pin.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _districtController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.23,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'e.g. Manhattan, Brooklyn…',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.23,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeAddressField() {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _office.trim().isEmpty
              ? AppColors.borderGrey
              : AppColors.textPrimary,
          width: 1.4,
        ),
      ),
      child: TextField(
        controller: _officeController,
        maxLines: null,
        expands: true,
        onChanged: (_) => setState(() {}),
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          fontSize: 14,
          height: 22.4 / 14,
          letterSpacing: -0.15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'Street, floor, suite number…',
          hintStyle: TextStyle(
            fontSize: 14,
            height: 22.4 / 14,
            letterSpacing: -0.15,
            color: AppColors.textPrimary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_pin.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your precise address is never shared publicly. Only your city/district is visible to clients.',
              style: TextStyle(
                fontSize: 12,
                height: 19.5 / 12,
                color: AppColors.textGrey555,
              ),
            ),
          ),
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
