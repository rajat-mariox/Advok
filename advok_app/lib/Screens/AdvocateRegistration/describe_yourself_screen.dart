import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import '../../Utils/Responsive/responsive.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'select_purpose_screen.dart';

class DescribeYourselfScreen extends StatefulWidget {
  const DescribeYourselfScreen({super.key});

  static const String routeName = 'advocate_describe';

  @override
  State<DescribeYourselfScreen> createState() => _DescribeYourselfScreenState();
}

class _DescribeYourselfScreenState extends State<DescribeYourselfScreen> {
  // India-style flow: one of the two tier cards.
  AdvocateType? _selected;

  // US-style flow: Years in Practice + Firm Role instead of a fixed tier.
  String? _years;
  String? _firmRole;

  bool get _usesFirmRoles => CountryCatalog.terms.usesFirmRoles;

  bool get _canContinue => _usesFirmRoles
      ? _years != null && _firmRole != null
      : _selected != null;

  /// The rest of the flow (and the backend) still works on a junior/senior
  /// tier, so for the US we derive it from the role + experience.
  AdvocateType get _derivedType {
    if (!_usesFirmRoles) return _selected!;
    const seniorRoles = {
      'Partner',
      'Of Counsel',
      'Counsel',
      'Solo Practitioner',
    };
    const seniorYears = {'11–20 years', '20+ years'};
    return seniorRoles.contains(_firmRole) || seniorYears.contains(_years)
        ? AdvocateType.senior
        : AdvocateType.junior;
  }

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 1,
      continueEnabled: _canContinue,
      onContinue: () {
        final type = _derivedType;
        AdvocateOnboardingData.current
          ..advocateType = type
          ..yearsInPractice = _usesFirmRoles ? (_years ?? '') : ''
          ..firmRole = _usesFirmRoles ? (_firmRole ?? '') : '';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SelectPurposeScreen(advocateType: type),
          ),
        );
      },
      children: [
        _buildRegistrationBanner(),
        const SizedBox(height: 24),
        const Text(
          'STEP 1 OF 5',
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
          'Describe Yourself',
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
          'Choose your professional role to personalise your experience.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        if (_usesFirmRoles) ..._buildFirmRoleSections() else ...[
          _AdvocateTypeCard(
            title: CountryCatalog.terms.juniorTitle,
            subtitle: CountryCatalog.terms.juniorSubtitle,
            note: CountryCatalog.terms.juniorNote,
            selected: _selected == AdvocateType.junior,
            onTap: () => setState(() => _selected = AdvocateType.junior),
          ),
          const SizedBox(height: 12),
          _AdvocateTypeCard(
            title: CountryCatalog.terms.seniorTitle,
            subtitle: CountryCatalog.terms.seniorSubtitle,
            note: CountryCatalog.terms.seniorNote,
            selected: _selected == AdvocateType.senior,
            onTap: () => setState(() => _selected = AdvocateType.senior),
          ),
        ],
      ],
    );
  }

  /// US variant: two independent questions instead of a fixed tier.
  List<Widget> _buildFirmRoleSections() {
    return [
      const _SectionLabel('Years in Practice'),
      const SizedBox(height: 8),
      _DropdownField(
        value: _years,
        placeholder: 'Select years in practice…',
        onTap: () => _showOptionsSheet(
          title: 'Years in Practice',
          options: CountryCatalog.terms.yearsInPracticeOptions,
          selected: _years,
          onSelected: (value) => setState(() => _years = value),
        ),
      ),
      const SizedBox(height: 16),
      const _SectionLabel('Firm Role'),
      const SizedBox(height: 8),
      _DropdownField(
        value: _firmRole,
        placeholder: 'Select firm role…',
        onTap: () => _showOptionsSheet(
          title: 'Firm Role',
          options: CountryCatalog.terms.firmRoles,
          selected: _firmRole,
          onSelected: (value) => setState(() => _firmRole = value),
        ),
      ),
    ];
  }

  void _showOptionsSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
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
                        onSelected(option);
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

  Widget _buildRegistrationBanner() {
    return Container(
      height: context.rs(110),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.progressTrack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_briefcase.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${CountryCatalog.terms.lawyerSingular} Registration',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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

/// Dropdown-style field (tap to open a bottom sheet of options), styled like
/// the court picker on the Professional Details step.
class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              color:
                  value == null ? AppColors.borderGrey : AppColors.textPrimary,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder,
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
}

class _AdvocateTypeCard extends StatelessWidget {
  const _AdvocateTypeCard({
    required this.title,
    required this.subtitle,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.textPrimary : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.white.withValues(alpha: 0.15)
                          : AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_award.svg',
                        width: 22,
                        height: 22,
                        colorFilter: selected
                            ? const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected ? AppColors.white : Colors.transparent,
                      border: selected
                          ? null
                          : Border.all(
                              color: AppColors.borderGrey,
                              width: 1.4,
                            ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 24 / 16,
                  letterSpacing: -0.31,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 13,
                  letterSpacing: -0.08,
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.75)
                      : AppColors.textGrey555,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 12,
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.55)
                      : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
