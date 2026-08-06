import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Utils/AppColors/app_colors.dart';

/// Circular grey back button used on the onboarding screens.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? () => Navigator.of(context).pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/ic_arrow_back.svg',
              width: 16,
              height: 16,
            ),
          ),
        ),
      ),
    );
  }
}
