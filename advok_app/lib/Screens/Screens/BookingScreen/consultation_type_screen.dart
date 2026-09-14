import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';
import 'select_datetime_screen.dart';

class ConsultationType {
  const ConsultationType({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final String icon;
  final String title;
  final String subtitle;
  final String price;
}

/// Fallback fee when the pricing settings can't be loaded — same default the
/// backend seeds. The live value comes from the admin panel.
const Map<String, double> _defaultPricing = {'phone_call': 90};

String _priceLabel(double amount) => amount == amount.roundToDouble()
    ? '\$${amount.toStringAsFixed(0)}'
    : '\$${amount.toStringAsFixed(2)}';

/// Clients consult by voice only — video calls and office visits are not
/// offered on the platform.
/// [providerFee] wins when the provider carries its own rate (law firms and
/// their attorneys); otherwise the platform attorney rate applies.
List<ConsultationType> _buildTypes(
  Map<String, double> pricing, [
  double? providerFee,
]) =>
    [
      ConsultationType(
        icon: 'assets/icons/ic_phone.svg',
        title: 'Phone Call',
        subtitle: 'Voice consultation',
        price: _priceLabel(providerFee ?? pricing['phone_call'] ?? 90),
      ),
    ];

class ConsultationTypeScreen extends StatefulWidget {
  const ConsultationTypeScreen({super.key, required this.advocate});

  final Advocate advocate;

  @override
  State<ConsultationTypeScreen> createState() => _ConsultationTypeScreenState();
}

class _ConsultationTypeScreenState extends State<ConsultationTypeScreen> {
  int _selected = 0;

  /// Fees set from the admin panel; defaults until the fetch answers.
  late List<ConsultationType> _types =
      _buildTypes(_defaultPricing, widget.advocate.consultationFee);

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    try {
      final pricing = await ApiService.fetchConsultationPricing();
      if (!mounted) return;
      setState(
        () => _types = _buildTypes(pricing, widget.advocate.consultationFee),
      );
    } catch (_) {
      // Backend unreachable — the default fees stay.
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? AppColors.textPrimary
                                : AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'Step 1 of 3',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const Text(
                      'How would you like to consult?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 28 / 20,
                        letterSpacing: -0.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose your preferred consultation format',
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (int i = 0; i < _types.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _TypeCard(
                        type: _types[i],
                        selected: _selected == i,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildContinueButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        children: const [
          CircleBackButton(),
          Text(
            'Consultation Type',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectDateTimeScreen(
                    advocate: widget.advocate,
                    consultationType: _types[_selected],
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continue',
                  style: TextStyle(
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
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ConsultationType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.textPrimary.withValues(alpha: 0.06)
          : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.textPrimary.withValues(alpha: 0.13)
                      : AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(type.icon, width: 24, height: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: -0.08,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    type.price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      letterSpacing: -0.31,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/ic_check.svg',
                          width: 11,
                          height: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
