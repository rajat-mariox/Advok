import 'package:flutter/material.dart';

import '../Utils/AppColors/app_colors.dart';

/// "Or login with" divider followed by the Google / Apple buttons,
/// shared by the login and OTP screens.
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({
    super.key,
    this.onGoogleTap,
    this.onAppleTap,
  });

  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;

  @override
  Widget build(BuildContext context) {
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
                onTap: onGoogleTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/ic_apple.png',
                label: 'Apple',
                onTap: onAppleTap,
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
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.blueGray300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, width: 20, height: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: AppColors.blueGray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
