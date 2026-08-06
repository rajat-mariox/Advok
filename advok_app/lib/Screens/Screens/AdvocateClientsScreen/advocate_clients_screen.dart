import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateCasesScreen/advocate_cases_screen.dart'
    show CaseBadge, advocateCases;
import '../AdvocateCasesScreen/case_details_screen.dart';
import 'client_directory.dart';

class AdvocateClientsScreen extends StatefulWidget {
  const AdvocateClientsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AdvocateClientsScreen> createState() => _AdvocateClientsScreenState();
}

class _AdvocateClientsScreenState extends State<AdvocateClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdvocateClient> _filter(List<AdvocateClient> clients) {
    if (_query.isEmpty) return clients;
    final query = _query.toLowerCase();
    return clients
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.matter.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchField(),
        Expanded(
          child: ListenableBuilder(
            listenable: ClientDirectory.instance,
            builder: (context, _) {
              final clients = _filter(ClientDirectory.instance.clients);
              if (clients.isEmpty) {
                if (_query.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'No clients found',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [_buildEmptyState()],
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  for (int i = 0; i < clients.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _ClientCard(client: clients[i]),
                  ],
                ],
              );
            },
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
                'assets/icons/ic_user.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No clients yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Clients will appear here once you accept client requests.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textGrey555),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 13),
      child: Row(
        children: [
          Material(
            color: AppColors.fillGrey,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onBack,
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
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Clients',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 22.5 / 15,
                  letterSpacing: -0.23,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: -0.15,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search clients...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    letterSpacing: -0.15,
                    color: AppColors.textGrey,
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

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});

  final AdvocateClient client;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final matches =
              advocateCases.where((c) => c.title == client.matter).toList();
          if (matches.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseDetailsScreen(caseData: matches.first),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGrey, width: 1.4),
                ),
                child: ClipOval(
                  child: Image.asset(client.avatar, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            client.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 19.5 / 13,
                              letterSpacing: -0.08,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        CaseBadge(
                          label: client.status.label,
                          color: client.status.badgeColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.matter,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: AppColors.textGrey555,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Joined ${client.joined}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: 0.06,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${client.sessions} session${client.sessions == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: 0.06,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
