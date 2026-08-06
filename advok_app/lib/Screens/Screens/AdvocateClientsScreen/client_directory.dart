import 'package:flutter/material.dart';

enum ClientStatus { active, upcoming, completed }

extension ClientStatusLabel on ClientStatus {
  String get label => switch (this) {
    ClientStatus.active => 'Active',
    ClientStatus.upcoming => 'Upcoming',
    ClientStatus.completed => 'Completed',
  };

  Color get badgeColor => switch (this) {
    ClientStatus.active => const Color(0xFF2A2A2A),
    ClientStatus.upcoming => const Color(0xFF555555),
    ClientStatus.completed => const Color(0xFF999999),
  };
}

class AdvocateClient {
  const AdvocateClient({
    required this.name,
    required this.avatar,
    required this.matter,
    required this.status,
    required this.joined,
    required this.sessions,
  });

  final String name;
  final String avatar;
  final String matter;
  final ClientStatus status;
  final String joined;
  final int sessions;
}

/// In-memory client list shared between the advocate dashboard (accepting
/// requests) and the Clients tab. Replace with the API-backed source once
/// request handling has a backend.
class ClientDirectory extends ChangeNotifier {
  ClientDirectory._();

  static final ClientDirectory instance = ClientDirectory._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Starts empty; populated when the advocate accepts client requests.
  final List<AdvocateClient> _clients = [];

  List<AdvocateClient> get clients => List.unmodifiable(_clients);

  AdvocateClient? findByName(String name) {
    for (final client in _clients) {
      if (client.name == name) return client;
    }
    return null;
  }

  /// Adds an accepted request as a client at the top of the list. If a
  /// client with the same name already exists it is replaced so the newly
  /// accepted matter shows up instead of a duplicate entry.
  void addFromAcceptedRequest({
    required String name,
    required String avatar,
    required String matter,
  }) {
    _clients.removeWhere((c) => c.name == name);
    final now = DateTime.now();
    _clients.insert(
      0,
      AdvocateClient(
        name: name,
        avatar: avatar,
        matter: matter,
        status: ClientStatus.active,
        joined: '${_months[now.month - 1]} ${now.day}',
        sessions: 0,
      ),
    );
    notifyListeners();
  }
}
