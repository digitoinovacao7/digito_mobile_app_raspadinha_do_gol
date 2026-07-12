import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NetworkLogo extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final Widget placeholderIcon;

  const NetworkLogo({
    super.key,
    required this.url,
    this.width = 48,
    this.height = 48,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return placeholderIcon;
    }

    if (url!.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url!,
        width: width,
        height: height,
        placeholderBuilder: (BuildContext context) => placeholderIcon,
      );
    } else {
      return Image.network(
        url!,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => placeholderIcon,
      );
    }
  }
}
