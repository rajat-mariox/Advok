import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Screens/Screens/FirmCasesScreen/firm_cases_screen.dart';
import '../Screens/Screens/FirmDashboardScreen/firm_dashboard_screen.dart';
import '../Screens/Screens/FirmLawyersScreen/firm_lawyers_screen.dart';
import '../Screens/Screens/FirmProfileScreen/firm_profile_screen.dart';
import '../Screens/Screens/MessagesScreen/messages_screen.dart';
import '../Utils/AppColors/app_colors.dart';

/// Bottom-navigation shell for the law-firm flow.
class FirmNavScreen extends StatefulWidget {
  const FirmNavScreen({super.key});

  @override
  State<FirmNavScreen> createState() => _FirmNavScreenState();
}

class _FirmNavScreenState extends State<FirmNavScreen> {
  int _index = 0;

  static const List<({String icon, String label})> _items = [
    (icon: 'assets/icons/ic_nav_home.svg', label: 'Home'),
    (icon: 'assets/icons/ic_purpose_clients.svg', label: 'Lawyers'),
    (icon: 'assets/icons/ic_nav_messages.svg', label: 'Messages'),
    (icon: 'assets/icons/ic_file.svg', label: 'Cases'),
    (icon: 'assets/icons/ic_role_firm.svg', label: 'Firm'),
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
              FirmDashboardScreen(
                onFirmTap: () => setState(() => _index = 4),
              ),
              FirmLawyersScreen(
                onBack: () => setState(() => _index = 0),
                onViewCases: () => setState(() => _index = 3),
              ),
              const MessagesScreen(),
              FirmCasesScreen(onBack: () => setState(() => _index = 0)),
              const FirmProfileScreen(),
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
