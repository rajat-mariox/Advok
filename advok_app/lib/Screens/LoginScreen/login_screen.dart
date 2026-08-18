import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../CommonWidgets/circle_back_button.dart';
import '../../CommonWidgets/phone_number_limit_formatter.dart';
import '../../CommonWidgets/social_login_section.dart';
import '../../Services/api_service.dart';
import '../../Services/apple_auth_service.dart';
import '../../Services/google_auth_service.dart';
import '../../Services/post_login_navigator.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/CountryData/country_catalog.dart';
import '../OtpScreen/otp_screen.dart';
import '../SelectCountryScreen/select_country_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.country});

  final Country country;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _sending = false;
  late final CountryProfile _countryProfile;

  @override
  void initState() {
    super.initState();
    // Remember the chosen country so address forms later in onboarding can
    // show its states/provinces.
    CountryCatalog.select(widget.country.name);
    _countryProfile = CountryCatalog.selected;
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _phoneValid => _countryProfile.isValidPhone(_phoneController.text);

  bool get _showPhoneError =>
      _phoneController.text.trim().isNotEmpty && !_phoneValid;

  bool get _canSendOtp => _phoneValid && !_sending;

  Future<void> _googleSignIn() async {
    try {
      final loggedIn =
          await GoogleAuthService.signIn(country: widget.country.name);
      if (!loggedIn || !mounted) return;
      PostLoginNavigator.navigateAfterLogin(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _appleSignIn() async {
    try {
      final loggedIn =
          await AppleAuthService.signIn(country: widget.country.name);
      if (!loggedIn || !mounted) return;
      PostLoginNavigator.navigateAfterLogin(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    setState(() => _sending = true);
    try {
      final devOtp = await ApiService.sendOtp(
        phone,
        widget.country.dialCode,
        country: widget.country.name,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            country: widget.country,
            phoneNumber: phone,
            devOtp: devOtp,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleBackButton(),
                const SizedBox(height: 20),
                const Text(
                  'STEP 2 OF 3',
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
                  'Enter your mobile number',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 35 / 24,
                    letterSpacing: -0.32,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "We'll send a verification code to confirm your identity.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textGrey555,
                  ),
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
                            color: i < 2
                                ? AppColors.textPrimary
                                : AppColors.progressTrack,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                _buildCountryCodeButton(),
                const SizedBox(height: 16),
                _buildPhoneField(),
                if (_showPhoneError) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Enter a valid ${widget.country.name} number '
                    '(${_countryProfile.phoneLengthHint}).',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                      color: Color(0xFFC92A3A),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildTermsText(),
                const SizedBox(height: 32),
                Row(
                  children: const [
                    Expanded(
                      child: _TrustBadge(
                        icon: 'assets/icons/ic_shield.svg',
                        title: 'Secure',
                        subtitle: '256-bit SSL',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _TrustBadge(
                        icon: 'assets/icons/ic_lock.svg',
                        title: 'Private',
                        subtitle: 'No spam ever',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _TrustBadge(
                        icon: 'assets/icons/ic_verified.svg',
                        title: 'Verified',
                        subtitle: 'Bar verified',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSendOtpButton(),
                const SizedBox(height: 24),
                SocialLoginSection(
                  onGoogleTap: _googleSignIn,
                  onAppleTap: _appleSignIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCodeButton() {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.country.flag,
                style: const TextStyle(fontSize: 18, height: 28 / 18),
              ),
              const SizedBox(width: 10),
              Text(
                widget.country.dialCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              SvgPicture.asset(
                'assets/icons/ic_chevron_down.svg',
                width: 14,
                height: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    final filled = _phoneController.text.isNotEmpty;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: filled ? AppColors.textPrimary : AppColors.borderGrey,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/ic_phone.svg', width: 18, height: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s()\-]')),
                PhoneNumberLimitFormatter(_countryProfile.maxDigits),
              ],
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Enter a phone number',
                hintStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          if (filled) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _phoneController.clear,
              child: SvgPicture.asset(
                'assets/icons/ic_clear.svg',
                width: 16,
                height: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    const greyStyle = TextStyle(
      fontSize: 12,
      height: 19.5 / 12,
      color: AppColors.textGrey,
    );
    const blackStyle = TextStyle(
      fontSize: 12,
      height: 19.5 / 12,
      color: AppColors.textPrimary,
    );
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: "By continuing, you agree to ADVOK's ", style: greyStyle),
          TextSpan(text: 'Terms of Service', style: blackStyle),
          TextSpan(text: ' and ', style: greyStyle),
          TextSpan(text: 'Privacy Policy', style: blackStyle),
          TextSpan(text: '.', style: greyStyle),
        ],
      ),
    );
  }

  Widget _buildSendOtpButton() {
    final enabled = _canSendOtp;
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
              onTap: enabled ? _sendOtp : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _sending ? 'Sending…' : 'Send OTP',
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

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          SvgPicture.asset(icon, width: 18, height: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.5,
              letterSpacing: 0.06,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              height: 1.5,
              letterSpacing: 0.17,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
