import 'package:flutter/material.dart';

/// A collection of optimized widgets for better performance
class OptimizedWidgets {
  /// Creates a list item with optimized rendering
  static Widget listItem({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Key? key,
  }) {
    return RepaintBoundary(
      key: key,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Creates an optimized image with proper caching
  static Widget cachedImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Key? key,
  }) {
    return RepaintBoundary(
      key: key,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: (width?.toInt() ?? 300) * 2,
        cacheHeight: (height?.toInt() ?? 300) * 2,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  /// Creates an optimized card with proper boundaries
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    Key? key,
  }) {
    return RepaintBoundary(
      key: key,
      child: Card(
        margin: margin ?? const EdgeInsets.all(8.0),
        color: color,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  /// Creates an optimized list view builder
  static Widget listViewBuilder<T>({
    required List<T> items,
    required Widget Function(BuildContext, int) itemBuilder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Key? key,
  }) {
    return ListView.builder(
      key: key,
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemBuilder: itemBuilder,
    );
  }

  /// Creates a loading indicator with optimized rendering
  static Widget loadingIndicator({
    Color? color,
    double size = 24.0,
    Key? key,
  }) {
    return Center(
      key: key,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: color,
        ),
      ),
    );
  }
} 