import 'package:flutter/material.dart';

class ZoomableImage extends StatefulWidget {
  final String imageUrl;

  const ZoomableImage({super.key, required this.imageUrl});

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _transformationController.addListener(() {
      final matrix = _transformationController.value;
      _currentScale = matrix.getMaxScaleOnAxis();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    Matrix4 endMatrix;
    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()..scale(2.0);
    }
    _animateToTransform(endMatrix);
  }

  void _zoomIn() {
    double newScale = (_currentScale * 1.5).clamp(0.5, 4.0);
    Matrix4 newMatrix = Matrix4.identity()..scale(newScale);
    _animateToTransform(newMatrix);
  }

  void _zoomOut() {
    double newScale = (_currentScale / 1.5).clamp(0.5, 4.0);
    Matrix4 newMatrix = Matrix4.identity()..scale(newScale);
    _animateToTransform(newMatrix);
  }

  void _animateToTransform(Matrix4 endMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0).then((_) {
      _transformationController.value = endMatrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: screenWidth * 0.9,
          height: screenHeight * 0.8,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              if (_animation != null) {
                _transformationController.value = _animation!.value;
              }
              return InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(20),
                constrained: true,
                child: GestureDetector(
                  onDoubleTap: _onDoubleTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain, // Fit nicely inside
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: Colors.white, size: 64),
                            SizedBox(height: 16),
                            Text('Failed to load image',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
