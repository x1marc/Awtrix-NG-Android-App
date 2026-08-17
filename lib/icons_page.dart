import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
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
          _error = 'Icons nicht erreichbar (${widget.device.host}).';
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
        snack(context, 'Icon $id nicht gefunden');
      } else {
        final r = await uploadIcon(api, id, bytes);
        if (r.statusCode >= 200 && r.statusCode < 300) {
          snack(context, 'Icon $id gespeichert');
          _idC.clear();
          await _load();
        } else {
          snack(context, 'Uhr lehnte ab (${r.statusCode})');
        }
      }
    } catch (_) {
      snack(context, 'Fehler beim Laden');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('„$name" löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.deleteFile('/ICONS/$name');
        snack(context, 'Gelöscht');
        await _load();
      } catch (_) {
        snack(context, 'Nicht erreichbar');
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
                    const Text('Speicher'),
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
            title: 'LaMetric-Icon laden',
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
                label: const Text('Galerie durchsuchen & direkt laden'),
              ),
              const SizedBox(height: 10),
              Text('… oder eine Icon-ID direkt eingeben:',
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
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: OutlineInputBorder(),
                      labelText: 'Icon-ID',
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
                      : const Text('Laden'),
                ),
              ]),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                      Uri.parse('https://developer.lametric.com/icons'),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Icon-Galerie öffnen'),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Gespeicherte Icons (${_files.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final f in _files)
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text('${f['name']}'),
              subtitle: Text('${(f['size'] as num?)?.toInt() ?? 0} Bytes'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Löschen',
                onPressed: () => _delete('${f['name']}'),
              ),
            ),
          if (_files.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Noch keine Icons gespeichert.')),
            ),
        ],
      ),
    );
  }
}
