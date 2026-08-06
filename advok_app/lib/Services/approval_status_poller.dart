import 'dart:async';

import 'api_service.dart';

/// Polls the backend while a registration is pending so the UI can unlock
/// itself the moment the admin approves (or show the rejection reason).
class ApprovalStatusPoller {
  ApprovalStatusPoller({required this.onChanged});

  /// Called with the latest status ('pending_approval' / 'approved' /
  /// 'rejected') and, when rejected, the admin's reason.
  final void Function(String status, String? rejectionReason) onChanged;

  Timer? _timer;

  void start() {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    try {
      final result = await ApiService.fetchStatus();
      final status = result['status'] as String? ?? 'pending_approval';
      if (status == 'approved' || status == 'rejected') {
        stop();
        if (status == 'approved') {
          // Pull the submitted profile into the session for the dashboard.
          await ApiService.fetchMe();
        }
      }
      onChanged(status, result['rejectionReason'] as String?);
    } catch (_) {
      // Backend unreachable — keep the current state, retry on the next tick.
    }
  }
}
