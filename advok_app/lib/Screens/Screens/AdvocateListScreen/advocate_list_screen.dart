import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateProfileScreen/advocate_profile_screen.dart';

class Advocate {
  const Advocate({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.cases,
    required this.location,
    required this.price,
    required this.availability,
    required this.image,
    this.rating,
  });

  final String name;
  final String specialty;
  final String experience;
  final String cases;
  final String location;
  final String price;
  final String availability;
  final String image;
  final String? rating;
}

const List<Advocate> _advocates = [];

class AdvocateListScreen extends StatefulWidget {
  const AdvocateListScreen({super.key, required this.title, this.onBack});

  final String title;

  /// Overrides the default back behaviour (popping the route). Used when the
  /// screen is embedded as the Search tab.
  final VoidCallback? onBack;

  @override
  State<AdvocateListScreen> createState() => _AdvocateListScreenState();
}

class _AdvocateListScreenState extends State<AdvocateListScreen> {
  static const List<String> _filters = ['All', 'Junior', 'Senior', 'Available Now'];

  int _selectedFilter = 0;

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildFilterChips(),
                    const SizedBox(height: 12),
                    if (_advocates.isEmpty)
                      _buildEmptyState()
                    else ...[
                      Text(
                        'Showing ${_advocates.length} advocates near you',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < _advocates.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _AdvocateListCard(advocate: _advocates[i]),
                      ],
                    ],
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
        children: [
          CircleBackButton(onTap: widget.onBack),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                // TODO: Open the filters sheet.
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
                    'assets/icons/ic_filter.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_search.svg', width: 16, height: 16),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search advocates...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  letterSpacing: -0.15,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
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
                'assets/icons/ic_search.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No advocates yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Advocates will appear here once verified advocates join the platform.',
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.textPrimary : AppColors.fillGrey,
                borderRadius: BorderRadius.circular(100),
                border: selected
                    ? null
                    : Border.all(color: AppColors.borderGrey),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 16 / 12,
                    color: selected ? AppColors.white : AppColors.textGrey555,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdvocateListCard extends StatelessWidget {
  const _AdvocateListCard({required this.advocate});

  final Advocate advocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              advocate.image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                advocate.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                  letterSpacing: -0.08,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.fillGrey,
                                    width: 1.4,
                                  ),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/ic_check.svg',
                                    width: 10,
                                    height: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            advocate.specialty,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: AppColors.textGrey555,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Toggle favourite.
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SvgPicture.asset(
                          'assets/icons/ic_heart.svg',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (advocate.rating != null) ...[
                      SvgPicture.asset(
                        'assets/icons/ic_star.svg',
                        width: 11,
                        height: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        advocate.rating!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 16 / 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const _DotSeparator(),
                    ],
                    Text(advocate.experience, style: _metaStyle),
                    const _DotSeparator(),
                    Text(advocate.cases, style: _metaStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_pin.svg',
                      width: 10,
                      height: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(advocate.location, style: _metaStyle),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: advocate.price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.5,
                              letterSpacing: -0.31,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(
                            text: '/hr ',
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          TextSpan(
                            text: advocate.availability,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16 / 12,
                              color: Color(0xFF2A2A2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AdvocateProfileScreen(advocate: advocate),
                          ),
                        );
                      },
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.textPrimary,
                              AppColors.gradientDarkEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 16 / 12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    color: AppColors.textGrey555,
  );
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 10,
          height: 1.5,
          letterSpacing: 0.12,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}
