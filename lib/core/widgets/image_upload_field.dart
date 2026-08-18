// Web-only admin panel: native drag & drop requires dart:html.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Generic image upload widget with drag-and-drop. Writes the download URL
/// into [urlController] after upload completes.
class ImageUploadField extends StatefulWidget {
  final TextEditingController urlController;
  final String objectId;
  final String pathPrefix;

  const ImageUploadField({
    super.key,
    required this.urlController,
    required this.objectId,
    required this.pathPrefix,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _dragging = false;
  bool _uploading = false;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    final win = html.window;
    win.addEventListener('dragover', _onDragOver);
    win.addEventListener('dragleave', _onDragLeave);
    win.addEventListener('drop', _onDrop);
  }

  @override
  void dispose() {
    final win = html.window;
    win.removeEventListener('dragover', _onDragOver);
    win.removeEventListener('dragleave', _onDragLeave);
    win.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  void _onDragOver(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    e.stopPropagation();
    if (!_dragging) setState(() => _dragging = true);
  }

  void _onDragLeave(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    if (_dragging) setState(() => _dragging = false);
  }

  void _onDrop(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    e.stopPropagation();
    if (_dragging) setState(() => _dragging = false);
    final data = (e as dynamic).dataTransfer as html.DataTransfer?;
    final dropped = data?.files;
    final file = (dropped == null || dropped.isEmpty) ? null : dropped.first;
    if (file != null) _readAndUpload(file);
  }

  void _browse() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;
    void cleanup() => input.remove();
    input.onChange.first.then((_) {
      cleanup();
      final files = input.files;
      final file = (files == null || files.isEmpty) ? null : files.first;
      if (file != null) _readAndUpload(file);
    }, onError: (_) => cleanup());
    input.on['cancel'].first.then((_) => cleanup());
    html.document.body?.append(input);
    input.click();
  }

  void _readAndUpload(html.File file) {
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final bytes = reader.result;
      if (bytes is Uint8List) {
        _uploadBytes(bytes, file.name.isEmpty ? 'image.jpg' : file.name);
      }
    });
    reader.onError.listen((_) {
      if (mounted) setState(() => _error = 'Could not read the dropped file.');
    });
    reader.readAsArrayBuffer(file);
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String get _storagePath => '${widget.pathPrefix}/${widget.objectId}';

  Future<void> _uploadBytes(Uint8List bytes, String name) async {
    if (!mounted) return;
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });
    final ref = FirebaseStorage.instance.ref(_storagePath);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentType(name),
        cacheControl: 'public,max-age=86400',
      ),
    );
    String? failure;
    final done = Completer<void>();
    final sub = task.snapshotEvents.listen((snap) {
      if (!mounted) return;
      if (snap.totalBytes > 0) {
        setState(
          () =>
              _progress = (snap.bytesTransferred / snap.totalBytes).clamp(0, 1),
        );
      }
      if (done.isCompleted) return;
      switch (snap.state) {
        case TaskState.success:
          done.complete();
          break;
        case TaskState.error:
          failure ??= 'Upload failed.';
          done.complete();
          break;
        case TaskState.canceled:
          failure ??= 'Upload canceled.';
          done.complete();
          break;
        case TaskState.paused:
        case TaskState.running:
          if (snap.totalBytes > 0 && snap.bytesTransferred >= snap.totalBytes) {
            done.complete();
          }
          break;
      }
    });
    try {
      await done.future.timeout(const Duration(seconds: 90));
      if (failure != null) throw failure!;
      final url = await _waitForDownloadUrl(ref);
      if (!mounted) return;
      widget.urlController.text = url;
      setState(() {
        _uploading = false;
        _progress = 1;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Upload failed: $e';
        });
      }
    } finally {
      sub.cancel();
    }
  }

  Future<String> _waitForDownloadUrl(Reference ref) async {
    for (var attempt = 0; attempt < 15; attempt++) {
      try {
        return await ref.getDownloadURL();
      } catch (_) {
        final delay = 500 * (attempt + 1);
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    throw 'Upload finished but the file is not reachable yet. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.urlController,
      builder: (context, value, _) {
        final url = value.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (url.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.darkBase,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 30,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            InkWell(
              onTap: _uploading ? null : _browse,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: _dragging
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dragging ? AppColors.gold : AppColors.glassBorder,
                    width: _dragging ? 2 : 1,
                  ),
                ),
                child: _uploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 4,
                              color: AppColors.gold,
                              backgroundColor: AppColors.glassBorder,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Uploading…',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 26,
                            color: AppColors.accent,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Drag & drop an image here\nor click to browse',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.liveRedLight,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
