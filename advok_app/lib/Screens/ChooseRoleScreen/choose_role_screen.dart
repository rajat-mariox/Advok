import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../AppNavigation/client_nav_screen.dart';
import '../../Services/api_service.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/Responsive/responsive.dart';
import '../AdvocateRegistration/advocate_registration_models.dart';
import '../AdvocateRegistration/describe_yourself_screen.dart';
import '../LawFirmRegistration/register_firm_screen.dart';
import '../LawStudentRegistration/student_verification_screen.dart';

enum UserRole { client, advocate, lawStudent, lawFirm }

const Map<UserRole, String> _apiRoles = {
  UserRole.client: 'client',
  UserRole.advocate: 'advocate',
  UserRole.lawStudent: 'law_student',
  UserRole.lawFirm: 'law_firm',
};

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  UserRole? _selected;
  bool _submitting = false;

  Future<void> _continue() async {
    final role = _selected!;
    setState(() => _submitting = true);
    try {
      await ApiService.selectRole(_apiRoles[role]!);
      if (!mounted) return;
      switch (role) {
        case UserRole.advocate:
          AdvocateOnboardingData.current.reset();
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(
                name: DescribeYourselfScreen.routeName,
              ),
              builder: (_) => const DescribeYourselfScreen(),
            ),
          );
        case UserRole.lawStudent:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StudentVerificationScreen(),
            ),
          );
        case UserRole.lawFirm:
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(
                name: RegisterFirmScreen.routeName,
              ),
              builder: (_) => const RegisterFirmScreen(),
            ),
          );
        case UserRole.client:
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ClientNavScreen()),
            (route) => false,
          );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/bg_pattern.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          const Text(
                            'WELCOME TO ADVOK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 3.06,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Choose your role',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 35.2 / 24,
                              letterSpacing: -0.59,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Select how you will use the platform. You can switch anytime.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              letterSpacing: -0.15,
                              color: AppColors.textGrey555,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTrustBanner(),
                          const SizedBox(height: 20),
                          _buildRoleGrid(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: _buildContinueButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: context.rs(130),
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/img_law_library.jpg',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xBF000000), Color(0x33000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Trusted by',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 24 / 16,
                      letterSpacing: -0.31,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '50,000+ Americans',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 28 / 20,
                      letterSpacing: -0.45,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lawyers · Clients · Students · Firms',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: Color(0xFFDDDDDD),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _RoleCard(
                  icon: 'assets/icons/ic_role_client.svg',
                  badgeColor: const Color(0x21333333),
                  title: 'Client',
                  subtitle: 'Find & consult lawyers',
                  selected: _selected == UserRole.client,
                  onTap: () => setState(() => _selected = UserRole.client),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleCard(
                  icon: 'assets/icons/ic_role_advocate.svg',
                  badgeColor: const Color(0x210A0A0A),
                  title: 'Advocate',
                  subtitle: 'Manage cases & clients',
                  selected: _selected == UserRole.advocate,
                  onTap: () => setState(() => _selected = UserRole.advocate),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _RoleCard(
                  icon: 'assets/icons/ic_role_student.svg',
                  badgeColor: const Color(0x21444444),
                  title: 'Law Student',
                  subtitle: 'Learn & connect',
                  selected: _selected == UserRole.lawStudent,
                  onTap: () => setState(() => _selected = UserRole.lawStudent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleCard(
                  icon: 'assets/icons/ic_role_firm.svg',
                  badgeColor: const Color(0x21333333),
                  title: 'Law Firm',
                  subtitle: 'Run your practice',
                  selected: _selected == UserRole.lawFirm,
                  onTap: () => setState(() => _selected = UserRole.lawFirm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final enabled = _selected != null && !_submitting;
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
              onTap: enabled ? _continue : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _submitting ? 'Please wait…' : 'Continue',
                    style: const TextStyle(
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
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
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
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: SvgPicture.asset(icon, width: 22, height: 22),
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/ic_check.svg',
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            AppColors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
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
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 12,
                  color: AppColors.textGrey555,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
