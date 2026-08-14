import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Eine AWTRIX-NG-Uhr im Netzwerk (per IP/Hostname).
class AwtrixDevice {
  String host; // IP oder Hostname (z. B. 192.168.1.111 oder awtrixng-a1b2c3.local)
  int port;
  String name;

  AwtrixDevice({required this.host, this.port = 80, String? name})
      : name = (name == null || name.trim().isEmpty) ? host : name.trim();

  String get base => 'http://$host${port == 80 ? '' : ':$port'}';

  Map<String, dynamic> toJson() => {'host': host, 'port': port, 'name': name};

  factory AwtrixDevice.fromJson(Map<String, dynamic> j) => AwtrixDevice(
        host: j['host'] as String,
        port: (j['port'] as int?) ?? 80,
        name: j['name'] as String?,
      );
}

/// HTTP-API-Client (AWTRIX NG /api/v1/...).
class AwtrixApi {
  final AwtrixDevice device;
  AwtrixApi(this.device);

  Uri _u(String path) => Uri.parse('${device.base}/api/v1$path');

  Future<http.Response> _send(String method, String path, {Object? body}) async {
    final client = http.Client();
    try {
      final req = http.Request(method, _u(path));
      req.headers['Content-Type'] = 'application/json';
      if (body != null) req.body = jsonEncode(body);
      final streamed = await client.send(req).timeout(const Duration(seconds: 6));
      return await http.Response.fromStream(streamed);
    } finally {
      client.close();
    }
  }

  dynamic _json(http.Response r) {
    if (r.body.isEmpty) return null;
    try {
      return jsonDecode(r.body);
    } catch (_) {
      return null;
    }
  }

  // --- Notifications ---
  Future<http.Response> notify(
    String text, {
    List<int>? color,
    String? icon,
    int? durationS,
    bool? hold,
    bool? rainbow,
  }) =>
      _send('POST', '/notifications', body: {
        'text': text,
        if (color != null) 'textColor': color,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
        if (durationS != null) 'durationMs': durationS * 1000,
        if (hold != null) 'hold': hold,
        if (rainbow != null && rainbow) 'rainbow': true,
      });

  Future<http.Response> dismiss() => _send('DELETE', '/notifications/active');

  // --- Apps ---
  Future<http.Response> nextApp() => _send('POST', '/apps/next');
  Future<http.Response> prevApp() => _send('POST', '/apps/previous');
  Future<http.Response> switchApp(String name) =>
      _send('PUT', '/apps/active', body: {'name': name});
  Future<http.Response> deleteApp(String name) => _send('DELETE', '/apps/$name');
  Future<http.Response> reorderApps(List<String> order, List<String> disabled) =>
      _send('PUT', '/apps/order', body: {'order': order, 'disabled': disabled});

  Future<List<Map<String, dynamic>>> getApps() async {
    try {
      final d = _json(await _send('GET', '/apps'));
      final List list = d is List
          ? d
          : d is Map && d['apps'] is List
              ? d['apps'] as List
              : d is Map
                  ? d.keys.map((k) => {'name': '$k'}).toList()
                  : const [];
      return list
          .whereType<Map>()
          .map((e) => e.map((k, val) => MapEntry('$k', val)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Display / Power / Overlay ---
  Future<http.Response> power(bool on) =>
      _send('PATCH', '/display', body: {'power': on});
  Future<http.Response> overlay(String? name) =>
      _send('PATCH', '/display', body: {'overlay': name});

  // --- Moodlight ---
  Future<http.Response> moodlight(List<int> color, {int brightness = 120}) =>
      _send('PUT', '/display/moodlight',
          body: {'color': color, 'brightness': brightness});
  Future<http.Response> moodlightOff() => _send('DELETE', '/display/moodlight');

  // --- Indicators (1-3) ---
  Future<http.Response> indicator(int id, List<int> color, {int blinkMs = 0}) =>
      _send('PUT', '/indicators/$id',
          body: {'color': color, if (blinkMs > 0) 'blinkMs': blinkMs});
  Future<http.Response> indicatorOff(int id) =>
      _send('DELETE', '/indicators/$id');

  // --- Settings (alle) ---
  Future<http.Response> setBrightness(int b) =>
      _send('PATCH', '/settings', body: {'brightness': b});
  Future<http.Response> autoBrightness(bool on) =>
      _send('PATCH', '/settings', body: {'autoBrightness': on});
  Future<http.Response> patchSettings(Map<String, dynamic> s) =>
      _send('PATCH', '/settings', body: s);
  Future<Map<String, dynamic>> getSettings() async {
    final d = _json(await _send('GET', '/settings'));
    return d is Map ? d.cast<String, dynamic>() : {};
  }

  // --- Audio ---
  Future<List<String>> getMelodies() async {
    final d = _json(await _send('GET', '/audio/melodies'));
    final list = d is List
        ? d
        : (d is Map && d['melodies'] is List ? d['melodies'] : const []);
    return list.map((e) => e is Map ? '${e['name']}' : '$e').toList();
  }

  Future<http.Response> playMelody(String name) =>
      _send('POST', '/audio/play', body: {'name': name});
  Future<http.Response> stopAudio() => _send('POST', '/audio/stop');

  // --- Sounds / RTTTL direkt ---
  Future<http.Response> playRtttl(String rtttl) =>
      _send('POST', '/audio/play', body: {'rtttl': rtttl});

  // --- Device / System ---
  Future<http.Response> reboot() => _send('POST', '/device/reboot');
  Future<http.Response> factoryReset() =>
      _send('POST', '/device/factory-reset');

  Future<Map<String, dynamic>> getDevice() async {
    final d = _json(await _send('GET', '/device'));
    return d is Map ? d.cast<String, dynamic>() : {};
  }

  Future<Map<String, dynamic>> getSystem() async {
    final d = _json(await _send('GET', '/system'));
    return d is Map ? d.cast<String, dynamic>() : {};
  }

  Future<http.Response> patchSystem(Map<String, dynamic> s) =>
      _send('PUT', '/system', body: s);

  Future<Map<String, dynamic>> getCapabilities() async {
    final d = _json(await _send('GET', '/capabilities'));
    return d is Map ? d.cast<String, dynamic>() : {};
  }
}

/// UDP-Broadcast-Discovery: sendet FIND_AWTRIXNG an :4210, lauscht auf :4211.
Future<List<AwtrixDevice>> discoverAwtrix(
    {Duration timeout = const Duration(seconds: 3)}) async {
  final found = <String, AwtrixDevice>{};
  RawDatagramSocket? sock;
  try {
    sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4211,
        reuseAddress: true);
    sock.broadcastEnabled = true;
    sock.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = sock!.receive();
      if (dg == null) return;
      final msg = utf8.decode(dg.data, allowMalformed: true).trim();
      if (msg.isEmpty || msg.startsWith('FIND_')) return;
      final ip = dg.address.address;
      final parts = msg.split(':');
      final name = parts[0];
      final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 80) : 80;
      found[ip] = AwtrixDevice(host: ip, port: port, name: name);
    });

    final data = utf8.encode('FIND_AWTRIXNG');
    final bcast = InternetAddress('255.255.255.255');
    sock.send(data, bcast, 4210);
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        sock?.send(data, bcast, 4210);
      } catch (_) {}
    });

    await Future.delayed(timeout);
  } catch (_) {
    // Discovery fehlgeschlagen -> Nutzer kann per IP hinzufuegen.
  } finally {
    sock?.close();
  }
  return found.values.toList();
}

/// Persistenz der bekannten Uhren.
class DeviceStore {
  static const _key = 'awtrix_devices';

  static Future<List<AwtrixDevice>> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return [];
    try {
      final list = jsonDecode(s) as List;
      return list
          .map((e) => AwtrixDevice.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<AwtrixDevice> devices) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(devices.map((d) => d.toJson()).toList()));
  }
}
