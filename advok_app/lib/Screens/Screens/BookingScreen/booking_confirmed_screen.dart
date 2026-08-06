import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../AppNavigation/client_nav_screen.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/Responsive/responsive.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({
    super.key,
    required this.advocateName,
    required this.date,
    required this.time,
    required this.type,
    required this.amount,
  });

  final String advocateName;
  final String date;
  final String time;
  final String type;
  final String amount;

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadge(context),
                  const SizedBox(height: 28),
                  const Text(
                    'Booking Confirmed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 32 / 24,
                      letterSpacing: 0.07,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your appointment with $advocateName has been '
                    'scheduled. A confirmation has been sent to your email.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 22.75 / 14,
                      letterSpacing: -0.15,
                      color: AppColors.textGrey555,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildDetailsCard(),
                  const SizedBox(height: 28),
                  _buildPrimaryButton(context),
                  const SizedBox(height: 12),
                  _buildSecondaryButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      width: context.rs(110),
      height: context.rs(110),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2A2A2A).withValues(alpha: 0.21),
          width: 1.4,
        ),
      ),
      child: Center(
        child: Container(
          width: context.rs(80),
          height: context.rs(80),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A).withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/ic_check_circle_dark.svg',
              width: 44,
              height: 44,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 0.7),
      ),
      child: Column(
        children: [
          _buildDetailRow('Date', date),
          _buildDetailRow('Time', time),
          _buildDetailRow('Type', type),
          _buildDetailRow('Amount Paid', amount, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool showDivider = true}) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.7),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
          Text(
            value,
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
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
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
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ClientNavScreen()),
              (route) => false,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_home_white.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.31,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.progressTrack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey, width: 0.7),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // TODO: Open the booking in the device calendar.
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_calendar_dark.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'View in Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.31,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
