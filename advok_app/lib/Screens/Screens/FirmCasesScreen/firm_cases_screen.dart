import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../FirmDashboardScreen/firm_case_details_screen.dart';
import '../FirmDashboardScreen/firm_dashboard_screen.dart';

const List<FirmCase> _allCases = [];

/// Full case list for the firm's bottom-nav Cases tab.
class FirmCasesScreen extends StatefulWidget {
  const FirmCasesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<FirmCasesScreen> createState() => _FirmCasesScreenState();
}

class _FirmCasesScreenState extends State<FirmCasesScreen> {
  int _filter = 0;

  static const List<String> _filters = [
    'All',
    'Active',
    'Hearing',
    'Discovery',
    'Closed',
  ];

  @override
  Widget build(BuildContext context) {
    final filter = _filters[_filter];
    final visibleCases = filter == 'All'
        ? _allCases
        : _allCases.where((c) => c.status == filter).toList();
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (int i = 0; i < _filters.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Material(
                  color: _filter == i
                      ? AppColors.textPrimary
                      : AppColors.fillGrey,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _filter = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _filter == i
                              ? AppColors.textPrimary
                              : AppColors.borderGrey,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 16 / 12,
                          color: _filter == i
                              ? AppColors.white
                              : AppColors.textGrey555,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: visibleCases.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [_buildEmptyState()],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: visibleCases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, index) {
                    final firmCase = visibleCases[index];
                    return _CaseCard(
                      firmCase: firmCase,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FirmCaseDetailsScreen(caseData: firmCase),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.fillGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_office.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No cases yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Firm cases will appear here once case tracking goes live.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
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
          CircleBackButton(onTap: widget.onBack),
          const Expanded(
            child: Text(
              'All Cases',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 24 / 17,
                letterSpacing: -0.34,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // TODO: Open the new-case form once it's designed.
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_plus.svg',
                    width: 14,
                    height: 14,
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

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.firmCase, this.onTap});

  final FirmCase firmCase;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      firmCase.number,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 1.2,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.progressTrack,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      firmCase.status,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                firmCase.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_user.svg',
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textGrey,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    firmCase.client,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  const SizedBox(width: 14),
                  SvgPicture.asset(
                    'assets/icons/ic_office.svg',
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textGrey,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    firmCase.lawyer,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_calendar_dark.svg',
                      width: 12,
                      height: 12,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filed ${firmCase.filed}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
