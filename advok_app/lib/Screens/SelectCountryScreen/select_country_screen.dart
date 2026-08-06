import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../Utils/AppColors/app_colors.dart';
import '../LoginScreen/login_screen.dart';

class Country {
  const Country({required this.flag, required this.name, required this.dialCode});

  final String flag;
  final String name;
  final String dialCode;
}

const List<Country> _popularCountries = [
  Country(flag: '🇺🇸', name: 'United States', dialCode: '+1'),
  Country(flag: '🇬🇧', name: 'United Kingdom', dialCode: '+44'),
  Country(flag: '🇨🇦', name: 'Canada', dialCode: '+1'),
  Country(flag: '🇦🇺', name: 'Australia', dialCode: '+61'),
];

const List<Country> _allCountries = [
  Country(flag: '🇮🇳', name: 'India', dialCode: '+91'),
  Country(flag: '🇩🇪', name: 'Germany', dialCode: '+49'),
  Country(flag: '🇫🇷', name: 'France', dialCode: '+33'),
  Country(flag: '🇦🇪', name: 'UAE', dialCode: '+971'),
  Country(flag: '🇸🇬', name: 'Singapore', dialCode: '+65'),
  Country(flag: '🇵🇰', name: 'Pakistan', dialCode: '+92'),
  Country(flag: '🇳🇬', name: 'Nigeria', dialCode: '+234'),
  Country(flag: '🇿🇦', name: 'South Africa', dialCode: '+27'),
  Country(flag: '🇧🇷', name: 'Brazil', dialCode: '+55'),
  Country(flag: '🇲🇽', name: 'Mexico', dialCode: '+52'),
  Country(flag: '🇯🇵', name: 'Japan', dialCode: '+81'),
  Country(flag: '🇰🇷', name: 'South Korea', dialCode: '+82'),
];

class SelectCountryScreen extends StatefulWidget {
  const SelectCountryScreen({super.key});

  @override
  State<SelectCountryScreen> createState() => _SelectCountryScreenState();
}

class _SelectCountryScreenState extends State<SelectCountryScreen> {
  String _query = '';
  Country? _selected;

  List<Country> _filter(List<Country> countries) {
    if (_query.isEmpty) return countries;
    final query = _query.toLowerCase();
    return countries
        .where((c) =>
            c.name.toLowerCase().contains(query) || c.dialCode.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final popular = _filter(_popularCountries);
    final all = _filter(_allCountries);

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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    if (popular.isNotEmpty) ...[
                      const _SectionLabel('Popular'),
                      const SizedBox(height: 12),
                      for (int i = 0; i < popular.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _CountryTile(
                          country: popular[i],
                          selected: _selected == popular[i],
                          onTap: () => setState(() => _selected = popular[i]),
                        ),
                      ],
                    ],
                    if (all.isNotEmpty) ...[
                      if (popular.isNotEmpty) const SizedBox(height: 16),
                      const _SectionLabel('All Countries'),
                      const SizedBox(height: 12),
                      for (int i = 0; i < all.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _CountryTile(
                          country: all[i],
                          selected: _selected == all[i],
                          onTap: () => setState(() => _selected = all[i]),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.19),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_scales.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STEP 1 OF 3',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: 3.06,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.81,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
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
          const SizedBox(height: 20),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_search.svg',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search country or code...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final enabled = _selected != null;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          if (enabled) ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.19),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _selected!.flag,
                    style: const TextStyle(fontSize: 20, height: 1.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selected!.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _selected!.dialCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Opacity(
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
                    onTap: enabled
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LoginScreen(country: _selected!),
                              ),
                            );
                          }
                        : null,
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
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.5,
        letterSpacing: 1.12,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.textPrimary.withValues(alpha: 0.07)
          : AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderGrey,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                country.flag,
                style: const TextStyle(fontSize: 24, height: 1),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  country.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                country.dialCode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.43,
                  letterSpacing: -0.15,
                  color:
                      selected ? AppColors.textPrimary : AppColors.textGrey,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 16),
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
        ),
      ),
    );
  }
}
