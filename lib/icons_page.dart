import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'l10n.dart';
import 'lametric_browser_page.dart';
import 'widgets.dart';

class IconsPage extends StatefulWidget {
  final AwtrixDevice device;
  const IconsPage({super.key, required this.device});

  @override
  State<IconsPage> createState() => _IconsPageState();
}

class _IconsPageState extends State<IconsPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  final _idC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await api.getFiles('/ICONS');
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = trp('icons_unreachable', {'host': widget.device.host});
        });
      }
    }
  }

  List<Map<String, dynamic>> get _files {
    final f = _data?['files'];
    if (f is List) {
      return f
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry('$k', v)))
          .toList();
    }
    return [];
  }

  Future<void> _loadLametric() async {
    final id = _idC.text.trim();
    if (id.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await fetchLametricIcon(id);
      if (bytes == null) {
        snack(context, trp('icon_not_found', {'id': id}));
      } else {
        final r = await uploadIcon(api, id, bytes);
        if (r.statusCode >= 200 && r.statusCode < 300) {
          snack(context, trp('icon_saved', {'id': id}));
          _idC.clear();
          await _load();
        } else {
          snack(context, trp('rejected', {'code': '${r.statusCode}'}));
        }
      }
    } catch (_) {
      snack(context, tr('error_generic'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(trp('delete_q', {'name': name})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('delete'))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.deleteFile('/ICONS/$name');
        snack(context, tr('delete'));
        await _load();
      } catch (_) {
        snack(context, tr('notReachableShort'));
      }
    }
  }

  Widget _lametricPreview(String id) {
    if (id.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        'https://developer.lametric.com/content/apps/icon_thumbs/$id',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 48,
          color: Colors.black12,
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  // Miniatur eines auf der Uhr gespeicherten Icons (Web-Server liefert die
  // Datei direkt unter /ICONS/<name>; animierte GIFs werden abgespielt).
  Widget _iconThumb(String name) {
    final url = '${widget.device.base}/ICONS/$name';
    final auth = widget.device.authHeader;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          url,
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          headers: auth == null ? null : {'Authorization': auth},
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported,
              size: 18, color: Colors.grey),
        ),
      ),
    );
  }

  // Zeigt das Icon kurz auf der Uhr an (Benachrichtigung nur mit Icon).
  Future<void> _showOnClock(String name) async {
    final ref =
        name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    try {
      final r = await api.sendNotification(
          {'icon': ref, 'text': '', 'durationMs': 6000, 'stack': false});
      snack(
          context,
          (r.statusCode >= 200 && r.statusCode < 300)
              ? trp('showing_named', {'name': ref})
              : trp('rejected', {'code': '${r.statusCode}'}));
    } catch (_) {
      snack(context, tr('notReachableShort'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);

    final used = (_data?['usedBytes'] as num?)?.toInt();
    final total = (_data?['totalBytes'] as num?)?.toInt();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (used != null && total != null && total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(tr('storage')),
                    const Spacer(),
                    Text(
                        '${(used / 1024).toStringAsFixed(0)} / ${(total / 1024).toStringAsFixed(0)} KB'),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: (used / total).clamp(0.0, 1.0).toDouble(),
                        minHeight: 8),
                  ),
                ],
              ),
            ),
          SectionCard(
            title: tr('lametric_load'),
            icon: Icons.download,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            LametricBrowserPage(device: widget.device)),
                  );
                  _load();
                },
                icon: const Icon(Icons.search),
                label: Text(tr('browse_gallery')),
              ),
              const SizedBox(height: 10),
              Text(tr('or_enter_id'),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Row(children: [
                _lametricPreview(_idC.text.trim()),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _idC,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: const OutlineInputBorder(),
                      labelText: tr('icon_id'),
                      hintText: 'z. B. 2867',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _loadLametric,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(tr('load')),
                ),
              ]),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                      Uri.parse('https://developer.lametric.com/icons'),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(tr('open_gallery')),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(trp('saved_icons', {'n': '${_files.length}'}),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final f in _files)
            ListTile(
              leading: _iconThumb('${f['name']}'),
              title: Text('${f['name']}'),
              subtitle: Text('${(f['size'] as num?)?.toInt() ?? 0} Bytes'),
              onTap: () => _showOnClock('${f['name']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    tooltip: tr('show_on_clock'),
                    onPressed: () => _showOnClock('${f['name']}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: tr('delete'),
                    onPressed: () => _delete('${f['name']}'),
                  ),
                ],
              ),
            ),
          if (_files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(tr('no_icons'))),
            ),
        ],
      ),
    );
  }
}
