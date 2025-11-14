import 'package:flutter/material.dart';

enum ReusableImageType { asset, network, file }

class ReusableImage extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final ReusableImageType type;

  const ReusableImage.asset(
    this.imagePath, {
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  })  : imageUrl = null,
        type = ReusableImageType.asset,
        super(key: key);

  const ReusableImage.network(
    this.imageUrl, {
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  })  : imagePath = null,
        type = ReusableImageType.network,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (type == ReusableImageType.network && imageUrl != null) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    } else if (type == ReusableImageType.asset && imagePath != null) {
      imageWidget = Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    } else {
      imageWidget = Container(
        width: width,
        height: height,
        color: backgroundColor ?? Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
