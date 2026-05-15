import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef _Responder = Future<String> Function(Uri);

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'Unshelf-Buyer/1.0 (https://unshelf.ph)';
  static const Duration _minInterval = Duration(seconds: 1);

  NominatimService() : _responder = _defaultResponder;

  NominatimService.withMockResponder({required _Responder responder})
      : _responder = responder;

  final _Responder _responder;
  DateTime _lastRequestAt = DateTime.fromMicrosecondsSinceEpoch(0);
  final _AsyncLock _gateLock = _AsyncLock();

  Future<List<NominatimPlace>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    await _waitForRateSlot();
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '1',
    });
    final body = await _responder(uri);
    final decoded = jsonDecode(body) as List<dynamic>;
    return decoded
        .map((j) => NominatimPlace.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<NominatimPlace?> reverseGeocode(double lat, double lng) async {
    await _waitForRateSlot();
    final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'json',
      'addressdetails': '1',
    });
    final body = await _responder(uri);
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['error'] == null) {
      return NominatimPlace.fromJson(decoded);
    }
    return null;
  }

  Future<void> _waitForRateSlot() async {
    await _gateLock.acquire();
    try {
      final now = DateTime.now();
      final elapsed = now.difference(_lastRequestAt);
      if (elapsed < _minInterval) {
        await Future.delayed(_minInterval - elapsed);
      }
      _lastRequestAt = DateTime.now();
    } finally {
      _gateLock.release();
    }
  }

  static Future<String> _defaultResponder(Uri uri) async {
    final resp = await http.get(uri, headers: {'User-Agent': _userAgent});
    return resp.body;
  }
}

class NominatimPlace {
  NominatimPlace({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final double lat;
  final double lng;

  factory NominatimPlace.fromJson(Map<String, dynamic> j) => NominatimPlace(
        displayName: j['display_name'] as String? ?? '',
        lat: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
        lng: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
      );
}

class _AsyncLock {
  Completer<void>? _completer;

  Future<void> acquire() async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  void release() {
    final c = _completer;
    _completer = null;
    c?.complete();
  }
}
