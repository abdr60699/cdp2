import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;

import '../models/youtube_helper.dart';

class MediaGalleryPreview extends StatefulWidget {
  final List<String> mediaUrls;

  const MediaGalleryPreview({super.key, required this.mediaUrls});

  @override
  State<MediaGalleryPreview> createState() => _MediaGalleryPreviewState();
}

class _MediaGalleryPreviewState extends State<MediaGalleryPreview> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, YoutubePlayerController> _youtubeControllers = {};

  // Track rotation for each media item
  final Map<int, double> _rotationAngles = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Initialize rotation angles to 0 for all items
    for (int i = 0; i < widget.mediaUrls.length; i++) {
      _rotationAngles[i] = 0.0;
    }
  }

  @override
  void dispose() {
    // Properly dispose all YouTube controllers
    for (var controller in _youtubeControllers.values) {
      controller.close();
    }
    _youtubeControllers.clear();
    _pageController.dispose();
    super.dispose();
  }

  // Rotate current media item by 90 degrees (smart rotation - counterclockwise)
  void _rotateCurrentMedia() {
    setState(() {
      final currentAngle = _rotationAngles[_currentIndex]!;
      final currentDegrees = (currentAngle * 180 / math.pi) % 360;

      // Reverse rotation: counterclockwise cycle
      double newAngle;
      if (currentDegrees == 0) {
        newAngle = 3 * math.pi / 2; // 0° -> 270° (rotated left)
      } else if (currentDegrees == 270) {
        newAngle = math.pi; // 270° -> 180° (upside down)
      } else if (currentDegrees == 180) {
        newAngle = math.pi / 2; // 180° -> 90° (rotated right)
      } else {
        newAngle = 0; // 90° -> 0° (back to normal/straight)
      }

      _rotationAngles[_currentIndex] = newAngle;
    });
  }

  // Reset rotation for current media item
  void _resetRotation() {
    setState(() {
      _rotationAngles[_currentIndex] = 0.0;
    });
  }

  // Get appropriate rotation icon based on current rotation
  Widget _getRotationIcon() {
    final currentAngle = _rotationAngles[_currentIndex]!;
    final currentDegrees = (currentAngle * 180 / math.pi) % 360;

    if (currentDegrees == 90) {
      // At 90°, next click will go to 0° (straight)
      return const Icon(Icons.straighten, color: Colors.white, size: 20);
    } else {
      // For 0°, 270°, 180°, show rotate counterclockwise
      return const Icon(Icons.rotate_90_degrees_ccw,
          color: Colors.white, size: 20);
    }
  }

  // Get appropriate tooltip based on current rotation
  String _getRotationTooltip() {
    final currentAngle = _rotationAngles[_currentIndex]!;
    final currentDegrees = (currentAngle * 180 / math.pi) % 360;

    if (currentDegrees == 0) {
      return 'Rotate to 270°';
    } else if (currentDegrees == 270) {
      return 'Rotate to 180°';
    } else if (currentDegrees == 180) {
      return 'Rotate to 90°';
    } else {
      return 'Rotate to 0° (straight)';
    }
  }

  YoutubePlayerController _getYouTubeController(String videoId, int index) {
    if (_youtubeControllers[index] != null) {
      return _youtubeControllers[index]!;
    }

    try {
      final controller = YoutubePlayerController(
        initialVideoId: videoId,
        params: const YoutubePlayerParams(
          autoPlay: true,
          showControls: true,
          showFullscreenButton: true,
          enableCaption: false,
          privacyEnhanced: false,
          playsInline: true,
          mute: false,
          loop: false,
          enableJavaScript: true,
        ),
      );

      _youtubeControllers[index] = controller;
      return controller;
    } catch (e) {
      print('Error creating YouTube controller: $e');
      rethrow;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> downloadToGallery(String imageUrl, BuildContext context) async {
    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse(imageUrl));
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download",
              "property_${DateTime.now().millisecondsSinceEpoch}.jpg")
          ..click();
        html.Url.revokeObjectUrl(url);
        return;
      }

      final status = await _requestStoragePermission();
      if (!status) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permission denied - cannot save image')),
        );
        return;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: "property_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess']) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Image saved'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to save image to gallery');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt ?? 0;

      if (sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return false;
  }

  Widget _buildMediaItem(int index) {
    final url = widget.mediaUrls[index];
    final rotationAngle = _rotationAngles[index] ?? 0.0;

    Widget mediaWidget;

    if (YouTubeHelper.isYouTubeUrl(url)) {
      final videoId = YouTubeHelper.extractVideoId(url);
      if (videoId != null) {
        try {
          final controller = _getYouTubeController(videoId, index);

          mediaWidget = Container(
            color: Colors.black,
            child: Center(
              child: YoutubePlayerIFrame(
                controller: controller,
              ),
            ),
          );
        } catch (e) {
          print('Error creating YouTube player: $e');
          mediaWidget = Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    YouTubeHelper.getThumbnailUrl(videoId),
                    width: 300,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.video_library,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'YouTube Player Not Available',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('Open YouTube URL: $url');
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open in Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        mediaWidget = const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white70, size: 48),
              SizedBox(height: 16),
              Text(
                'Invalid YouTube URL',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        );
      }
    } else {
      // Regular image
      mediaWidget = InteractiveViewer(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading image...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.white70, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Apply rotation transform
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Transform.rotate(
        angle: rotationAngle,
        child: mediaWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No photos or videos available',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => _buildMediaItem(index),
          ),

          // Navigation controls for multiple items
          if (widget.mediaUrls.length > 1) ...[
            // Backward button
            Positioned(
              bottom: 40,
              left: 80,
              child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 32),
                  onPressed: () {
                    if (_currentIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  label: const Text('Prev')),
            ),

            // Forward button
            Positioned(
              bottom: 40,
              right: 80,
              child: TextButton.icon(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 32),
                  iconAlignment: IconAlignment.end,
                  onPressed: () {
                    if (_currentIndex < widget.mediaUrls.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  label: const Text('Next')),
            ),

            // Page indicator
            Positioned(
              bottom: 40,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],

          // Top control bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rotation controls
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: _getRotationIcon(),
                        onPressed: _rotateCurrentMedia,
                        label: const Text('Rotate',
                            style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      if (_rotationAngles[_currentIndex] != 0.0) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 18),
                          onPressed: _resetRotation,
                          tooltip: 'Reset rotation',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Download button for images (only show if current item is not a YouTube video)
                // if (!YouTubeHelper.isYouTubeUrl(widget.mediaUrls[_currentIndex]))
                //   FloatingActionButton(
                //     backgroundColor: Colors.black54,
                //     heroTag: "download",
                //     onPressed: () =>
                //         downloadToGallery(widget.mediaUrls[_currentIndex], context),
                //     child: const Icon(Icons.download, color: Colors.white),
                //   ),

                // Rotation angle indicator (only show if rotated)
                if (_rotationAngles[_currentIndex] != 0.0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${((_rotationAngles[_currentIndex]! * 180 / math.pi) % 360).round()}°',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Video indicator for YouTube videos
          if (YouTubeHelper.isYouTubeUrl(widget.mediaUrls[_currentIndex]))
            Positioned(
              bottom: 100,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'YouTube Video',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
