import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    required this.fit,
  });

  final String imageUrl;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return fallback;

    return imageUrl.startsWith('assets/')
        ? Image.asset(imageUrl, fit: fit, errorBuilder: _errorBuilder)
        : Image.network(imageUrl, fit: fit, errorBuilder: _errorBuilder);
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => fallback;
}
