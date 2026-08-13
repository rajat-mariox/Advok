import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Services/api_service.dart';
import '../Utils/AppColors/app_colors.dart';

/// Header avatar showing the logged-in user's profile photo from the
/// session, falling back to a placeholder icon when no photo is set.
/// Used at the top corner of the home/dashboard screens.
class SessionAvatar extends StatelessWidget {
  const SessionAvatar({
    super.key,
    this.size = 40,
    this.borderRadius,
    this.fallbackIcon = 'assets/icons/ic_user.svg',
    this.onTap,
  });

  final double size;

  /// null → circle (like the client/student headers).
  final BorderRadius? borderRadius;
  final String fallbackIcon;
  final VoidCallback? onTap;

  Uint8List? get _photoBytes {
    final photo = Session.photo;
    if (photo == null || photo.isEmpty) return null;
    final comma = photo.indexOf(',');
    try {
      return base64Decode(comma >= 0 ? photo.substring(comma + 1) : photo);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _photoBytes;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.fillGrey,
          shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.borderGrey, width: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Center(
                child: SvgPicture.asset(
                  fallbackIcon,
                  width: size * 0.45,
                  height: size * 0.45,
                ),
              ),
      ),
    );
  }
}
