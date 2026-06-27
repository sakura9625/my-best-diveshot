import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

class ResolvedImage extends StatefulWidget {
  final String fileName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const ResolvedImage({
    super.key,
    required this.fileName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  State<ResolvedImage> createState() => _ResolvedImageState();
}

class _ResolvedImageState extends State<ResolvedImage> {
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _resolvePath();
  }

  @override
  void didUpdateWidget(ResolvedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // fileNameが変わったら再解決する
    if (oldWidget.fileName != widget.fileName) {
      _resolvedPath = null;
      _resolvePath();
    }
  }

  Future<void> _resolvePath() async {
    final path = await ImageService.resolveImagePath(widget.fileName);
    if (mounted) setState(() => _resolvedPath = path);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedPath == null) {
      return widget.errorWidget ?? const SizedBox.shrink();
    }
    final file = File(_resolvedPath!);
    if (!file.existsSync()) {
      return widget.errorWidget ?? Container(
        color: Colors.white12,
        child: const Icon(Icons.image_not_supported, color: Colors.white24),
      );
    }
    return Image.file(
      file,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      // キャッシュを使わず常に最新を表示
      cacheWidth: null,
      key: ValueKey(_resolvedPath),
    );
  }
}
