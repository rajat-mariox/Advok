import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/CountryData/country_catalog.dart';
import 'realtime_service.dart';

/// Optional override: flutter run --dart-define=ADVOK_API_URL=http://...:4000/api
const String _envApiUrl = String.fromEnvironment('ADVOK_API_URL');

/// LAN IP of the computer running the backend. Phone/emulator must be on the
/// same WiFi. If the IP changes, update this (check with `ipconfig`).
const String _devMachineLanIp = '192.168.1.34';
const int _backendPort = 4000;

/// Backend URL (LAN only — no localhost / 10.0.2.2 fallbacks).
List<String> get _candidateUrls {
  if (_envApiUrl.isNotEmpty) return [_envApiUrl];
  return ['http://$_devMachineLanIp:$_backendPort/api'];
}

/// Auth session for the current app run, mirrored to local storage so a
/// login survives the app being closed (the backend token lasts 30 days).
class Session {
  Session._();

  static const _tokenKey = 'advok_session_token';
  static const _userKey = 'advok_session_user';

  static String? _token;
  static Map<String, dynamic>? _user;

  /// Bumped on every session change (login, profile update, logout,
  /// restore) so state listeners — see SessionProvider — can rebuild UI.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static String? get token => _token;
  static set token(String? value) {
    _token = value;
    _persist();
  }

  static Map<String, dynamic>? get user => _user;
  static set user(Map<String, dynamic>? value) {
    _user = value;
    _persist();
  }

  /// Loads the last saved login from disk (called once on app start).
  /// Returns false when there is no usable saved session.
  static Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    final savedUser = prefs.getString(_userKey);
    if (savedToken == null || savedUser == null) return false;
    try {
      _user = jsonDecode(savedUser) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }
    _token = savedToken;
    // Restore the (India/US) experience of this account even before the
    // backend is reached.
    final savedCountry = country;
    if (savedCountry != null && savedCountry.isNotEmpty) {
      CountryCatalog.select(savedCountry);
    }
    revision.value++;
    return true;
  }

  /// Fire-and-forget disk write — login flows shouldn't block on storage.
  static void _persist() {
    revision.value++;
    SharedPreferences.getInstance().then((prefs) {
      if (_token == null || _user == null) {
        prefs.remove(_tokenKey);
        prefs.remove(_userKey);
      } else {
        prefs.setString(_tokenKey, _token!);
        prefs.setString(_userKey, jsonEncode(_user));
      }
    });
  }

  static String? get userId => user?['id'] as String?;

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

  /// The country this account registered with (falls back to the country
  /// picked on the Select Country screen this session).
  static String? get country => user?['country'] as String?;

  /// Advocate profile photo as a base64 data URL (null if not set).
  static String? get photo => profile?['photo'] as String?;

  /// Name shown in headers/profile, taken from the onboarding data.
  static String get displayName {
    final p = profile;
    switch (role) {
      case 'advocate':
        return (p?['professional']?['fullName'] as String?) ??
            CountryCatalog.terms.lawyerSingular;
      case 'law_student':
        return (p?['fullName'] as String?) ?? 'Law Student';
      case 'law_firm':
        return (p?['firmName'] as String?) ?? 'Law Firm';
      default:
        // Clients can set a display name from Edit Profile.
        final name = p?['fullName'] as String?;
        if (name != null && name.isNotEmpty) return name;
        return _phoneDisplay.isEmpty ? 'Client' : _phoneDisplay;
    }
  }

  /// Email (or phone as fallback) shown on profile cards.
  static String get displayContact {
    final p = profile;
    final email = switch (role) {
      'advocate' => p?['professional']?['email'] as String?,
      'law_firm' => p?['officialEmail'] as String?,
      'client' => p?['email'] as String?,
      _ => null,
    };
    if (email != null && email.isNotEmpty) return email;
    return _phoneDisplay.isEmpty ? '—' : _phoneDisplay;
  }

  static String get roleLabel {
    final firm = user?['firmName'] as String?;
    if (role == 'advocate' && firm != null && firm.trim().isNotEmpty) {
      return 'Attorney at ${firm.trim()}';
    }
    switch (role) {
      case 'advocate':
        // US profiles carry a firm role (Partner, Associate…); the tier
        // titles are the India-style fallback.
        final firmRole = profile?['firmRole'] as String?;
        if (firmRole != null && firmRole.isNotEmpty) return firmRole;
        return profile?['advocateType'] == 'senior'
            ? CountryCatalog.terms.seniorTitle
            : CountryCatalog.terms.juniorTitle;
      case 'law_student':
        return 'Law Student';
      case 'law_firm':
        return 'Law Firm';
      default:
        return 'Client';
    }
  }

  static void clear() {
    Realtime.instance.disconnect();
    _token = null;
    _user = null;
    _persist();
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;

  /// HTTP status of the failed response, or null when the server was
  /// unreachable (timeout / no connection).
  final int? statusCode;

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

  /// The backend base URL the app settled on (see [_baseUrl]).
  static Future<String> resolvedBaseUrl() => _baseUrl();

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${await _baseUrl()}$path');
    if (Session.token != null) Realtime.instance.ensureConnected();
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
      } else if (method == 'PUT') {
        response = await http
            .put(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 12));
      } else if (method == 'DELETE') {
        response = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 12));
      } else {
        // Document uploads can be large; give POSTs a longer window.
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 30));
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
      throw ApiException(
        data['error'] as String? ?? 'Something went wrong.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  /// Returns the dev OTP (shown in-app because no SMS gateway is wired yet).
  static Future<String?> sendOtp(
    String phone,
    String countryCode, {
    String? country,
  }) async {
    final data = await _request(
      'POST',
      '/auth/send-otp',
      body: {'phone': phone, 'countryCode': countryCode, 'country': ?country},
    );
    return data['devOtp'] as String?;
  }

  static Future<void> verifyOtp(String phone, String otp) async {
    final data = await _request(
      'POST',
      '/auth/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );
    Session.token = data['token'] as String?;
    Session.user = data['user'] as Map<String, dynamic>?;
    _syncCountry();
  }

  /// Logs in with a Google ID token (from Google Sign-In). The backend
  /// verifies the token, finds or creates the account and returns the same
  /// token/user payload as verify-otp.
  static Future<void> loginWithGoogle(String idToken, {String? country}) async {
    final data = await _request(
      'POST',
      '/auth/google',
      body: {'idToken': idToken, 'country': ?country},
    );
    Session.token = data['token'] as String?;
    Session.user = data['user'] as Map<String, dynamic>?;
    _syncCountry();
  }

  /// Logs in with an Apple identity token (from Sign in with Apple).
  /// [fullName] is only available on the very first Apple sign-in, so it is
  /// forwarded for the backend to store right away.
  static Future<void> loginWithApple(
    String identityToken, {
    String? fullName,
    String? country,
  }) async {
    final data = await _request(
      'POST',
      '/auth/apple',
      body: {
        'identityToken': identityToken,
        'fullName': ?fullName,
        'country': ?country,
      },
    );
    Session.token = data['token'] as String?;
    Session.user = data['user'] as Map<String, dynamic>?;
    _syncCountry();
  }

  /// Keeps the app's country flow in line with the country this account was
  /// created with, so a returning user gets the same (India/US) experience
  /// regardless of the tile tapped on the Select Country screen.
  static void _syncCountry() {
    final saved = Session.country;
    if (saved != null && saved.isNotEmpty) {
      CountryCatalog.select(saved);
    }
  }

  static Future<void> selectRole(String role) async {
    final data = await _request(
      'POST',
      '/auth/select-role',
      body: {'role': role},
    );
    Session.user = data['user'] as Map<String, dynamic>?;
  }

  /// Refreshes [Session.user] (role, status and submitted profile).
  static Future<void> fetchMe() async {
    final data = await _request('GET', '/auth/me');
    Session.user = data['user'] as Map<String, dynamic>?;
    _syncCountry();
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

  static Future<void> submitFirmOnboarding(Map<String, dynamic> payload) async {
    await _request('POST', '/onboarding/law-firm', body: payload);
    await fetchMe();
  }

  /// Current approval status: onboarding_required / pending_approval /
  /// approved / rejected (with the admin's reason).
  static Future<Map<String, dynamic>> fetchStatus() {
    return _request('GET', '/onboarding/status');
  }

  /// Verified advocates/attorneys in the user's country, for the client
  /// browse screens. The backend does the country filtering.
  static Future<List<Map<String, dynamic>>> fetchAdvocates() async {
    final data = await _request('GET', '/advocates');
    final list = data['advocates'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Curated "Cases to Read" for law students (published ones only), in
  /// the order the admin set. Cards only — no opinion text.
  static Future<List<Map<String, dynamic>>> fetchCaseStudies() async {
    final data = await _request('GET', '/learning/cases');
    final list = data['cases'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// US legal news for the student Legal News tab (SCOTUSblog, ABA Journal,
  /// Congress.gov), aggregated and cached by the backend.
  static Future<List<Map<String, dynamic>>> fetchLegalNews() async {
    final data = await _request('GET', '/learning/news');
    final list = data['news'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// One case with its syllabus and full opinion text (when available).
  static Future<Map<String, dynamic>> fetchCaseStudy(String id) async {
    final data = await _request('GET', '/learning/cases/$id');
    return (data['case'] as Map<String, dynamic>?) ?? {};
  }

  /// Law student's legal queries (Legal Queries tab), newest first. Each has
  /// `id, category, question, status (pending|answered), response?,
  /// responderName?, createdAt, answeredAt?`.
  static Future<List<Map<String, dynamic>>> fetchLegalQueries() async {
    final data = await _request('GET', '/queries');
    final list = data['queries'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Submits a legal question; the ADVOK team answers from the admin panel
  /// and the student is notified. Returns the created query.
  static Future<Map<String, dynamic>> createLegalQuery({
    required String category,
    required String question,
  }) async {
    final data = await _request(
      'POST',
      '/queries',
      body: {'category': category, 'question': question},
    );
    return (data['query'] as Map<String, dynamic>?) ?? {};
  }

  /// Structured IRAC study notes for a published case. Generated by ADVOK AI
  /// on the first request (a few seconds) and cached on the backend after.
  static Future<Map<String, dynamic>> generateCaseNotes(String caseId) async {
    final data = await _request('POST', '/learning/cases/$caseId/notes');
    return (data['notes'] as Map<String, dynamic>?) ?? {};
  }

  /// Legal Dictionary search / browse. Returns `{ terms: [...], total }`.
  /// With an empty [query] and a [letter], browses that letter A–Z.
  static Future<Map<String, dynamic>> searchDictionary(
    String query, {
    String? letter,
    int limit = 40,
    int offset = 0,
  }) async {
    final params = <String, String>{
      if (query.isNotEmpty) 'q': query,
      if (letter != null && letter.isNotEmpty) 'letter': letter,
      'limit': '$limit',
      'offset': '$offset',
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return _request('GET', '/learning/dictionary?$qs');
  }

  /// Initial letters that have dictionary entries, for the A–Z strip.
  static Future<List<String>> fetchDictionaryLetters() async {
    final data = await _request('GET', '/learning/dictionary/letters');
    final list = data['letters'] as List<dynamic>? ?? [];
    return list
        .cast<Map<String, dynamic>>()
        .map((l) => l['letter'] as String? ?? '')
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// One dictionary entry with its definition and any cached explanation.
  static Future<Map<String, dynamic>> fetchDictionaryTerm(String slug) async {
    final data = await _request(
      'GET',
      '/learning/dictionary/${Uri.encodeComponent(slug)}',
    );
    return (data['term'] as Map<String, dynamic>?) ?? {};
  }

  /// Plain-English explanation of a term by ADVOK AI (cached on the
  /// backend). Pass [slug] for a dictionary entry, or just [term] for a word
  /// the dictionary lacks. Returns the updated term.
  static Future<Map<String, dynamic>> explainLegalTerm({
    String? slug,
    String? term,
    bool regenerate = false,
  }) async {
    final data = await _request(
      'POST',
      '/learning/dictionary/explain',
      body: {
        if (slug != null && slug.isNotEmpty) 'slug': slug,
        if (term != null && term.isNotEmpty) 'term': term,
        if (regenerate) 'regenerate': true,
      },
    );
    return (data['term'] as Map<String, dynamic>?) ?? {};
  }

  /// ADVOK AI: whether the assistant is wired to a model on the backend.
  static Future<bool> fetchAiStatus() async {
    final data = await _request('GET', '/ai/status');
    return data['connected'] == true;
  }

  /// Active suggested prompts for the empty ADVOK AI chat screen, managed
  /// from the admin panel.
  static Future<List<String>> fetchAiSuggestions() async {
    final data = await _request('GET', '/ai/suggestions');
    final list = data['suggestions'] as List<dynamic>? ?? [];
    return list.whereType<String>().toList();
  }

  /// ADVOK AI chat turn. [messages] is the conversation so far as
  /// {role: 'user'|'assistant', content} maps, ending with the user's new
  /// question. Returns the assistant's reply text.
  static Future<String> aiChat(List<Map<String, String>> messages) async {
    final data = await _request('POST', '/ai/chat', body: {'messages': messages});
    return (data['reply'] as String?)?.trim() ?? '';
  }

  /// Verified law firms in the user's country, for the client home "Law
  /// Firms" section and its See-all list. Country-scoped by the backend.
  static Future<List<Map<String, dynamic>>> fetchLawFirms() async {
    final data = await _request('GET', '/law-firms');
    final list = data['lawFirms'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Books a consultation with an advocate. Every request starts 'pending'
  /// and waits for the advocate to accept. Returns the created booking.
  static Future<Map<String, dynamic>> createBooking({
    required String advocateId,
    required String consultationType,
    required String date,
    required String time,
    required double amount,
    int durationMinutes = 60,
  }) async {
    final data = await _request(
      'POST',
      '/bookings',
      body: {
        'advocateId': advocateId,
        'consultationType': consultationType,
        'date': date,
        'time': time,
        'amount': amount,
        'durationMinutes': durationMinutes,
      },
    );
    return data['booking'] as Map<String, dynamic>;
  }

  /// The user's bookings — a client sees the ones they made, an advocate the
  /// ones made with them. Newest first.
  static Future<List<Map<String, dynamic>>> fetchBookings() async {
    final data = await _request('GET', '/bookings');
    final list = data['bookings'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// Advocate accepts or declines a pending consultation request. Accepting
  /// creates the client relationship and shares contact details.
  static Future<void> respondToBooking(
    String bookingId, {
    required bool accept,
    /// Law firms pass the index of the team attorney handling the
    /// consultation (required when the firm has listed attorneys).
    int? attorneyIndex,
  }) async {
    await _request(
      'POST',
      '/bookings/$bookingId/${accept ? 'accept' : 'decline'}',
      body: attorneyIndex == null ? null : {'attorneyIndex': attorneyIndex},
    );
  }

  /// Client cancels an upcoming booking.
  static Future<void> cancelBooking(String bookingId) async {
    await _request('POST', '/bookings/$bookingId/cancel');
  }

  /// Marks a confirmed consultation as held — the call happens directly by
  /// phone, so either side just closes the appointment.
  static Future<void> completeBooking(String bookingId) async {
    await _request('POST', '/bookings/$bookingId/complete');
  }

  /// The advocate's client directory: everyone whose consultation request
  /// they accepted. Newest relationship first.
  static Future<List<Map<String, dynamic>>> fetchClients() async {
    final data = await _request('GET', '/clients');
    final list = data['clients'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// The user's cases — an advocate sees the ones they manage, a client the
  /// ones opened for them. Most recently updated first.
  static Future<List<Map<String, dynamic>>> fetchCases() async {
    final data = await _request('GET', '/cases');
    final list = data['cases'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// One case with its full timeline.
  static Future<Map<String, dynamic>> fetchCase(String caseId) async {
    final data = await _request('GET', '/cases/$caseId');
    return data['case'] as Map<String, dynamic>;
  }

  /// Attorney opens a case for an existing Advok client (someone whose
  /// consultation they accepted). Returns the created case.
  static Future<Map<String, dynamic>> createCase({
    required String clientId,
    required String title,
    required String caseNumber,
    required String court,
    String? practiceArea,
    String? priority,
    String? filedDate,
    String? nextHearing,
    int? courtDocketId,
  }) async {
    final data = await _request(
      'POST',
      '/cases',
      body: {
        'clientId': clientId,
        'title': title,
        'caseNumber': caseNumber,
        'court': court,
        'courtDocketId': ?courtDocketId,
        if (practiceArea != null && practiceArea.isNotEmpty)
          'practiceArea': practiceArea,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        if (filedDate != null && filedDate.isNotEmpty) 'filedDate': filedDate,
        if (nextHearing != null && nextHearing.isNotEmpty)
          'nextHearing': nextHearing,
      },
    );
    return data['case'] as Map<String, dynamic>;
  }

  /// Attorney posts a case update: a timeline event and/or a status,
  /// priority or next-hearing change. Returns the updated case.
  static Future<Map<String, dynamic>> addCaseUpdate(
    String caseId, {
    String? title,
    String? description,
    String? date,
    String? status,
    String? priority,
    String? nextHearing,
  }) async {
    final data = await _request(
      'POST',
      '/cases/$caseId/updates',
      body: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (date != null && date.isNotEmpty) 'date': date,
        if (status != null && status.isNotEmpty) 'status': status,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        if (nextHearing != null && nextHearing.isNotEmpty)
          'nextHearing': nextHearing,
      },
    );
    return data['case'] as Map<String, dynamic>;
  }

  /// Attorney attaches a file to a case, as a base64 data URL. Returns the
  /// updated case.
  static Future<Map<String, dynamic>> addCaseDocument(
    String caseId, {
    required String name,
    required String fileDataUrl,
  }) async {
    final data = await _request('POST', '/cases/$caseId/documents', body: {
      'name': name,
      'file': fileDataUrl,
    });
    return data['case'] as Map<String, dynamic>;
  }

  /// Attorney asks the client for a document. The request lands in the chat
  /// thread as a card the client can upload against. Returns the updated
  /// case.
  static Future<Map<String, dynamic>> requestCaseDocument(
    String caseId, {
    required String name,
    String? note,
  }) async {
    final data =
        await _request('POST', '/cases/$caseId/document-requests', body: {
      'name': name,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return data['case'] as Map<String, dynamic>;
  }

  /// Client uploads the document their attorney requested, as a base64 data
  /// URL. Returns the updated case.
  static Future<Map<String, dynamic>> uploadRequestedCaseDocument(
    String caseId,
    String requestId, {
    required String name,
    required String fileDataUrl,
  }) async {
    final data = await _request(
      'POST',
      '/cases/$caseId/document-requests/$requestId/upload',
      body: {'name': name, 'file': fileDataUrl},
    );
    return data['case'] as Map<String, dynamic>;
  }

  /// Attorney removes a document from a case. Returns the updated case.
  static Future<Map<String, dynamic>> removeCaseDocument(
    String caseId,
    String documentId,
  ) async {
    final data =
        await _request('DELETE', '/cases/$caseId/documents/$documentId');
    return data['case'] as Map<String, dynamic>;
  }

  /// Court-records search for the Add Case flow (CourtListener / PACER
  /// dockets). `available` is false when the provider could not be reached —
  /// the app then falls back to manual entry.
  static Future<Map<String, dynamic>> docketLookup(String caseNumber) async {
    return _request(
      'GET',
      '/cases/docket-lookup?caseNumber=${Uri.encodeQueryComponent(caseNumber)}',
    );
  }

  /// Pulls the latest court records for a case linked to a docket: new
  /// docket entries join the timeline and a terminated docket closes the
  /// case. Returns `{case, sync: {changed, newEvents, statusChanged, status,
  /// error?}}`.
  static Future<Map<String, dynamic>> syncCaseWithCourt(String caseId) async {
    return _request('POST', '/cases/$caseId/sync');
  }

  /// The user's conversations, latest first. Each row carries the peer's
  /// display info, the last message and the unread count.
  static Future<List<Map<String, dynamic>>> fetchThreads() async {
    final data = await _request('GET', '/messages/threads');
    final list = data['threads'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// The full chat with one user, oldest first. Opening it marks their
  /// messages as read.
  static Future<Map<String, dynamic>> fetchChat(String peerId) async {
    return _request('GET', '/messages/with/$peerId');
  }

  /// Sends a chat message to a related user (client ↔ attorney).
  static Future<void> sendChatMessage(String peerId, String text) async {
    await _request('POST', '/messages/with/$peerId', body: {'text': text});
  }

  /// Consultation fees per type ('video_call' → 120, …), set from the
  /// admin panel.
  static Future<Map<String, double>> fetchConsultationPricing() async {
    final data = await _request('GET', '/settings/pricing');
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    return {
      for (final entry in pricing.entries)
        if (entry.value is num) entry.key: (entry.value as num).toDouble(),
    };
  }

  /// The user's notifications, newest first, plus the unread count.
  static Future<Map<String, dynamic>> fetchNotifications() async {
    return _request('GET', '/notifications');
  }

  /// Marks all notifications as read.
  static Future<void> markNotificationsRead() async {
    await _request('POST', '/notifications/read');
  }

  /// Saves the Edit Profile screen for any role (fields depend on the role,
  /// e.g. fullName/email/photo for clients, firmName/... for firms) and
  /// refreshes the session with the updated user.
  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    final data = await _request('PUT', '/profile', body: fields);
    Session.user = data['user'] as Map<String, dynamic>? ?? Session.user;
  }

  /// App page content (Terms, Privacy, ...) managed from the admin panel.
  // ---------------------------------------------------------- Help & Support

  /// Support email / phone / hours shown on the Help & Support screen,
  /// editable from the admin panel.
  static Future<Map<String, dynamic>> fetchSupportContact() async {
    final data = await _request('GET', '/settings/support');
    return (data['support'] as Map<String, dynamic>?) ?? {};
  }

  /// The user's support tickets, latest activity first, plus how many
  /// admin replies they haven't opened yet.
  static Future<({List<Map<String, dynamic>> tickets, int unread})>
      fetchSupportTickets() async {
    final data = await _request('GET', '/support/tickets');
    final list = (data['tickets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return (tickets: list, unread: (data['unread'] as num?)?.toInt() ?? 0);
  }

  /// One ticket with its reply thread. Opening it marks replies as read.
  static Future<Map<String, dynamic>> fetchSupportTicket(String id) async {
    final data = await _request('GET', '/support/tickets/$id');
    return data['ticket'] as Map<String, dynamic>;
  }

  /// Raises a new ticket. [category] is one of account, booking, payment,
  /// case, technical, other.
  static Future<Map<String, dynamic>> createSupportTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    final data = await _request('POST', '/support/tickets', body: {
      'category': category,
      'subject': subject,
      'message': message,
    });
    return data['ticket'] as Map<String, dynamic>;
  }

  /// Adds the user's follow-up message to a ticket.
  static Future<Map<String, dynamic>> replySupportTicket(
    String id,
    String text,
  ) async {
    final data = await _request(
      'POST',
      '/support/tickets/$id/reply',
      body: {'text': text},
    );
    return data['ticket'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchCmsPage(String slug) async {
    final data = await _request('GET', '/cms/$slug');
    return data['page'] as Map<String, dynamic>;
  }
}
