import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../Services/api_service.dart';
import '../Utils/AppColors/app_colors.dart';

/// "Or login with" divider followed by the Google / Apple buttons, shared by
/// the login and OTP screens.
///
/// The section owns the guard rails so screens don't have to: one sign-in at
/// a time (extra taps are ignored while a flow runs), a button that can't
/// work is shown disabled with the reason instead of erroring on every tap
/// (Google before the backend has a client ID; Apple on Android), and the
/// backend's sign-in config is fetched once per app run.
class SocialLoginSection extends StatefulWidget {
  const SocialLoginSection({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
  });

  final Future<void> Function()? onGoogleTap;
  final Future<void> Function()? onAppleTap;

  @override
  State<SocialLoginSection> createState() => _SocialLoginSectionState();
}

class _SocialLoginSectionState extends State<SocialLoginSection> {
  /// Cached across screens for the app run; null until fetched.
  static bool? _googleAvailable;
  static bool? _appleAvailable;

  String? _busy; // 'google' | 'apple'

  bool get _isApplePlatform => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (_googleAvailable == null) _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ApiService.fetchAuthConfig();
      final google = config['google'] as Map<String, dynamic>? ?? const {};
      final apple = config['apple'] as Map<String, dynamic>? ?? const {};
      _googleAvailable = google['enabled'] == true;
      _appleAvailable = apple['enabled'] != false;
    } catch (_) {
      // Backend unreachable: leave the buttons enabled; the tap will explain.
      _googleAvailable = true;
      _appleAvailable = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _run(String which, Future<void> Function()? action) async {
    if (action == null || _busy != null) return;
    setState(() => _busy = which);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleOff = _googleAvailable == false;
    final appleOff = !_isApplePlatform || _appleAvailable == false;
    final googleNote = googleOff ? 'Not set up yet' : null;
    final appleNote = !_isApplePlatform
        ? 'iPhone only'
        : _appleAvailable == false
            ? 'Not set up yet'
            : null;
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: Divider(color: AppColors.blueGray300)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Or login with',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: AppColors.blueGray500,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.blueGray300)),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/ic_google.png',
                label: 'Google',
                note: googleNote,
                busy: _busy == 'google',
                enabled: !googleOff && _busy == null,
                onTap: () => _run('google', widget.onGoogleTap),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/ic_apple.png',
                label: 'Apple',
                note: appleNote,
                busy: _busy == 'apple',
                enabled: !appleOff && _busy == null,
                onTap: () => _run('apple', widget.onAppleTap),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
    required this.busy,
    this.note,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool busy;

  /// Small reason under the label when the button is disabled.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled || busy ? 1 : 0.5,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.blueGray300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Image.asset(icon, width: 20, height: 20),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busy ? 'Signing in…' : label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        color: AppColors.blueGray500,
                      ),
                    ),
                    if (note != null && !busy)
                      Text(
                        note!,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
