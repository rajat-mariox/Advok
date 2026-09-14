import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// One "something changed" notice from the backend's live stream.
class RealtimeEvent {
  const RealtimeEvent({required this.topic, this.data});

  /// 'bookings', 'cases', 'messages', 'notifications', 'clients', 'queries',
  /// 'support', 'account', 'settings', 'content'.
  final String topic;

  /// Small hint (ids, status); never the full record.
  final Map<String, dynamic>? data;
}

/// Live updates over Server-Sent Events. One connection per app session:
/// started automatically once the user is signed in (see ApiService) and
/// dropped on logout. Screens subscribe with [on] and simply re-fetch the
/// list they show, so everything reflects other users' actions within about
/// a second without pull-to-refresh.
class Realtime {
  Realtime._();

  static final Realtime instance = Realtime._();

  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  /// True while the stream is connected (for a status dot, if wanted).
  final ValueNotifier<bool> connected = ValueNotifier(false);

  http.Client? _client;
  StreamSubscription<String>? _lines;
  Timer? _reconnect;
  int _attempt = 0;
  String? _tokenInUse;
  bool _wanted = false;

  /// Events for any of [topics] (empty set = everything).
  Stream<RealtimeEvent> on(Set<String> topics) => topics.isEmpty
      ? _events.stream
      : _events.stream.where((e) => topics.contains(e.topic));

  /// Connects if there is a session token and no live connection yet.
  /// Cheap to call repeatedly.
  void ensureConnected() {
    final token = Session.token;
    if (token == null || token.isEmpty) return;
    if (_wanted && _tokenInUse == token && (_client != null || _reconnect != null)) {
      return;
    }
    _wanted = true;
    _tokenInUse = token;
    _closeSocket();
    _connect();
  }

  /// Drops the connection (logout).
  void disconnect() {
    _wanted = false;
    _tokenInUse = null;
    _reconnect?.cancel();
    _reconnect = null;
    _closeSocket();
  }

  Future<void> _connect() async {
    if (!_wanted) return;
    final token = _tokenInUse;
    if (token == null) return;
    try {
      final base = await ApiService.resolvedBaseUrl();
      final client = http.Client();
      _client = client;
      final request = http.Request('GET', Uri.parse('$base/events'))
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw http.ClientException('Live updates: HTTP ${response.statusCode}');
      }
      _attempt = 0;
      connected.value = true;
      String? eventName;
      final dataLines = <String>[];
      _lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.isEmpty) {
            if (eventName == 'change' && dataLines.isNotEmpty) {
              _dispatch(dataLines.join('\n'));
            }
            eventName = null;
            dataLines.clear();
            return;
          }
          if (line.startsWith(':')) return; // heartbeat
          if (line.startsWith('event:')) {
            eventName = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            dataLines.add(line.substring(5).trimLeft());
          }
        },
        onDone: _onDropped,
        onError: (_) => _onDropped(),
        cancelOnError: true,
      );
    } catch (_) {
      _onDropped();
    }
  }

  void _dispatch(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final topic = map['topic'] as String?;
      if (topic == null) return;
      _events.add(RealtimeEvent(
        topic: topic,
        data: map['data'] is Map<String, dynamic>
            ? map['data'] as Map<String, dynamic>
            : null,
      ));
    } catch (_) {
      // Malformed frame — ignore.
    }
  }

  void _onDropped() {
    connected.value = false;
    _closeSocket();
    if (!_wanted) return;
    // Exponential backoff: 2s, 4s, 8s … capped at 30s.
    final seconds = (2 << _attempt).clamp(2, 30);
    _attempt = (_attempt + 1).clamp(0, 5);
    _reconnect?.cancel();
    _reconnect = Timer(Duration(seconds: seconds), () {
      _reconnect = null;
      _connect();
    });
  }

  void _closeSocket() {
    _lines?.cancel();
    _lines = null;
    _client?.close();
    _client = null;
    connected.value = false;
  }
}

/// Mixin for screens that show a backend list: call [listenRealtime] in
/// `initState` and the subscription is cancelled on dispose.
mixin RealtimeRefresh<T extends StatefulWidget> on State<T> {
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  /// Re-runs [onEvent] whenever the backend reports a change on any of
  /// [topics]. Bursts are coalesced so one refresh covers a flurry of events.
  void listenRealtime(Set<String> topics, void Function(RealtimeEvent event) onEvent) {
    _realtimeSub?.cancel();
    Timer? debounce;
    RealtimeEvent? last;
    _realtimeSub = Realtime.instance.on(topics).listen((event) {
      last = event;
      debounce?.cancel();
      debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        final e = last;
        if (e != null) onEvent(e);
      });
    });
    Realtime.instance.ensureConnected();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    super.dispose();
  }
}
