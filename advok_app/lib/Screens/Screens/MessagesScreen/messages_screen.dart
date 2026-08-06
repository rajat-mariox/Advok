import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 28 / 20,
                  letterSpacing: -0.45,
                  color: AppColors.textPrimary,
                ),
              ),
              Material(
                color: AppColors.fillGrey,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    // TODO: Start a new conversation.
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/ic_compose.svg',
                        width: 15,
                        height: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.fillGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_search.svg',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        letterSpacing: -0.15,
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [_buildEmptyState()],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.fillGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_compose.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your conversations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey555,
            ),
          ),
        ],
      ),
    );
  }
}
