import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Optional override: flutter run --dart-define=ADVOK_API_URL=http://...:4000/api
const String _envApiUrl = String.fromEnvironment('ADVOK_API_URL');

/// If your computer's WiFi IP changes, update this (check with `ipconfig`).
const String _devMachineLanIp = '192.168.68.105';

/// Backend URLs tried in order on first use, so a plain `flutter run` works
/// everywhere without flags:
/// - localhost   -> desktop/web, and USB phones after `adb reverse tcp:4000 tcp:4000`
/// - 10.0.2.2    -> Android emulator
/// - LAN IP      -> physical phone on the same WiFi as this computer
List<String> get _candidateUrls {
  if (_envApiUrl.isNotEmpty) return [_envApiUrl];
  if (!kIsWeb && Platform.isAndroid) {
    return [
      'http://localhost:4000/api',
      'http://10.0.2.2:4000/api',
      'http://$_devMachineLanIp:4000/api',
    ];
  }
  return ['http://localhost:4000/api'];
}

/// In-memory auth session for the current app run.
class Session {
  Session._();

  static String? token;
  static Map<String, dynamic>? user;

  static String? get role => user?['role'] as String?;
  static String? get status => user?['status'] as String?;
  static bool get isLoggedIn => token != null;

  /// The onboarding data this user submitted (null until submitted).
  static Map<String, dynamic>? get profile =>
      user?['profile'] as Map<String, dynamic>?;

  static String get _phoneDisplay {
    final phone = user?['phone'] as String?;
    if (phone == null) return '';
    final cc = user?['countryCode'] as String? ?? '';
    return '$cc $phone'.trim();
  }

  /// Name shown in headers/profile, taken from the onboarding data.
  static String get displayName {
    final p = profile;
    switch (role) {
      case 'advocate':
        return (p?['professional']?['fullName'] as String?) ?? 'Advocate';
      case 'law_student':
        return (p?['fullName'] as String?) ?? 'Law Student';
      case 'law_firm':
        return (p?['firmName'] as String?) ?? 'Law Firm';
      default:
        return _phoneDisplay.isEmpty ? 'Client' : _phoneDisplay;
    }
  }

  /// Email (or phone as fallback) shown on profile cards.
  static String get displayContact {
    final p = profile;
    final email = switch (role) {
      'advocate' => p?['professional']?['email'] as String?,
      'law_firm' => p?['officialEmail'] as String?,
      _ => null,
    };
    if (email != null && email.isNotEmpty) return email;
    return _phoneDisplay.isEmpty ? '—' : _phoneDisplay;
  }

  static String get roleLabel {
    switch (role) {
      case 'advocate':
        return profile?['advocateType'] == 'senior'
            ? 'Senior Advocate'
            : 'Junior Advocate';
      case 'law_student':
        return 'Law Student';
      case 'law_firm':
        return 'Law Firm';
      default:
        return 'Client';
    }
  }

  static void clear() {
    token = null;
    user = null;
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static String? _resolvedBaseUrl;

  /// Probes /health on each candidate URL and remembers the first one that
  /// answers, so the app finds the backend on its own.
  static Future<String> _baseUrl() async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    for (final base in _candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$base/health'))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = base;
          return base;
        }
      } catch (_) {
        // Unreachable — try the next candidate.
      }
    }
    // Nothing answered; let the actual request surface the error. Not cached,
    // so the probe runs again once the backend is up.
    return _candidateUrls.first;
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${await _baseUrl()}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
    };
    http.Response response;
    try {
      if (method == 'GET') {
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 12));
      } else {
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 12));
      }
    } catch (_) {
      throw ApiException(
        'Could not reach the ADVOK server. Check your connection.',
      );
    }
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response.');
    }
    if (response.statusCode >= 400) {
      throw ApiException(data['error'] as String? ?? 'Something went wrong.');
    }
    return data;
  }

  /// Returns the dev OTP (shown in-app because no SMS gateway is wired yet).
  static Future<String?> sendOtp(String phone, String countryCode) async {
    final data = await _request('POST', '/auth/send-otp', body: {
      'phone': phone,
      'countryCode': countryCode,
    });
    return data['devOtp'] as String?;
  }

  static Future<void> verifyOtp(String phone, String otp) async {
    final data = await _request('POST', '/auth/verify-otp', body: {
      'phone': phone,
      'otp': otp,
    });
    Session.token = data['token'] as String?;
    Session.user = data['user'] as Map<String, dynamic>?;
  }

  static Future<void> selectRole(String role) async {
    final data = await _request('POST', '/auth/select-role', body: {
      'role': role,
    });
    Session.user = data['user'] as Map<String, dynamic>?;
  }

  /// Refreshes [Session.user] (role, status and submitted profile).
  static Future<void> fetchMe() async {
    final data = await _request('GET', '/auth/me');
    Session.user = data['user'] as Map<String, dynamic>?;
  }

  static Future<void> submitAdvocateOnboarding(
    Map<String, dynamic> payload,
  ) async {
    await _request('POST', '/onboarding/advocate', body: payload);
    await fetchMe();
  }

  static Future<void> submitStudentOnboarding(
    Map<String, dynamic> payload,
  ) async {
    await _request('POST', '/onboarding/law-student', body: payload);
    await fetchMe();
  }

  static Future<void> submitFirmOnboarding(
    Map<String, dynamic> payload,
  ) async {
    await _request('POST', '/onboarding/law-firm', body: payload);
    await fetchMe();
  }

  /// Current approval status: onboarding_required / pending_approval /
  /// approved / rejected (with the admin's reason).
  static Future<Map<String, dynamic>> fetchStatus() {
    return _request('GET', '/onboarding/status');
  }

  /// App page content (Terms, Privacy, ...) managed from the admin panel.
  static Future<Map<String, dynamic>> fetchCmsPage(String slug) async {
    final data = await _request('GET', '/cms/$slug');
    return data['page'] as Map<String, dynamic>;
  }
}
