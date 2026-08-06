import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../CommonWidgets/circle_back_button.dart';
import '../../CommonWidgets/social_login_section.dart';
import '../../Services/api_service.dart';
import '../../Services/post_login_navigator.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../../Utils/Responsive/responsive.dart';
import '../SelectCountryScreen/select_country_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.country,
    required this.phoneNumber,
    this.devOtp,
  });

  final Country country;
  final String phoneNumber;

  /// Prototype helper — the backend returns the OTP because no SMS
  /// gateway is connected yet. Shown on screen for easy testing.
  final String? devOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _resendTimer;
  int _secondsLeft = _resendSeconds;
  bool _verifying = false;
  String? _devOtp;
  String? _error;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _otpController.addListener(_onOtpChanged);
    _focusNode.addListener(() => setState(() {}));
    _startResendTimer();
  }

  void _onOtpChanged() {
    setState(() {});
    if (_otp.length == _otpLength && !_verifying) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ApiService.verifyOtp(widget.phoneNumber, _otp);
      if (!mounted) return;
      // Routes by account state: new user -> choose role, onboarding not
      // finished -> registration flow, pending -> status screen, approved ->
      // dashboard, rejected -> rejection screen with the admin's reason.
      PostLoginNavigator.navigateAfterLogin(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _otpController.clear();
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    _startResendTimer();
    try {
      final devOtp = await ApiService.sendOtp(
        widget.phoneNumber,
        widget.country.dialCode,
      );
      if (!mounted) return;
      setState(() {
        _devOtp = devOtp;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _otpController.text;

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleBackButton(),
                const SizedBox(height: 20),
                const Text(
                  'STEP 3 OF 3',
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
                  'Verify your number',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 35 / 24,
                    letterSpacing: -0.32,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Enter the 6-digit code sent to ',
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textGrey555,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${widget.country.dialCode} ${widget.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                          letterSpacing: -0.15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
                _buildOtpBoxes(),
                const SizedBox(height: 24),
                _buildDots(),
                if (_devOtp != null) ...[
                  const SizedBox(height: 16),
                  _buildDevOtpHint(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 32),
                _buildStatusBar(),
                const SizedBox(height: 24),
                _buildChangeNumber(),
                SizedBox(height: context.hp(0.10)),
                SocialLoginSection(
                  onGoogleTap: () {
                    // TODO: Google sign-in.
                  },
                  onAppleTap: () {
                    // TODO: Apple sign-in.
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _otpLength; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Flexible(
                child: _OtpBox(
                  digit: i < _otp.length ? _otp[i] : '',
                  active: _focusNode.hasFocus &&
                      (i == _otp.length ||
                          (i == _otpLength - 1 && _otp.length == _otpLength)),
                ),
              ),
            ],
          ],
        ),
        // Invisible input capturing the OTP digits.
        Positioned.fill(
          child: TextField(
            controller: _otpController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: _otpLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(
              color: Colors.transparent,
              fontSize: 1,
              height: 1,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              filled: false,
            ),
            cursorColor: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _otpLength; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: i < _otp.length
                  ? AppColors.textPrimary
                  : AppColors.progressTrack,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDevOtpHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Test mode — your OTP is ',
              style: TextStyle(
                fontSize: 12,
                height: 19.5 / 12,
                color: AppColors.textGrey555,
              ),
            ),
            TextSpan(
              text: _devOtp,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 19.5 / 13,
                letterSpacing: 2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x14DC3545),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 19.5 / 12.5,
          color: Color(0xFFC92A3A),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final canResend = _secondsLeft == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.textGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${_otp.length}/$_otpLength digits entered',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: AppColors.textGrey555,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: canResend ? _resendOtp : null,
            child: Text(
              canResend ? 'Resend' : 'Resend in ${_secondsLeft}s',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
                letterSpacing: -0.15,
                color:
                    canResend ? AppColors.textPrimary : AppColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeNumber() {
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: "Didn't receive the code? ",
              style: TextStyle(
                fontSize: 12,
                height: 19.5 / 12,
                color: AppColors.textGrey,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text(
                  'Change number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: -0.31,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.digit, required this.active});

  final String digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active || digit.isNotEmpty
              ? AppColors.textPrimary
              : AppColors.borderGrey,
          width: 1.4,
        ),
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
