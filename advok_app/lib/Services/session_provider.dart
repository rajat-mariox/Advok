import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// App-wide session state (Provider layer).
///
/// [Session] stays the storage layer — it holds the token/user and mirrors
/// them to disk. This ChangeNotifier sits on top so widgets can
/// `context.watch<SessionProvider>()` and rebuild automatically whenever the
/// logged-in user changes: login, role selection, profile edits, approval
/// status updates and logout all bump [Session.revision].
class SessionProvider extends ChangeNotifier {
  SessionProvider() {
    Session.revision.addListener(notifyListeners);
  }

  bool get isLoggedIn => Session.isLoggedIn;
  String? get role => Session.role;
  String? get status => Session.status;
  Map<String, dynamic>? get user => Session.user;
  Map<String, dynamic>? get profile => Session.profile;
  String? get photo => Session.photo;
  String? get country => Session.country;
  String get displayName => Session.displayName;
  String get displayContact => Session.displayContact;
  String get roleLabel => Session.roleLabel;

  /// Clears the saved login; listening screens rebuild in logged-out state.
  void logout() => Session.clear();

  @override
  void dispose() {
    Session.revision.removeListener(notifyListeners);
    super.dispose();
  }
}
