import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Services/saved_advocates.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../../../Utils/CountryData/country_catalog.dart';
import '../AdvocateListScreen/advocate_list_screen.dart' show Advocate;
import '../AdvocateProfileScreen/advocate_profile_screen.dart';

/// Attorneys the user saved with the heart on an attorney's profile.
class SavedAdvocatesScreen extends StatefulWidget {
  const SavedAdvocatesScreen({super.key});

  @override
  State<SavedAdvocatesScreen> createState() => _SavedAdvocatesScreenState();
}

class _SavedAdvocatesScreenState extends State<SavedAdvocatesScreen> {
  List<Advocate> _all = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await SavedAdvocates.refresh();
      if (!mounted) return;
      setState(() {
        _all = list.map(Advocate.fromApi).toList();
        _error = '';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _unsave(Advocate a) async {
    try {
      await SavedAdvocates.toggle(a.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plural = CountryCatalog.terms.lawyerPlural;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    const CircleBackButton(),
                    const SizedBox(width: 12),
                    Text(
                      'Saved $plural',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 26 / 20,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    // Unsaving here hides the card right away, no reload.
                    : ValueListenableBuilder<Set<String>>(
                        valueListenable: SavedAdvocates.ids,
                        builder: (context, ids, _) {
                          final visible =
                              _all.where((a) => ids.contains(a.id)).toList();
                          return RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                              children: [
                                if (visible.isEmpty)
                                  _empty(plural)
                                else
                                  for (final a in visible)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _SavedCard(
                                        advocate: a,
                                        onOpen: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AdvocateProfileScreen(advocate: a),
                                          ),
                                        ),
                                        onUnsave: () => _unsave(a),
                                      ),
                                    ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String plural) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.fillGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 28, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved ${plural.toLowerCase()} yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error.isNotEmpty
                ? _error
                : 'Tap the heart on a profile to keep it here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.advocate,
    required this.onOpen,
    required this.onUnsave,
  });

  final Advocate advocate;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final a = advocate;
    final initial = a.name.trim().isEmpty ? '?' : a.name.trim()[0].toUpperCase();
    final subtitle = [a.specialty, a.location].where((s) => s.trim().isNotEmpty).join(' · ');
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.white,
                  child: a.photoBytes != null
                      ? Image.memory(a.photoBytes!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 22 / 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, height: 18 / 12.5, color: AppColors.textGrey555),
                      ),
                    if (a.experience.trim().isNotEmpty)
                      Text(
                        a.experience,
                        style: const TextStyle(fontSize: 11.5, height: 16 / 11.5, color: AppColors.textGrey),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from saved',
                onPressed: onUnsave,
                icon: const Icon(Icons.favorite, color: AppColors.textPrimary),
              ),
              SvgPicture.asset('assets/icons/ic_chevron_right_grey.svg', width: 14, height: 14),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
