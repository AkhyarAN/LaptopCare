import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wrapper widget yang aman untuk web untuk mengatasi mouse tracker errors
class WebSafeImagePicker extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const WebSafeImagePicker({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Di web, gunakan GestureDetector yang lebih sederhana
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: child,
        ),
      );
    } else {
      // Di platform lain, gunakan InkWell biasa
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      );
    }
  }
}

/// Safe image widget untuk mengatasi network image issues di web
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('SafeNetworkImage error: $error');
        return errorWidget ?? _buildDefaultErrorWidget();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.error, color: Colors.grey),
      ),
    );
  }
}

/// Safe widget builder yang menangani errors gracefully
class SafeWidgetBuilder extends StatelessWidget {
  final Widget Function() builder;
  final Widget? errorWidget;
  final String? debugLabel;

  const SafeWidgetBuilder({
    super.key,
    required this.builder,
    this.errorWidget,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return builder();
    } catch (e) {
      debugPrint(
          'SafeWidgetBuilder error${debugLabel != null ? ' in $debugLabel' : ''}: $e');
      return errorWidget ?? _buildDefaultErrorWidget(e);
    }
  }

  Widget _buildDefaultErrorWidget(dynamic error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Widget Error',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 4),
            Text(
              '$error',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
