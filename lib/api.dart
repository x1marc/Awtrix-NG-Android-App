import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Eine AWTRIX-NG-Uhr im Netzwerk (per IP/Hostname).
class AwtrixDevice {
  String host; // IP oder Hostname (z. B. 192.168.1.50 oder awtrixng-a1b2c3.local)
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

  // --- Notifications ---
  Future<http.Response> notify(String text, {List<int>? color}) =>
      _send('POST', '/notifications', body: {
        'text': text,
        if (color != null) 'textColor': color,
      });

  Future<http.Response> dismiss() => _send('DELETE', '/notifications/active');

  // --- Apps ---
  Future<http.Response> nextApp() => _send('POST', '/apps/next');
  Future<http.Response> prevApp() => _send('POST', '/apps/previous');

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

  // --- Settings (40 Stück) ---
  Future<http.Response> setBrightness(int b) =>
      _send('PATCH', '/settings', body: {'brightness': b});
  Future<http.Response> autoBrightness(bool on) =>
      _send('PATCH', '/settings', body: {'autoBrightness': on});
  Future<http.Response> patchSettings(Map<String, dynamic> s) =>
      _send('PATCH', '/settings', body: s);
  Future<Map<String, dynamic>> getSettings() async {
    final r = await _send('GET', '/settings');
    return (jsonDecode(r.body) as Map).cast<String, dynamic>();
  }

  // --- Device ---
  Future<http.Response> reboot() => _send('POST', '/device/reboot');
  Future<Map<String, dynamic>> getDevice() async {
    final r = await _send('GET', '/device');
    return (jsonDecode(r.body) as Map).cast<String, dynamic>();
  }
}

/// UDP-Broadcast-Discovery: sendet FIND_AWTRIXNG an :4210, lauscht auf :4211.
/// Die Antwort ist HOSTNAME oder HOSTNAME:PORT, Absender-IP = Geräteadresse.
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
      if (msg.isEmpty || msg.startsWith('FIND_')) return; // eigene Anfrage ignorieren
      final ip = dg.address.address;
      final parts = msg.split(':');
      final name = parts[0];
      final port = parts.length > 1 ? (int.tryParse(parts[1]) ?? 80) : 80;
      found[ip] = AwtrixDevice(host: ip, port: port, name: name);
    });

    final data = utf8.encode('FIND_AWTRIXNG');
    final bcast = InternetAddress('255.255.255.255');
    sock.send(data, bcast, 4210);
    // Zweiter Versuch, falls das erste Paket verloren geht.
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        sock?.send(data, bcast, 4210);
      } catch (_) {}
    });

    await Future.delayed(timeout);
  } catch (_) {
    // Discovery fehlgeschlagen -> leere Liste, Nutzer kann per IP hinzufügen.
  } finally {
    sock?.close();
  }
  return found.values.toList();
}

/// Persistenz der bekannten Uhren (shared_preferences).
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
