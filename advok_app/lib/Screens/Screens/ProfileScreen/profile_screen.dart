import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../ChooseRoleScreen/choose_role_screen.dart';
import '../../SelectCountryScreen/select_country_screen.dart';
import '../../../CommonWidgets/profile_sheets.dart';
import 'help_support_screen.dart';

/// Profile tab of the client flow.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _location = '';
  final String _about = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              _buildProfileCard(),
              _buildSectionLabel('About'),
              _buildSectionCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _about.isEmpty ? 'Add a short bio…' : _about,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 22.75 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textGrey555,
                      ),
                    ),
                  ),
                ],
              ),
              _buildSectionLabel('My Information'),
              _buildSectionCard(
                children: [
                  const ProfileInfoRow(
                    icon: 'assets/icons/ic_award.svg',
                    label: 'Total Consultations',
                    value: '0 sessions',
                  ),
                  _buildInsetDivider(),
                  const ProfileInfoRow(
                    icon: 'assets/icons/ic_file.svg',
                    label: 'Active Cases',
                    value: '0 ongoing',
                  ),
                  _buildInsetDivider(),
                  const ProfileInfoRow(
                    icon: 'assets/icons/ic_bookmark.svg',
                    label: 'Saved Advocates',
                    value: '0 favorites',
                  ),
                ],
              ),
              _buildSectionLabel('Preferences'),
              _buildSectionCard(
                children: [
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_bell.svg',
                    title: 'Notifications',
                    subtitle: 'Push & email enabled',
                    trailing: _buildToggle(),
                    onTap: () => setState(
                      () => _notificationsEnabled = !_notificationsEnabled,
                    ),
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_pin.svg',
                    iconColor: AppColors.textPrimary,
                    title: 'Change Location',
                    subtitle: _location.isEmpty ? 'Not set' : _location,
                    onTap: _openLocationSheet,
                  ),
                ],
              ),
              _buildSectionLabel('Support & Information'),
              _buildSectionCard(
                children: [
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_star_outline.svg',
                    title: 'Rate This App',
                    subtitle: 'Love ADVOK? Share your feedback',
                    onTap: _openRateSheet,
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_share.svg',
                    iconColor: AppColors.textPrimary,
                    title: 'Share App',
                    subtitle: 'Invite friends to ADVOK',
                    onTap: _openShareSheet,
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_help.svg',
                    title: 'Help & Support',
                    subtitle: 'Contact our team',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_lock.svg',
                    title: 'Privacy Policy',
                    onTap: _openPrivacySheet,
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_file.svg',
                    title: 'Terms & Conditions',
                    onTap: _openTermsSheet,
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_info.svg',
                    title: 'About App',
                    subtitle: 'ADVOK v2.1.0',
                    onTap: _openAboutSheet,
                  ),
                ],
              ),
              _buildSectionLabel('Account'),
              _buildSectionCard(
                children: [
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_switch_role.svg',
                    title: 'Switch User Type',
                    subtitle: 'Currently: Client',
                    onTap: _openSwitchRoleSheet,
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_logout.svg',
                    iconBackground: const Color(
                      0xFF1A1A1A,
                    ).withValues(alpha: 0.07),
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: _openLogoutSheet,
                  ),
                  _buildInsetDivider(),
                  ProfileMenuRow(
                    icon: 'assets/icons/ic_trash.svg',
                    iconBackground: const Color(
                      0xFF1A1A1A,
                    ).withValues(alpha: 0.07),
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your data',
                    onTap: _openDeleteAccountSheet,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openDeleteAccountSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      backgroundColor: Colors.transparent,
      builder: (context) => const DeleteAccountSheet(),
    );
  }

  Future<void> _openSwitchRoleSheet() async {
    final selectedRole = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const RolePickerSheet(currentRoleIndex: 0),
    );
    // Staying on the current role needs no further action.
    if (selectedRole == null || selectedRole == 0 || !mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
      (route) => false,
    );
  }

  Future<void> _openAboutSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const AboutSheet(),
    );
  }

  Future<void> _openShareSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const ShareSheet(),
    );
  }

  Future<void> _openRateSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const RateSheet(),
    );
  }

  Future<void> _openPrivacySheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const CmsContentSheet(
        slug: 'privacy-policy',
        fallback: ContentSheet(
          title: 'Privacy Policy',
        sections: [
          (
            title: '1. Information We Collect',
            body:
                'We collect information you provide directly to us, such '
                'as when you create an account, fill in a form, make a '
                'booking, send us a message, or otherwise communicate '
                'with us.',
          ),
          (
            title: '2. How We Use Your Information',
            body:
                'We use the information we collect to operate and improve '
                'our services, process bookings, send you technical notices '
                'and support messages, respond to comments, and monitor '
                'usage.',
          ),
          (
            title: '3. Information Sharing',
            body:
                'We do not sell your personal data. We may share your '
                'information with service providers who assist us in '
                'operating the platform.',
          ),
          (
            title: '4. Data Security',
            body:
                'We take reasonable measures to help protect information '
                'about you from loss, theft, misuse, unauthorized access, '
                'disclosure, alteration, and destruction.',
          ),
          (
            title: '5. Your Rights',
            body:
                'You have the right to access, update, or delete your '
                'personal information at any time from your profile '
                'settings.',
          ),
          (
            title: '6. Contact',
            body:
                'If you have any questions about this Privacy Policy, '
                'please contact us at privacy@advok.app.',
          ),
        ],
          lastUpdated: 'Last updated: January 1, 2025',
        ),
      ),
    );
  }

  Future<void> _openTermsSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const CmsContentSheet(
        slug: 'terms-and-conditions',
        fallback: ContentSheet(
          title: 'Terms & Conditions',
        sections: [
          (
            title: '1. Acceptance of Terms',
            body:
                'By accessing or using ADVOK, you agree to be bound by '
                'these Terms and our Privacy Policy.',
          ),
          (
            title: '2. Use of Services',
            body:
                'ADVOK provides a platform connecting clients with legal '
                'professionals. We are not a law firm and do not provide '
                'legal advice.',
          ),
          (
            title: '3. User Accounts',
            body:
                'You are responsible for maintaining the confidentiality '
                'of your account credentials.',
          ),
          (
            title: '4. Advocate Verification',
            body:
                'All advocates listed on ADVOK are independently verified '
                'against Bar Council records.',
          ),
          (
            title: '5. Payment & Refunds',
            body:
                'Consultation fees are charged at the rates listed by '
                'each advocate. Refunds are available within 24 hours of '
                'booking if cancelled before the consultation begins.',
          ),
          (
            title: '6. Prohibited Conduct',
            body:
                'You may not use ADVOK for any unlawful purpose or to '
                'harass advocates or other users.',
          ),
          (
            title: '7. Governing Law',
            body:
                'These Terms shall be governed by the laws of the State '
                'of New York.',
          ),
        ],
          lastUpdated: 'Effective: January 1, 2025',
        ),
      ),
    );
  }

  Future<void> _openLogoutSheet() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const LogoutSheet(),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SelectCountryScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _openLocationSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSheet(),
    );
    if (selected != null && mounted) {
      setState(() => _location = selected);
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 33 / 22,
              letterSpacing: -0.26,
              color: AppColors.textPrimary,
            ),
          ),
          Material(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // TODO: Open the edit profile screen.
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGrey, width: 0.7),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_edit.svg',
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey, width: 0.7),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Session.displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 21.25 / 17,
                          letterSpacing: -0.43,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Session.displayContact,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.textGrey555,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.progressTrack,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.borderGrey,
                                width: 0.7,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 6,
                                  height: 6,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: AppColors.textPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Session.roleLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                    letterSpacing: 0.06,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.progressTrack,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/ic_pin.svg',
                                  width: 10,
                                  height: 10,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.textGrey555,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _location.isEmpty ? 'Not set' : _location,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                    letterSpacing: 0.12,
                                    color: AppColors.textGrey555,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('0', 'Consultations'),
              const SizedBox(width: 8),
              _buildStatCard('0', 'Active Cases'),
              const SizedBox(width: 8),
              _buildStatCard('0', 'Saved'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey, width: 1.4),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_user.svg',
                width: 26,
                height: 26,
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              onTap: () {
                // TODO: Change the profile photo.
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.4),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_camera.svg',
                    width: 11,
                    height: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey, width: 0.7),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 27 / 18,
                letterSpacing: -0.44,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: 0.12,
                color: AppColors.textGrey555,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.5,
          letterSpacing: 1.12,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 0.7),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInsetDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _notificationsEnabled
            ? AppColors.textPrimary
            : AppColors.borderGrey,
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: _notificationsEnabled
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x4D000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
