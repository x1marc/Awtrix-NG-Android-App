import 'package:flutter/material.dart';

import 'api.dart';
import 'l10n.dart';
import 'widgets.dart';

/// Durchsucht die LaMetric-Icon-Galerie und lädt ein Icon per Tipp direkt
/// auf die Uhr (Download von LaMetric + Upload via /files).
class LametricBrowserPage extends StatefulWidget {
  final AwtrixDevice device;
  const LametricBrowserPage({super.key, required this.device});

  @override
  State<LametricBrowserPage> createState() => _LametricBrowserPageState();
}

class _LametricBrowserPageState extends State<LametricBrowserPage> {
  late final AwtrixApi api = AwtrixApi(widget.device);
  final _q = TextEditingController();
  List<Map<String, dynamic>> _icons = [];
  bool _loading = true;
  String? _uploading;
  final Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final res = await searchLametricIcons(_q.text, count: 90);
    if (mounted) {
      setState(() {
        _icons = res;
        _loading = false;
      });
    }
  }

  Future<void> _upload(Map<String, dynamic> icon) async {
    final id = '${icon['id']}';
    if (_uploading != null) return;
    setState(() => _uploading = id);
    try {
      final bytes = await fetchLametricIcon(id);
      if (bytes == null) {
        snack(context, tr('download_failed'));
      } else {
        final r = await uploadIcon(api, id, bytes);
        if (r.statusCode >= 200 && r.statusCode < 300) {
          _done.add(id);
          snack(context, trp('icon_uploaded', {'id': id}));
        } else {
          snack(context, trp('rejected', {'code': '${r.statusCode}'}));
        }
      }
    } catch (_) {
      snack(context, tr('upload_error'));
    }
    if (mounted) setState(() => _uploading = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(tr('lametric_icons'))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      prefixIcon: const Icon(Icons.search),
                      hintText: tr('search_hint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: Text(tr('search'))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(tr('tap_to_load'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _icons.isEmpty
                      ? Center(child: Text(tr('nothing_found')))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 110,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: _icons.length,
                          itemBuilder: (_, i) {
                            final ic = _icons[i];
                            final id = '${ic['id']}';
                            final busy = _uploading == id;
                            final done = _done.contains(id);
                            return InkWell(
                              onTap: () => _upload(ic),
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF141414),
                                        borderRadius: BorderRadius.circular(8),
                                        border: done
                                            ? Border.all(
                                                color: Colors.green, width: 2)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: busy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Image.network(
                                                    '${ic['thumb']}',
                                                    fit: BoxFit.contain,
                                                    gaplessPlayback: true,
                                                    errorBuilder: (_, __, ___) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey),
                                                  ),
                                                ),
                                                if (done)
                                                  const Positioned(
                                                    right: 2,
                                                    top: 2,
                                                    child: Icon(Icons.check_circle,
                                                        color: Colors.green,
                                                        size: 18),
                                                  ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('$id',
                                      style: const TextStyle(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
    );
  }
}
