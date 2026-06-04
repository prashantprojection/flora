import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Safely builds a Flutter Image widget from a file path, gracefully
/// routing blob URLs to Image.network on the Web and local paths to Image.file natively.
Widget buildImage(
  String path, {
  BoxFit? fit,
  double? width,
  double? height,
  Widget? placeholder,
  int? cacheWidth,
  bool gaplessPlayback = false,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (path.isEmpty) return placeholder ?? const SizedBox.shrink();

  if (kIsWeb) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder ?? (context, error, stackTrace) =>
          placeholder ?? const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    gaplessPlayback: gaplessPlayback,
    errorBuilder: errorBuilder ?? (context, error, stackTrace) =>
        placeholder ?? const Icon(Icons.broken_image, color: Colors.grey),
  );
}

/// Safely provides an ImageProvider from a file path, routing blob URLs
/// to NetworkImage on the Web and local paths to FileImage natively.
/// Useful for BoxDecoration, CircleAvatar, etc.
ImageProvider getImageProvider(String path) {
  if (kIsWeb) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}
