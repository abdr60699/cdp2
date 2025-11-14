import 'dart:math' show pi;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:checkdreamproperty/models/format_inr.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'models/clicl_track.dart';
import 'models/url_expander_service.dart';
import 'widgets/media_gallery_preview.dart';
import 'models/youtube_helper.dart';
// Import the click tracking service

class PropertyCard extends StatefulWidget {
  final Map<String, dynamic> property;
  final VoidCallback onPhonePressed;
  final VoidCallback onWhatsAppPressed;
  final VoidCallback? onMapPressed;
  final bool isMobile;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onPhonePressed,
    required this.onWhatsAppPressed,
    this.onMapPressed,
    required this.isMobile,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  final Map<String, String?> _expandedUrlCache = {};
  final Map<String, bool> _urlExpansionStatus = {};
  bool _isExpandingUrls = false;
  int _expandedCount = 0;
  int _totalUrlsToExpand = 0;
  final Map<String, double> _imageRotations = {};
  final Map<String, bool> _loadingPreview = {};
  // YouTube controllers map
  final Map<String, YoutubePlayerController> _youtubeControllers = {};
  final Set<String> _playingVideos = {};

  // Click tracking service
  final ClickTrackingService _clickTracker = ClickTrackingService();
  bool _hasTrackedView = false; // Prevent multiple view tracking

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _expandImageUrls();

    // Track property view when card is initialized
    _trackPropertyView();
  }


Widget _buildCarouselItem(String originalUrl) {
  final expandedUrl = _getExpandedUrl(originalUrl);
  final isBeingExpanded = _isUrlBeingExpanded(originalUrl);
  final currentRotation = _imageRotations[originalUrl] ?? 0.0;
  final isLoadingPreview = _loadingPreview[originalUrl] ?? false;

  // Show loading indicator if URL is being expanded
  if (isBeingExpanded) {
    return Container(
      width: double.infinity,
      height: 230,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Expanding URL...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget carouselContent;

  if (YouTubeHelper.isYouTubeUrl(expandedUrl)) {
    final videoId = YouTubeHelper.extractVideoId(expandedUrl);
    if (videoId != null) {
      carouselContent = Stack(
        children: [
          Image.network(
            YouTubeHelper.getThumbnailUrl(videoId),
            width: double.infinity,
            height: 230,
            fit: BoxFit.cover,
            loadingBuilder: _buildImageLoadingBuilder,
            errorBuilder: (context, error, stackTrace) =>
                _buildYouTubeErrorWidget(),
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      );
    } else {
      carouselContent = _buildYouTubeErrorWidget();
    }
  } else {
    carouselContent = Transform.rotate(
      angle: currentRotation,
      child: Image.network(
        expandedUrl,
        width: double.infinity,
        height: 230,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: double.infinity,
            height: 230,
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget(originalUrl, expandedUrl);
        },
      ),
    );
  }

  return Stack(
    children: [
      // Base container to ensure proper sizing
      Container(
        width: double.infinity,
        height: 230,
        child: carouselContent,
      ),

      // Gesture detection layer
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {},
          onPanUpdate: (_) {},
          onPanEnd: (_) {},
          onTapDown: isLoadingPreview ? null : (details) async {
            if (_loadingPreview[originalUrl] == true) return;
            
            setState(() {
              _loadingPreview[originalUrl] = true;
            });

            await Future.delayed(const Duration(milliseconds: 50));

            try {
              final processedUrls = _getProcessedImageUrls();
              if (processedUrls.isNotEmpty) {
                await _trackMediaGalleryClick();
                if (mounted) {
                  await showDialog(
                    context: context,
                    builder: (_) => MediaGalleryPreview(
                      mediaUrls: processedUrls,
                    ),
                  );
                }
              }
            } catch (e) {
              print('Error opening media gallery: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to open media gallery'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _loadingPreview[originalUrl] = false;
                });
              }
            }
          },
          onTap: isLoadingPreview ? null : () async {
            if (_loadingPreview[originalUrl] != true) {
              setState(() {
                _loadingPreview[originalUrl] = true;
              });

              await Future.delayed(const Duration(milliseconds: 50));

              try {
                final processedUrls = _getProcessedImageUrls();
                if (processedUrls.isNotEmpty) {
                  await _trackMediaGalleryClick();
                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (_) => MediaGalleryPreview(
                        mediaUrls: processedUrls,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error opening media gallery: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to open media gallery'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _loadingPreview[originalUrl] = false;
                  });
                }
              }
            }
          },
          child: Container(color: Colors.transparent),
        ),
      ),

      // Loading overlay when opening preview
      if (isLoadingPreview)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Opening ...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      // Rotation controls
      Positioned(
        bottom: 12,
        left: 12,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _imageRotations[originalUrl] = 
                          (currentRotation - (pi / 2)) % (2 * pi);
                    });
                  },
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.rotate_left,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.3),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _imageRotations[originalUrl] = 
                          (currentRotation + (pi / 2)) % (2 * pi);
                    });
                  },
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.rotate_right,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Tap hint indicator
     
    ],
  );
}

// IMPROVED: Better loading builder that ALWAYS shows loading first
Widget _buildImageLoadingBuilder(
    BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
  if (loadingProgress == null) return child;

  return Container(
    width: double.infinity,
    height: 230,
    color: Colors.grey[100],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading image...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (loadingProgress.expectedTotalBytes != null) ...[
            const SizedBox(height: 8),
            Text(
              '${(loadingProgress.cumulativeBytesLoaded / 1024).toStringAsFixed(1)} KB / ${(loadingProgress.expectedTotalBytes! / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

// ENHANCED: Better carousel with loading states
Widget _buildImageCarousel(String? propertyStatus) {
  final images = getListValue('images');
  final imageStrings =
      images.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();

  if (imageStrings.isEmpty) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No photos or videos available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    child: SizedBox(
      height: 230,
      width: double.infinity,
      child: Stack(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              viewportFraction: 1.0,
              // ENHANCED: Better auto-play logic
              autoPlay: !_isExpandingUrls && 
                       !_hasUrlsBeingExpanded() && 
                       !_hasLoadingImages(), // Don't auto-play while any image is loading
              autoPlayInterval: const Duration(seconds: 4),
              height: 230,
              enableInfiniteScroll: imageStrings.length > 1,
              pauseAutoPlayOnTouch: true, // Pause on user interaction
              pauseAutoPlayOnManualNavigate: true,
            ),
            items: imageStrings.map((url) => _buildCarouselItem(url)).toList(),
          ),
          
          // Enhanced progress indicator
          if (_isExpandingUrls || _hasUrlsBeingExpanded())
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _totalUrlsToExpand > 0
                            ? _expandedCount / _totalUrlsToExpand
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isExpandingUrls
                          ? 'Processing $_expandedCount/$_totalUrlsToExpand'
                          : 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Image counter with enhanced styling
          if (imageStrings.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.collections,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${imageStrings.length} items',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Property status badge
          if (propertyStatus != null && propertyStatus.isNotEmpty && propertyStatus != 'none')
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  propertyStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// NEW: Helper method to check if any images are currently loading
bool _hasLoadingImages() {
  return _loadingPreview.values.any((isLoading) => isLoading);
}

  // Track property view (only once per card instance)
  Future<void> _trackPropertyView() async {
    if (_hasTrackedView) return;

    final propertyId = getNumericValue('main_id', 0).toInt();
    if (propertyId > 0) {
      // await _clickTracker.trackPropertyView(propertyId);
      _hasTrackedView = true;
    }
  }

  // Track phone button click
  Future<void> _trackPhoneClick() async {
    final propertyId = getNumericValue('main_id', 0).toInt();
    if (propertyId > 0) {
      // await _clickTracker.trackPhoneClick(propertyId);
    }
    widget.onPhonePressed();
  }

  // Track WhatsApp button click
  Future<void> _trackWhatsAppClick() async {
    final propertyId = getNumericValue('main_id', 0).toInt();
    if (propertyId > 0) {
      // await _clickTracker.trackWhatsAppClick(propertyId);
    }
    widget.onWhatsAppPressed();
  }

  // Track Map button click
  Future<void> _trackMapClick() async {
    final propertyId = getNumericValue('main_id', 0).toInt();
    if (propertyId > 0) {
      // await _clickTracker.trackMapClick(propertyId);
    }
    if (widget.onMapPressed != null) {
      widget.onMapPressed!();
    }
  }

  // Track details expansion click
  Future<void> _trackDetailsClick() async {
    final propertyId = getNumericValue('main_id', 0).toInt();
    if (propertyId > 0) {
      // await _clickTracker.trackDetailsClick(propertyId);
    }
  }

  // Track media gallery click
  Future<void> _trackMediaGalleryClick() async {
    final propertyId = getNumericValue('main_id', 0).toInt();
    if (propertyId > 0) {
      // await _clickTracker.trackPropertyClick(
      //     propertyId: propertyId, clickType: 'media_gallery');
    }
  }

  Future<void> _expandImageUrls() async {
    final images = getListValue('images');
    final imageUrls =
        images.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();

    if (imageUrls.isEmpty) return;

    // Initialize expansion status for all URLs
    for (final url in imageUrls) {
      if (!_urlExpansionStatus.containsKey(url)) {
        _urlExpansionStatus[url] = DioUrlExpanderService.needsExpansion(url);
      }
    }

    // Check which URLs need expansion (skip YouTube URLs)
    final urlsToExpand = imageUrls
        .where((url) =>
            !YouTubeHelper.isYouTubeUrl(url) && // Skip YouTube URLs
            DioUrlExpanderService.needsExpansion(url) &&
            !_expandedUrlCache.containsKey(url))
        .toList();

    if (urlsToExpand.isEmpty) return;

    setState(() {
      _isExpandingUrls = true;
      _expandedCount = 0;
      _totalUrlsToExpand = urlsToExpand.length;
    });

    try {
      // Process URLs individually to update UI progressively
      for (int i = 0; i < urlsToExpand.length; i++) {
        final url = urlsToExpand[i];

        try {
          final expandedUrl = await DioUrlExpanderService.expandUrl(url);

          if (mounted) {
            setState(() {
              _expandedUrlCache[url] = expandedUrl;
              _urlExpansionStatus[url] = false; // Mark as completed
              _expandedCount = i + 1;
            });
          }

          // Small delay to prevent overwhelming the UI
          if (i < urlsToExpand.length - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e) {
          print('Error expanding URL $url: $e');
          if (mounted) {
            setState(() {
              _expandedUrlCache[url] = url; // Fallback to original URL
              _urlExpansionStatus[url] =
                  false; // Mark as completed (with fallback)
              _expandedCount = i + 1;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isExpandingUrls = false;
        });
      }
    } catch (e) {
      print('Error expanding URLs: $e');
      if (mounted) {
        setState(() {
          _isExpandingUrls = false;
        });
      }
    }
  }

  /// Get the expanded URL or original URL if expansion failed/not needed
  String _getExpandedUrl(String originalUrl) {
    // Don't expand YouTube URLs
    if (YouTubeHelper.isYouTubeUrl(originalUrl)) {
      return originalUrl;
    }

    if (_expandedUrlCache.containsKey(originalUrl)) {
      return _expandedUrlCache[originalUrl] ?? originalUrl;
    }
    return originalUrl;
  }

  /// Check if a URL is still being expanded
  bool _isUrlBeingExpanded(String url) {
    // YouTube URLs are never being expanded
    if (YouTubeHelper.isYouTubeUrl(url)) {
      return false;
    }
    return _urlExpansionStatus[url] == true;
  }

  /// Get list of processed image URLs (expanded where possible)
  List<String> _getProcessedImageUrls() {
    final images = getListValue('images');
    return images
        .map((e) => e.toString())
        .where((url) => url.isNotEmpty)
        .map((url) => _getExpandedUrl(url))
        .toList();
  }



  Widget _buildYouTubeErrorWidget() {
    return Container(
      width: double.infinity,
      height: 230,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.youtube,
                size: 24,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                'YouTube Video',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   ' Thumbnail not available',
              //   style: TextStyle(
              //     color: Colors.grey[600],
              //     fontSize: 14,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageErrorWidget(String originalUrl, String expandedUrl) {
    return Container(
      width: double.infinity,
      height: 230,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }



  bool _hasUrlsBeingExpanded() {
    return _urlExpansionStatus.values.any((isExpanding) => isExpanding);
  }

  // Helper methods remain the same
  dynamic getPropertyValue(String key, [dynamic defaultValue]) {
    try {
      // First check if the property has a 'property_data' nested structure
      if (widget.property.containsKey('property_data') &&
          widget.property['property_data'] is Map) {
        final propertyData =
            widget.property['property_data'] as Map<String, dynamic>;
        if (propertyData.containsKey(key)) {
          return propertyData[key] ?? defaultValue;
        }
      }

      // Fallback to direct access for backward compatibility
      return widget.property[key] ?? defaultValue;
    } catch (e) {
      print('Error accessing property key $key: $e');
      return defaultValue;
    }
  }

  String getPhoneNumber() {
    try {
      // Check nested structure first
      if (widget.property.containsKey('property_data') &&
          widget.property['property_data'] is Map) {
        final propertyData =
            widget.property['property_data'] as Map<String, dynamic>;
        if (propertyData.containsKey('contact') &&
            propertyData['contact'] is Map) {
          final contact = propertyData['contact'] as Map<String, dynamic>;
          return contact['phone']?.toString() ?? '';
        }
      }

      // Fallback to direct access
      if (widget.property.containsKey('contact') &&
          widget.property['contact'] is Map) {
        final contact = widget.property['contact'] as Map<String, dynamic>;
        return contact['phone']?.toString() ?? '';
      }

      return widget.property['phone']?.toString() ?? '';
    } catch (e) {
      print('Error accessing phone number: $e');
      return '';
    }
  }

  String getWhatsAppNumber() {
    try {
      // Check nested structure first
      if (widget.property.containsKey('property_data') &&
          widget.property['property_data'] is Map) {
        final propertyData =
            widget.property['property_data'] as Map<String, dynamic>;
        if (propertyData.containsKey('contact') &&
            propertyData['contact'] is Map) {
          final contact = propertyData['contact'] as Map<String, dynamic>;
          return contact['whatsapp']?.toString() ?? '';
        }
      }

      // Fallback to direct access
      if (widget.property.containsKey('contact') &&
          widget.property['contact'] is Map) {
        final contact = widget.property['contact'] as Map<String, dynamic>;
        return contact['whatsapp']?.toString() ?? '';
      }

      return widget.property['whatsapp']?.toString() ?? '';
    } catch (e) {
      print('Error accessing WhatsApp number: $e');
      return '';
    }
  }

  num getNumericValue(String key, [num defaultValue = 0]) {
    final value = getPropertyValue(key, defaultValue);
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  String getStringValue(String key, [String defaultValue = '']) {
    final value = getPropertyValue(key, defaultValue);
    return value?.toString() ?? defaultValue;
  }

  bool getBoolValue(String key, [bool defaultValue = false]) {
    final value = getPropertyValue(key, defaultValue);
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  List<dynamic> getListValue(String key, [List<dynamic>? defaultValue]) {
    final value = getPropertyValue(key, defaultValue);
    if (value is List) return value;
    return defaultValue ?? [];
  }

  void _toggleExpansion() async {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    // Track details expansion click
    if (_isExpanded) {
      await _trackDetailsClick();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Dispose YouTube controllers
    for (var controller in _youtubeControllers.values) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth < 600;
    final titleFontSize = isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
    final locationFontSize =
        isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 15.0);
    final priceFontSize = isSmallScreen ? 15.0 : (isMediumScreen ? 16.0 : 18.0);
    final detailFontSize =
        isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 15.0);
    final buttonFontSize =
        isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
    final smallTextFontSize =
        isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
    final smallIconSize = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);

    // Get property values safely
    final forRent = getBoolValue('forRent', false);
    final rentAmount = getNumericValue('rentAmount', 0);
    final price = getNumericValue('price', 0);
    final squareFeet = getNumericValue('squareFeet', 0);
    final bedrooms = getNumericValue('bedrooms', 0);
    final builtupArea = getNumericValue('builtupArea', 0);
    final grounds = getNumericValue('grounds', 0);
    final waterTax = getNumericValue('waterTax', 0);
    final propertyTax = getNumericValue('propertyTax', 0);
    final bathrooms = getNumericValue('bathrooms', 0);
    final ageYears = getNumericValue('ageYears', 0);
    final landmarks = getListValue('landmarks', []);
    final propertyType = getStringValue('type', 'N/A');
    final city = getStringValue('city', 'N/A');
    final title = getStringValue('title', 'No title');
    final location = getStringValue('location', 'No location');
    final images = getListValue('images', []);

    // NEW FIELDS
    final purpose = getStringValue('purpose', 'For Sale');
    final propertyStatus = getStringValue('propertyStatus', 'Resale');
    final furnishingStatus = getStringValue('furnishingStatus', 'Unfurnished');
    final ownerType = getStringValue('ownerType', 'Owner');
    final negotiablePrice = getBoolValue('negotiablePrice', false);
    final parkingAvailable = getBoolValue('parkingAvailable', false);
    final balconyAvailable = getBoolValue('balconyAvailable', false);
    final urgentSale = getBoolValue('urgentSale', false);
    final maintenanceCharges = getNumericValue('maintenanceCharges', 0);
    final depositAmount = getNumericValue('depositAmount', 0);
    final floorNumber = getNumericValue('floorNumber', 0);
    final totalFloors = getNumericValue('totalFloors', 0);
    final numberOfBalconies = getNumericValue('numberOfBalconies', 0);
    final numberOfParking = getNumericValue('numberOfParking', 0);
    final contactPersonName = getStringValue('contactPersonName', '');
    final description = getStringValue('description', '');

    // Handle landmarks
    List<dynamic> allLandmarks = landmarks;
    if (allLandmarks.isEmpty) {
      final singleLandmark = getStringValue('landmark', '');
      if (singleLandmark.isNotEmpty) {
        allLandmarks = [singleLandmark];
      }
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageCarousel(propertyStatus),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: smallIconSize),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(fontSize: locationFontSize),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price with negotiable indicator
                    Row(
                      children: [
                        Text(
                          forRent
                              ? '₹${rentAmount.toStringAsFixed(0)}/month'
                              : '₹${Inr.formatIndianNumber(price.toInt().toString())}',
                          style: TextStyle(
                            fontSize: priceFontSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (negotiablePrice)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEGOTIABLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // const SizedBox(width: 2),
                        // Container(
                        //   margin: const EdgeInsets.only(left: 8),
                        //   padding: const EdgeInsets.symmetric(
                        //       horizontal: 4, vertical: 2),
                        //   decoration: BoxDecoration(
                        //     color: Colors.blue,
                        //     borderRadius: BorderRadius.circular(4),
                        //   ),
                        //   child: Text(
                        //     propertyStatus.toUpperCase(),
                        //     style: const TextStyle(
                        //       color: Colors.white,
                        //       fontSize: 8,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                        const Spacer(),
                        if (urgentSale)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'URGENT SALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: smallTextFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Property details
                    Wrap(
                      spacing: 16,
                      children: [
                        if (squareFeet > 0)
                          _buildPropertyDetail(
                              Icons.straighten,
                              '${squareFeet.toStringAsFixed(0)} sq.ft',
                              detailFontSize,
                              smallIconSize),
                        if (bedrooms > 0)
                          _buildPropertyDetail(
                              Icons.bed,
                              '${bedrooms.toStringAsFixed(0)} BHK',
                              detailFontSize,
                              smallIconSize),
                        if (parkingAvailable)
                          _buildPropertyDetail(
                              Icons.local_parking,
                              numberOfParking > 0
                                  ? '${numberOfParking.toInt()} Parking'
                                  : 'Parking',
                              detailFontSize,
                              smallIconSize),
                      ],
                    ),

                    // Expanded section
                    AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: _expandAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 20),

                          // Contact Person
                          if (contactPersonName.isNotEmpty)
                            _buildDetailRow('Contact Person', contactPersonName,
                                smallTextFontSize),

                          // Floor Information
                          if (floorNumber > 0 && totalFloors > 0)
                            _buildDetailRow(
                                'Floor',
                                '${floorNumber.toInt()} of ${totalFloors.toInt()}',
                                smallTextFontSize)
                          else if (floorNumber > 0)
                            _buildDetailRow('Floor', '${floorNumber.toInt()}',
                                smallTextFontSize),

                          // Furnishing Status
                          if (furnishingStatus.isNotEmpty &&
                              furnishingStatus != 'none')
                            _buildDetailRow('Furnishing', furnishingStatus,
                                smallTextFontSize),
                          if (rentAmount > 0)
                            _buildDetailRow('Monthily Income For Rent',
                                rentAmount.toString(), smallTextFontSize),

                          // Owner Type
                          if (ownerType.isNotEmpty && ownerType != 'none')
                            _buildDetailRow(
                                'Listed by', ownerType, smallTextFontSize),

                          // Other details
                          if (maintenanceCharges > 0)
                            _buildDetailRow(
                                'Maintenance',
                                '₹${maintenanceCharges.toStringAsFixed(0)}/month',
                                smallTextFontSize),

                          if (purpose == 'For Rent' && depositAmount > 0)
                            _buildDetailRow(
                                'Deposit',
                                '₹${depositAmount.toStringAsFixed(0)}',
                                smallTextFontSize),

                          if (builtupArea > 0)
                            _buildDetailRow(
                                'Built-up Area',
                                '${builtupArea.toStringAsFixed(0)} sq.ft',
                                smallTextFontSize),
                          if (grounds > 0)
                            _buildDetailRow('Grounds',
                                grounds.toStringAsFixed(1), smallTextFontSize),
                          if (allLandmarks.isNotEmpty)
                            _buildDetailRow(
                                'Landmark',
                                allLandmarks.first.toString(),
                                smallTextFontSize),
                          if (waterTax > 0)
                            _buildDetailRow(
                                'Water Tax',
                                '₹${waterTax.toStringAsFixed(0)}/year',
                                smallTextFontSize),
                          if (propertyTax > 0)
                            _buildDetailRow(
                                'Property Tax',
                                '₹${propertyTax.toStringAsFixed(0)}/year',
                                smallTextFontSize),
                          if (ageYears > 0)
                            _buildDetailRow(
                                'Building Age',
                                '${ageYears.toStringAsFixed(0)} years',
                                smallTextFontSize),
                          _buildDetailRow(
                              'Type', propertyType, smallTextFontSize),
                          _buildDetailRow('City', city, smallTextFontSize),
                          if (bathrooms > 0)
                            _buildDetailRow(
                                'Bath',
                                bathrooms.toStringAsFixed(0),
                                smallTextFontSize),
                          if (numberOfBalconies > 0)
                            _buildDetailRow(
                                'Balcony',
                                numberOfBalconies.toInt().toString(),
                                smallTextFontSize),

                          // Description
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description:',
                                    style: TextStyle(
                                      fontSize: smallTextFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style:
                                        TextStyle(fontSize: smallTextFontSize),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _toggleExpansion,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded
                                    ? 'Show Less Details'
                                    : 'Show More Details',
                                style: TextStyle(
                                  fontSize: smallTextFontSize,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: smallIconSize,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        if (images.isNotEmpty)
                          TextButton.icon(
                            onPressed: () async {
                              final processedUrls = _getProcessedImageUrls();
                              if (processedUrls.isNotEmpty) {
                                await _trackMediaGalleryClick();
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => MediaGalleryPreview(
                                      mediaUrls: processedUrls,
                                    ),
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 8),
                            ),
                            icon: Icon(
                              Icons.photo_library,
                              size: smallIconSize,
                              color: Colors.blue,
                            ),
                            label: Text(
                              'View All Media',
                              style: TextStyle(
                                  fontSize: smallTextFontSize,
                                  color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (getStringValue('mapLink').isNotEmpty) ...[
                          SizedBox(
                            width: 80,
                            child: ElevatedButton.icon(
                              onPressed: _trackMapClick,
                              icon:
                                  Icon(Icons.location_on, size: smallIconSize),
                              label: Text(
                                'Map',
                                style: TextStyle(fontSize: buttonFontSize),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _trackPhoneClick,
                            icon: Icon(Icons.phone, size: smallIconSize),
                            label: Text(
                              'Phone',
                              style: TextStyle(fontSize: buttonFontSize),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _trackWhatsAppClick,
                            icon: Icon(FontAwesomeIcons.whatsapp,
                                size: smallIconSize),
                            label: Text(
                              'WhatsApp',
                              style: TextStyle(fontSize: buttonFontSize),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDetail(
      IconData icon, String text, double fontSize, double iconSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
///
///
///
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// import 'models/url_expander_service.dart';
// import 'widgets/media_gallery_preview.dart';
// import 'models/youtube_helper.dart';

// class PropertyCard extends StatefulWidget {
//   final Map<String, dynamic> property;
//   final VoidCallback onPhonePressed;
//   final VoidCallback onWhatsAppPressed;
//   final VoidCallback? onMapPressed;
//   final bool isMobile;

//   const PropertyCard({
//     super.key,
//     required this.property,
//     required this.onPhonePressed,
//     required this.onWhatsAppPressed,
//      this.onMapPressed,
//     required this.isMobile,
//   });

//   @override
//   State<PropertyCard> createState() => _PropertyCardState();
// }

// class _PropertyCardState extends State<PropertyCard>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   late AnimationController _controller;
//   late Animation<double> _expandAnimation;

//   final Map<String, String?> _expandedUrlCache = {};
//   final Map<String, bool> _urlExpansionStatus = {};
//   bool _isExpandingUrls = false;
//   int _expandedCount = 0;
//   int _totalUrlsToExpand = 0;

//   // YouTube controllers map
//   final Map<String, YoutubePlayerController> _youtubeControllers = {};
//   final Set<String> _playingVideos = {};

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _expandAnimation =
//         CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//     _expandImageUrls();
//   }

//   Future<void> _expandImageUrls() async {
//     final images = getListValue('images');
//     final imageUrls =
//         images.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();

//     if (imageUrls.isEmpty) return;

//     // Initialize expansion status for all URLs
//     for (final url in imageUrls) {
//       if (!_urlExpansionStatus.containsKey(url)) {
//         _urlExpansionStatus[url] = DioUrlExpanderService.needsExpansion(url);
//       }
//     }

//     // Check which URLs need expansion (skip YouTube URLs)
//     final urlsToExpand = imageUrls
//         .where((url) =>
//             !YouTubeHelper.isYouTubeUrl(url) && // Skip YouTube URLs
//             DioUrlExpanderService.needsExpansion(url) &&
//             !_expandedUrlCache.containsKey(url))
//         .toList();

//     if (urlsToExpand.isEmpty) return;

//     setState(() {
//       _isExpandingUrls = true;
//       _expandedCount = 0;
//       _totalUrlsToExpand = urlsToExpand.length;
//     });

//     try {
//       // Process URLs individually to update UI progressively
//       for (int i = 0; i < urlsToExpand.length; i++) {
//         final url = urlsToExpand[i];

//         try {
//           final expandedUrl = await DioUrlExpanderService.expandUrl(url);

//           if (mounted) {
//             setState(() {
//               _expandedUrlCache[url] = expandedUrl;
//               _urlExpansionStatus[url] = false; // Mark as completed
//               _expandedCount = i + 1;
//             });
//           }

//           // Small delay to prevent overwhelming the UI
//           if (i < urlsToExpand.length - 1) {
//             await Future.delayed(const Duration(milliseconds: 100));
//           }
//         } catch (e) {
//           print('Error expanding URL $url: $e');
//           if (mounted) {
//             setState(() {
//               _expandedUrlCache[url] = url; // Fallback to original URL
//               _urlExpansionStatus[url] =
//                   false; // Mark as completed (with fallback)
//               _expandedCount = i + 1;
//             });
//           }
//         }
//       }

//       if (mounted) {
//         setState(() {
//           _isExpandingUrls = false;
//         });
//       }
//     } catch (e) {
//       print('Error expanding URLs: $e');
//       if (mounted) {
//         setState(() {
//           _isExpandingUrls = false;
//         });
//       }
//     }
//   }

//   /// Get the expanded URL or original URL if expansion failed/not needed
//   String _getExpandedUrl(String originalUrl) {
//     // Don't expand YouTube URLs
//     if (YouTubeHelper.isYouTubeUrl(originalUrl)) {
//       return originalUrl;
//     }

//     if (_expandedUrlCache.containsKey(originalUrl)) {
//       return _expandedUrlCache[originalUrl] ?? originalUrl;
//     }
//     return originalUrl;
//   }

//   /// Check if a URL is still being expanded
//   bool _isUrlBeingExpanded(String url) {
//     // YouTube URLs are never being expanded
//     if (YouTubeHelper.isYouTubeUrl(url)) {
//       return false;
//     }
//     return _urlExpansionStatus[url] == true;
//   }

//   /// Get list of processed image URLs (expanded where possible)
//   List<String> _getProcessedImageUrls() {
//     final images = getListValue('images');
//     return images
//         .map((e) => e.toString())
//         .where((url) => url.isNotEmpty)
//         .map((url) => _getExpandedUrl(url))
//         .toList();
//   }

//   /// Test URL accessibility and get info
//   Future<void> _testUrl(String url) async {
//     final info = await DioUrlExpanderService.getUrlInfo(url);

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content:
//               Text('URL Test: ${info['isAccessible'] ? 'Success' : 'Failed'}'),
//           backgroundColor: info['isAccessible'] ? Colors.green : Colors.red,
//         ),
//       );
//     }
//   }

//   Widget _buildCarouselItem(String originalUrl) {
//     final expandedUrl = _getExpandedUrl(originalUrl);
//     final isBeingExpanded = _isUrlBeingExpanded(originalUrl);

//     // Show loading indicator if URL is being expanded
//     if (isBeingExpanded) {
//       return Container(
//         width: double.infinity,
//         height: 230,
//         color: Colors.grey[100],
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   Theme.of(context).primaryColor,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Expanding URL...',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 14,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 originalUrl.length > 30
//                     ? '${originalUrl.substring(0, 30)}...'
//                     : originalUrl,
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                   fontSize: 12,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     Widget carouselContent;

//     if (YouTubeHelper.isYouTubeUrl(expandedUrl)) {
//       final videoId = YouTubeHelper.extractVideoId(expandedUrl);
//       if (videoId != null) {
//         carouselContent = Stack(
//           children: [
//             Image.network(
//               YouTubeHelper.getThumbnailUrl(videoId),
//               width: double.infinity,
//               height: 180,
//               fit: BoxFit.cover,
//               loadingBuilder: _buildImageLoadingBuilder,
//               errorBuilder: (context, error, stackTrace) =>
//                   _buildImageErrorWidget(originalUrl, expandedUrl),
//             ),
//             Center(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.8),
//                   shape: BoxShape.circle,
//                 ),
//                 padding: const EdgeInsets.all(12),
//                 child: const Icon(
//                   Icons.play_arrow,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//             ),
//           ],
//         );
//       } else {
//         carouselContent = _buildImageErrorWidget(originalUrl, expandedUrl);
//       }
//     } else {
//       carouselContent = Image.network(
//         expandedUrl,
//         width: double.infinity,
//         height: 180,
//         fit: BoxFit.cover,
//         loadingBuilder: _buildImageLoadingBuilder,
//         errorBuilder: (context, error, stackTrace) {
//           return _buildImageErrorWidget(originalUrl, expandedUrl);
//         },
//       );
//     }

//     return GestureDetector(
//       onTap: () {
//         final processedUrls = _getProcessedImageUrls();
//         if (processedUrls.isNotEmpty) {
//           showDialog(
//             context: context,
//             builder: (_) => MediaGalleryPreview(
//               mediaUrls: processedUrls,
//             ),
//           );
//         }
//       },
//       child: carouselContent,
//     );
//   }

//   Widget _buildImageLoadingBuilder(
//       BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
//     if (loadingProgress == null) return child;

//     return Container(
//       width: double.infinity,
//       height: 180,
//       color: Colors.grey[100],
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(
//               width: 40,
//               height: 40,
//               child: CircularProgressIndicator(
//                 value: loadingProgress.expectedTotalBytes != null
//                     ? loadingProgress.cumulativeBytesLoaded /
//                         loadingProgress.expectedTotalBytes!
//                     : null,
//                 strokeWidth: 3,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   Theme.of(context).primaryColor,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Loading image...',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//             if (loadingProgress.expectedTotalBytes != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 '${(loadingProgress.cumulativeBytesLoaded / 1024).toStringAsFixed(1)} KB / ${(loadingProgress.expectedTotalBytes! / 1024).toStringAsFixed(1)} KB',
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImageErrorWidget(String originalUrl, String expandedUrl) {
//     return Container(
//       width: double.infinity,
//       height: 180,
//       color: Colors.grey[200],
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.broken_image,
//             size: 48,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Image not available',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           ElevatedButton.icon(
//             onPressed: () => _testUrl(expandedUrl),
//             icon: const Icon(Icons.refresh, size: 16),
//             label: const Text('Retry'),
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size(100, 32),
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//               textStyle: const TextStyle(fontSize: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImageCarousel() {
//     final images = getListValue('images');
//     final imageStrings =
//         images.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();

//     if (imageStrings.isEmpty) {
//       return Container(
//         height: 250,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.photo_library,
//                 size: 48,
//                 color: Colors.grey[400],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'No photos or videos available',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//       child: SizedBox(
//         height: 180,
//         width: double.infinity,
//         child: Stack(
//           children: [
//             CarouselSlider(
//               options: CarouselOptions(
//                 viewportFraction: 1.0,
//                 autoPlay: !_isExpandingUrls &&
//                     !_hasUrlsBeingExpanded(), // Don't auto-play while expanding URLs
//                 autoPlayInterval: const Duration(seconds: 4),
//                 height: 180,
//                 enableInfiniteScroll: imageStrings.length > 1,
//               ),
//               items:
//                   imageStrings.map((url) => _buildCarouselItem(url)).toList(),
//             ),
//             // Overall progress indicator
//             if (_isExpandingUrls || _hasUrlsBeingExpanded())
//               Positioned(
//                 top: 12,
//                 right: 12,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.7),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       SizedBox(
//                         width: 14,
//                         height: 14,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           value: _totalUrlsToExpand > 0
//                               ? _expandedCount / _totalUrlsToExpand
//                               : null,
//                           valueColor:
//                               const AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         _isExpandingUrls
//                             ? 'Processing... ($_expandedCount/$_totalUrlsToExpand)'
//                             : 'Loading...',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             // Image counter
//             if (imageStrings.length > 1)
//               Positioned(
//                 bottom: 12,
//                 right: 12,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${imageStrings.length} items',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   bool _hasUrlsBeingExpanded() {
//     return _urlExpansionStatus.values.any((isExpanding) => isExpanding);
//   }

//   // Helper methods remain the same
//   dynamic getPropertyValue(String key, [dynamic defaultValue]) {
//     try {
//       return widget.property[key] ?? defaultValue;
//     } catch (e) {
//       print('Error accessing property key $key: $e');
//       return defaultValue;
//     }
//   }

//   num getNumericValue(String key, [num defaultValue = 0]) {
//     final value = getPropertyValue(key, defaultValue);
//     if (value is num) return value;
//     if (value is String) {
//       return num.tryParse(value) ?? defaultValue;
//     }
//     return defaultValue;
//   }

//   String getStringValue(String key, [String defaultValue = '']) {
//     final value = getPropertyValue(key, defaultValue);
//     return value?.toString() ?? defaultValue;
//   }

//   bool getBoolValue(String key, [bool defaultValue = false]) {
//     final value = getPropertyValue(key, defaultValue);
//     if (value is bool) return value;
//     if (value is String) {
//       return value.toLowerCase() == 'true';
//     }
//     return defaultValue;
//   }

//   List<dynamic> getListValue(String key, [List<dynamic>? defaultValue]) {
//     final value = getPropertyValue(key, defaultValue);
//     if (value is List) return value;
//     return defaultValue ?? [];
//   }

//   void _toggleExpansion() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     // Dispose YouTube controllers
//     for (var controller in _youtubeControllers.values) {
//       controller.close();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;
//     final isMediumScreen = screenWidth < 600;
//     final titleFontSize = isSmallScreen ? 13.0 : (isMediumScreen ? 15.0 : 16.0);
//     final locationFontSize =
//         isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 15.0);
//     final priceFontSize = isSmallScreen ? 15.0 : (isMediumScreen ? 16.0 : 18.0);
//     final detailFontSize =
//         isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 15.0);
//     final buttonFontSize =
//         isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
//     final smallTextFontSize =
//         isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);
//     final smallIconSize = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);

//     // Get property values safely
//     final forRent = getBoolValue('forRent');
//     final rentAmount = getNumericValue('rentAmount');
//     final price = getNumericValue('price');
//     final squareFeet = getNumericValue('squareFeet');
//     final bedrooms = getNumericValue('bedrooms');
//     final builtupArea = getNumericValue('builtupArea');
//     final grounds = getNumericValue('grounds');
//     final waterTax = getNumericValue('waterTax');
//     final propertyTax = getNumericValue('propertyTax');
//     final bathrooms = getNumericValue('bathrooms');
//     final ageYears = getNumericValue('ageYears');
//     final landmarks = getListValue('landmarks');
//     final propertyType = getStringValue('type', 'N/A');
//     final city = getStringValue('city', 'N/A');
//     final title = getStringValue('title', 'No title');
//     final location = getStringValue('location', 'No location');
//     final images = getListValue('images');

//     // Handle landmarks - check for both 'landmarks' and 'landmark'
//     List<dynamic> allLandmarks = landmarks;
//     if (allLandmarks.isEmpty) {
//       final singleLandmark = getStringValue('landmark');
//       if (singleLandmark.isNotEmpty) {
//         allLandmarks = [singleLandmark];
//       }
//     }

//     return Card(
//       color: Colors
//           .white, // Pure white instead of Color.fromARGB(255, 250, 247, 247)
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 8, // Reduce elevation for subtler shadow
//       shadowColor: Colors.black.withOpacity(0.4), // Enhanced shadow visibility
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildImageCarousel(),
//             Flexible(
//               child: Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: titleFontSize,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.location_on,
//                           size: smallIconSize,
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: Text(
//                             location,
//                             style: TextStyle(
//                               fontSize: locationFontSize,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         )
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       forRent
//                           ? '₹${rentAmount.toStringAsFixed(0)}/month'
//                           : price >= 100000
//                               ? '₹${(price / 100000).toStringAsFixed(1)} Lakhs'
//                               : '₹${price.toStringAsFixed(0)}',
//                       style: TextStyle(
//                         fontSize: priceFontSize,
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).colorScheme.primary,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 12,
//                       runSpacing: 6,
//                       children: [
//                         if (squareFeet > 0)
//                           _buildPropertyDetail(
//                               Icons.straighten,
//                               '${squareFeet.toStringAsFixed(0)} sq.ft',
//                               detailFontSize,
//                               smallIconSize),
//                         if (bedrooms > 0)
//                           _buildPropertyDetail(
//                               Icons.bed,
//                               '${bedrooms.toStringAsFixed(0)} BHK',
//                               detailFontSize,
//                               smallIconSize),
//                         if (bathrooms > 0)
//                           _buildPropertyDetail(
//                               Icons.bathtub,
//                               '${bathrooms.toStringAsFixed(0)} Bath',
//                               detailFontSize,
//                               smallIconSize),
//                       ],
//                     ),
//                     AnimatedBuilder(
//                       animation: _expandAnimation,
//                       builder: (context, child) {
//                         return ClipRect(
//                           child: Align(
//                             alignment: Alignment.topCenter,
//                             heightFactor: _expandAnimation.value,
//                             child: child,
//                           ),
//                         );
//                       },
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Divider(height: 20),
//                           if (builtupArea > 0)
//                             _buildDetailRow(
//                                 'Built-up Area',
//                                 '${builtupArea.toStringAsFixed(0)} sq.ft',
//                                 smallTextFontSize),
//                           if (grounds > 0)
//                             _buildDetailRow('Grounds',
//                                 grounds.toStringAsFixed(1), smallTextFontSize),
//                           if (allLandmarks.isNotEmpty)
//                             _buildDetailRow(
//                                 'Landmark',
//                                 allLandmarks.first.toString(),
//                                 smallTextFontSize),
//                           if (waterTax > 0)
//                             _buildDetailRow(
//                                 'Water Tax',
//                                 '₹${waterTax.toStringAsFixed(0)} / year',
//                                 smallTextFontSize),
//                           if (propertyTax > 0)
//                             _buildDetailRow(
//                                 'Property Tax',
//                                 '₹${propertyTax.toStringAsFixed(0)} / year',
//                                 smallTextFontSize),
//                           if (ageYears > 0)
//                             _buildDetailRow(
//                                 'Building Age',
//                                 '${ageYears.toStringAsFixed(0)} years',
//                                 smallTextFontSize),
//                           _buildDetailRow(
//                               'Type', propertyType, smallTextFontSize),
//                           _buildDetailRow('City', city, smallTextFontSize),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         TextButton(
//                           onPressed: _toggleExpansion,
//                           style: TextButton.styleFrom(
//                             minimumSize: Size.zero,
//                             padding: const EdgeInsets.symmetric(vertical: 6),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 _isExpanded
//                                     ? 'Show Less Details'
//                                     : 'Show More Details',
//                                 style: TextStyle(
//                                   fontSize: smallTextFontSize,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               const SizedBox(
//                                   width: 4), // spacing between text and icon
//                               Icon(
//                                 _isExpanded
//                                     ? Icons.expand_less
//                                     : Icons.expand_more,
//                                 size: smallIconSize,
//                                 color: Colors.blue,
//                                 semanticLabel: _isExpanded
//                                     ? 'Show Less Details'
//                                     : 'Show More Details',
//                                 textDirection: TextDirection.ltr,
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (images.isNotEmpty)
//                           TextButton.icon(
//                             onPressed: () {
//                               final processedUrls = _getProcessedImageUrls();
//                               if (processedUrls.isNotEmpty) {
//                                 showDialog(
//                                   context: context,
//                                   builder: (_) => MediaGalleryPreview(
//                                     mediaUrls: processedUrls,
//                                   ),
//                                 );
//                               }
//                             },
//                             style: TextButton.styleFrom(
//                               minimumSize: Size.zero,
//                               padding: const EdgeInsets.symmetric(
//                                   vertical: 6, horizontal: 8),
//                             ),
//                             icon: Icon(
//                               Icons.photo_library,
//                               size: smallIconSize,
//                               color: Colors.blue,
//                             ),
//                             label: Text('View All Media',
//                                 style: TextStyle(
//                                     fontSize: smallTextFontSize,
//                                     color: Colors.blue)),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                       if (getStringValue('mapLink').isNotEmpty) ...[
//       SizedBox(
//         width: 80,
//         child: ElevatedButton.icon(
//           onPressed: widget.onMapPressed,
//           icon: Icon(Icons.location_on, size: smallIconSize),
//           label: Text(
//             'Map',
//             style: TextStyle(fontSize: buttonFontSize),
//           ),
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.blue,
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 8, vertical: 12),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         ),
//       ),
//       const SizedBox(width: 6),
//     ],
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: widget.onPhonePressed,
//                             icon: Icon(Icons.phone, size: smallIconSize),
//                             label: Text(
//                               'Phone',
//                               style: TextStyle(fontSize: buttonFontSize),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.white,
//                               backgroundColor:
//                                   Theme.of(context).colorScheme.primary,
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: widget.onWhatsAppPressed,
//                             icon: Icon(FontAwesomeIcons.whatsapp,
//                                 size: smallIconSize),
//                             label: Text(
//                               'WhatsApp',
//                               style: TextStyle(fontSize: buttonFontSize),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.white,
//                               backgroundColor: Colors.green,
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPropertyDetail(
//       IconData icon, String text, double fontSize, double iconSize) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: iconSize, color: Colors.grey),
//         const SizedBox(width: 6),
//         Text(text, style: TextStyle(fontSize: fontSize)),
//       ],
//     );
//   }

//   Widget _buildDetailRow(String label, String value, double fontSize) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 90,
//             child: Text(
//               '$label:',
//               style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(fontSize: fontSize),
//               overflow: TextOverflow.ellipsis,
//               maxLines: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }