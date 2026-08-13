import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../Screens/Screens/AdvocateListScreen/advocate_list_screen.dart';
import '../Screens/Screens/BookingsScreen/bookings_screen.dart';
import '../Screens/Screens/HomeScreen/client_home_screen.dart';
import '../Screens/Screens/MessagesScreen/messages_screen.dart';
import '../Screens/Screens/ProfileScreen/profile_screen.dart';
import '../Utils/AppColors/app_colors.dart';
import '../Utils/CountryData/country_catalog.dart';

/// Bottom-navigation shell for the client flow.
class ClientNavScreen extends StatefulWidget {
  const ClientNavScreen({super.key});

  @override
  State<ClientNavScreen> createState() => _ClientNavScreenState();
}

class _ClientNavScreenState extends State<ClientNavScreen> {
  int _index = 0;

  static const List<({String icon, String label})> _items = [
    (icon: 'assets/icons/ic_nav_home.svg', label: 'Home'),
    (icon: 'assets/icons/ic_nav_search.svg', label: 'Search'),
    (icon: 'assets/icons/ic_nav_messages.svg', label: 'Messages'),
    (icon: 'assets/icons/ic_nav_bookings.svg', label: 'Bookings'),
    (icon: 'assets/icons/ic_nav_profile.svg', label: 'Profile'),
  ];

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
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              ClientHomeScreen(
                onProfileTap: () => setState(() => _index = 4),
              ),
              AdvocateListScreen(
                title: 'Find ${CountryCatalog.terms.lawyerPlural}',
                onBack: () => setState(() => _index = 0),
              ),
              const MessagesScreen(),
              BookingsScreen(onBack: () => setState(() => _index = 0)),
              const ProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  for (int i = 0; i < _items.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _index = i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _index == i
                                    ? AppColors.textPrimary
                                        .withValues(alpha: 0.13)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  _items[i].icon,
                                  width: 21,
                                  height: 21,
                                  colorFilter: ColorFilter.mode(
                                    _index == i
                                        ? AppColors.textPrimary
                                        : AppColors.textGrey,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _items[i].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                letterSpacing: 0.12,
                                color: _index == i
                                    ? AppColors.textPrimary
                                    : AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
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
