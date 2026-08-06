import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Utils/AppColors/app_colors.dart';
import 'advocate_registration_models.dart';
import 'advocate_step_scaffold.dart';
import 'practice_location_screen.dart';

enum AdvokPurpose {
  findClients,
  manageCases,
  scheduleHearings,
  onlineConsultation,
  documentManagement,
  everything,
}

class _PurposeOption {
  const _PurposeOption({
    required this.purpose,
    required this.icon,
    required this.label,
  });

  final AdvokPurpose purpose;
  final String icon;
  final String label;
}

const List<_PurposeOption> _options = [
  _PurposeOption(
    purpose: AdvokPurpose.findClients,
    icon: 'assets/icons/ic_purpose_clients.svg',
    label: 'Find Clients',
  ),
  _PurposeOption(
    purpose: AdvokPurpose.manageCases,
    icon: 'assets/icons/ic_purpose_cases.svg',
    label: 'Manage Cases',
  ),
  _PurposeOption(
    purpose: AdvokPurpose.scheduleHearings,
    icon: 'assets/icons/ic_purpose_hearings.svg',
    label: 'Schedule Hearings',
  ),
  _PurposeOption(
    purpose: AdvokPurpose.onlineConsultation,
    icon: 'assets/icons/ic_purpose_consult.svg',
    label: 'Online Consultation',
  ),
  _PurposeOption(
    purpose: AdvokPurpose.documentManagement,
    icon: 'assets/icons/ic_purpose_docs.svg',
    label: 'Document Management',
  ),
  _PurposeOption(
    purpose: AdvokPurpose.everything,
    icon: 'assets/icons/ic_purpose_everything.svg',
    label: 'Everything',
  ),
];

class SelectPurposeScreen extends StatefulWidget {
  const SelectPurposeScreen({super.key, required this.advocateType});

  final AdvocateType advocateType;

  @override
  State<SelectPurposeScreen> createState() => _SelectPurposeScreenState();
}

class _SelectPurposeScreenState extends State<SelectPurposeScreen> {
  final Set<AdvokPurpose> _selected = {};

  void _toggle(AdvokPurpose purpose) {
    setState(() {
      if (_selected.contains(purpose)) {
        _selected.remove(purpose);
        return;
      }
      // "Everything" is exclusive of the individual purposes.
      if (purpose == AdvokPurpose.everything) {
        _selected.clear();
      } else {
        _selected.remove(AdvokPurpose.everything);
      }
      _selected.add(purpose);
    });
  }

  _PurposeOption _option(AdvokPurpose purpose) =>
      _options.firstWhere((o) => o.purpose == purpose);

  Widget _card(AdvokPurpose purpose) {
    final option = _option(purpose);
    return _PurposeCard(
      option: option,
      selected: _selected.contains(purpose),
      onTap: () => _toggle(purpose),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdvocateStepScaffold(
      currentStep: 2,
      continueEnabled: _selected.isNotEmpty,
      onContinue: () {
        AdvocateOnboardingData.current.purposes =
            _selected.map((p) => _option(p).label).toList();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PracticeLocationScreen(
              advocateType: widget.advocateType,
            ),
          ),
        );
      },
      children: [
        const Text(
          'STEP 2 OF 5',
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
          'What will you use\nADVOK for?',
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
          'Select your primary purpose. You can pick multiple.',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.15,
            color: AppColors.textGrey555,
          ),
        ),
        const SizedBox(height: 24),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _card(AdvokPurpose.findClients)),
              const SizedBox(width: 12),
              Expanded(child: _card(AdvokPurpose.manageCases)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _card(AdvokPurpose.scheduleHearings)),
              const SizedBox(width: 12),
              Expanded(child: _card(AdvokPurpose.onlineConsultation)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _card(AdvokPurpose.documentManagement)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 12),
        _card(AdvokPurpose.everything),
      ],
    );
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PurposeOption option;
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
          padding: const EdgeInsets.all(17),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.white.withValues(alpha: 0.15)
                          : AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        option.icon,
                        width: 20,
                        height: 20,
                        colorFilter: selected
                            ? const ColorFilter.mode(
                                AppColors.white,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
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
                option.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 19.5 / 13,
                  letterSpacing: -0.08,
                  color: selected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
