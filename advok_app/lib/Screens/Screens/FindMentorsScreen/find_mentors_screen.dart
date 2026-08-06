import 'package:flutter/material.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../MessagesScreen/chat_screen.dart';
import 'request_mentorship_screen.dart';

/// Mentors are loaded from the backend; empty until then.
const List<
  ({
    String name,
    String subtitle,
    String mentees,
    String cases,
    String image,
    bool open,
  })
>
_mentors = [];

/// "Advocates" tab of the student flow — mentor discovery list.
class FindMentorsScreen extends StatefulWidget {
  const FindMentorsScreen({super.key, this.onBack});

  /// Called by the header back button; the nav shell uses it to switch
  /// back to the Home tab.
  final VoidCallback? onBack;

  @override
  State<FindMentorsScreen> createState() => _FindMentorsScreenState();
}

class _FindMentorsScreenState extends State<FindMentorsScreen> {
  final Set<String> _requested = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 16),
              if (_mentors.isEmpty)
                _buildEmptyState()
              else
                for (final mentor in _mentors) ...[
                  _buildMentorCard(mentor),
                  const SizedBox(height: 14),
                ],
            ],
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
            child: const Center(
              child: Icon(
                Icons.people_outline,
                size: 26,
                color: AppColors.textGrey555,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No mentors yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mentors will appear here once advocates open\n'
            'their mentorship slots.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          CircleBackButton(onTap: widget.onBack),
          const Expanded(
            child: Text(
              'Find Mentors',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 24 / 17,
                letterSpacing: -0.34,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Balances the back button so the title stays centered.
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 15,
            color: AppColors.textGrey555,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Connect with experienced advocates who are willing to guide '
              'law students. Request a mentorship session or shadow their '
              'casework.',
              style: TextStyle(
                fontSize: 13,
                height: 19.5 / 13,
                letterSpacing: -0.08,
                color: AppColors.textGrey555,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(
    ({
      String name,
      String subtitle,
      String mentees,
      String cases,
      String image,
      bool open,
    })
    mentor,
  ) {
    final requested = _requested.contains(mentor.name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  mentor.image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            mentor.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 22 / 15,
                              letterSpacing: -0.23,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusPill(mentor.open),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mentor.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        letterSpacing: -0.08,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          mentor.mentees,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: AppColors.textGrey555,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          mentor.cases,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: AppColors.textGrey555,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (mentor.open) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Message',
                    filled: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            name: mentor.name,
                            image: mentor.image,
                            online: true,
                            specialty: mentor.subtitle.split(' · ').first,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: requested ? 'Requested ✓' : 'Request Mentorship',
                    filled: true,
                    dark: requested,
                    onTap: () async {
                      if (requested) {
                        setState(() => _requested.remove(mentor.name));
                        return;
                      }
                      final sent = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => RequestMentorshipScreen(
                            mentorName: mentor.name,
                            mentorSpecialty: mentor.subtitle.split(' · ').first,
                            mentorImage: mentor.image,
                          ),
                        ),
                      );
                      if (sent == true && mounted) {
                        setState(() => _requested.add(mentor.name));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool open) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: open ? AppColors.borderGrey : AppColors.progressTrack,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        open ? 'Open' : 'Full',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 16 / 11,
          letterSpacing: -0.08,
          color: open ? AppColors.textPrimary : AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
    bool dark = false,
  }) {
    final Color background = dark
        ? AppColors.textPrimary
        : filled
        ? AppColors.borderGrey
        : AppColors.progressTrack;
    final Color textColor = dark ? AppColors.white : AppColors.textPrimary;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: filled && !dark
                ? Border.all(color: const Color(0xFFC9C9C9))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
                height: 18 / 13,
                letterSpacing: -0.08,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
