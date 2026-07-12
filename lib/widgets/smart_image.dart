import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SmartImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;

  const SmartImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorBuilder?.call(context, null, null) ?? 
             Icon(Icons.shield, color: Colors.grey, size: width ?? 48);
    }

    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        placeholderBuilder: (context) => SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    } else {
      return Image.network(
        url,
        width: width,
        height: height,
        headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        errorBuilder: errorBuilder ?? 
            (context, error, stackTrace) => Icon(Icons.shield, color: Colors.grey, size: width ?? 48),
      );
    }
  }
}
