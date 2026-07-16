import 'package:flutter/foundation.dart';
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

    final parsedUrl = Uri.tryParse(url);
    final imagePath = parsedUrl?.path.toLowerCase() ?? url.toLowerCase();
    final isFootballLogo =
        parsedUrl != null &&
        const {
          'media.api-sports.io',
          'crests.football-data.org',
        }.contains(parsedUrl.host);
    final resolvedUrl = isFootballLogo
        ? Uri.https(
            'southamerica-east1-raspadinhadogol.cloudfunctions.net',
            '/proxyFootballImage',
            {'url': url},
          ).toString()
        : url;

    // No Flutter Web, o elemento HTML carrega imagens de outros domínios sem
    // exigir que o servidor permita a leitura dos bytes pelo CanvasKit/Skwasm.
    // O próprio navegador também renderiza SVG dentro de <img>.
    if (kIsWeb) {
      return Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder:
            errorBuilder ??
            (context, error, stackTrace) =>
                Icon(Icons.shield, color: Colors.grey, size: width ?? 48),
      );
    }

    if (imagePath.endsWith('.svg')) {
      return SvgPicture.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorBuilder:
            errorBuilder ??
            (context, error, stackTrace) =>
                Icon(Icons.shield, color: Colors.grey, size: width ?? 48),
      );
    } else {
      return Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder:
            errorBuilder ??
            (context, error, stackTrace) =>
                Icon(Icons.shield, color: Colors.grey, size: width ?? 48),
      );
    }
  }
}
