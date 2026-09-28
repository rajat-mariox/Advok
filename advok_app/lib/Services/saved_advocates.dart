import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// The attorneys the signed-in user saved with the heart. One shared set so
/// the attorney profile heart, the profile count and the saved list stay in
/// sync without reloading each other.
class SavedAdvocates {
  SavedAdvocates._();

  static final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});
  static String? _loadedFor;

  static bool isSaved(String id) => ids.value.contains(id);

  /// Loads the saved ids once per signed-in user (cheap to call again).
  static Future<void> ensureLoaded() async {
    final user = Session.userId;
    if (user == null || _loadedFor == user) return;
    await refresh();
  }

  /// Full saved attorneys (cards) from the backend; also refreshes [ids].
  static Future<List<Map<String, dynamic>>> refresh() async {
    final list = await ApiService.fetchSavedAdvocates();
    ids.value = {for (final a in list) a['id'] as String};
    _loadedFor = Session.userId;
    return list;
  }

  /// Flips the heart. Updates the UI first, rolls back if the call fails.
  static Future<void> toggle(String id) async {
    if (id.isEmpty) return;
    final wasSaved = isSaved(id);
    ids.value = _with(id, !wasSaved);
    try {
      final result = wasSaved
          ? await ApiService.unsaveAdvocate(id)
          : await ApiService.saveAdvocate(id);
      ids.value = result.toSet();
    } catch (_) {
      ids.value = _with(id, wasSaved);
      rethrow;
    }
  }

  static Set<String> _with(String id, bool saved) {
    final next = {...ids.value};
    if (saved) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return next;
  }

  /// Forget everything (logout).
  static void clear() {
    ids.value = <String>{};
    _loadedFor = null;
  }
}
