import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A reusable YouTube player widget that uses video_player and youtube_explode_dart
/// to play YouTube videos without requiring the iframe package.
class ReusableYoutubePlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final bool loop;
  final bool mute;
  final Color? controlsColor;

  const ReusableYoutubePlayer({
    Key? key,
    required this.videoId,
    this.autoPlay = false,
    this.loop = false,
    this.mute = false,
    this.controlsColor,
  }) : super(key: key);

  @override
  State<ReusableYoutubePlayer> createState() => _ReusableYoutubePlayerState();
}

class _ReusableYoutubePlayerState extends State<ReusableYoutubePlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final yt = YoutubeExplode();

      try {
        // Get the video manifest
        final manifest = await yt.videos.streamsClient.getManifest(widget.videoId);

        // Get the muxed stream with highest quality (contains both audio and video)
        final streamInfo = manifest.muxed.withHighestBitrate();
        final videoUrl = streamInfo.url.toString();

        // Initialize video player controller
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

        await _controller!.initialize();

        if (widget.autoPlay && mounted) {
          await _controller!.play();
        }

        if (widget.mute && mounted) {
          await _controller!.setVolume(0.0);
        }

        if (widget.loop && mounted) {
          await _controller!.setLooping(true);
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } finally {
        yt.close();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load video: ${e.toString()}';
        });
      }
      print('Error initializing YouTube player: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),

            // Controls overlay
            if (_showControls)
              Container(
                color: Colors.black26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Play/Pause button
                    Center(
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: widget.controlsColor ?? Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar and controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          // Progress bar
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: widget.controlsColor ?? Colors.red,
                              bufferedColor: Colors.white30,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Time and controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: _controller!,
                                builder: (context, VideoPlayerValue value, child) {
                                  return Text(
                                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  // Mute/Unmute
                                  IconButton(
                                    icon: Icon(
                                      _controller!.value.volume > 0
                                          ? Icons.volume_up
                                          : Icons.volume_off,
                                      color: widget.controlsColor ?? Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_controller!.value.volume > 0) {
                                          _controller!.setVolume(0.0);
                                        } else {
                                          _controller!.setVolume(1.0);
                                        }
                                      });
                                    },
                                  ),
                                  // Fullscreen (placeholder - would need additional implementation)
                                  IconButton(
                                    icon: Icon(
                                      Icons.fullscreen,
                                      color: widget.controlsColor ?? Colors.white,
                                    ),
                                    onPressed: () {
                                      // Fullscreen functionality would go here
                                      // This would require additional package or native implementation
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Controller class to manage YouTube player from parent widgets
class ReusableYoutubePlayerController {
  final String videoId;
  final bool autoPlay;
  final bool loop;
  final bool mute;

  ReusableYoutubePlayerController({
    required this.videoId,
    this.autoPlay = false,
    this.loop = false,
    this.mute = false,
  });

  /// Factory constructor for creating controller with params
  factory ReusableYoutubePlayerController.fromParams({
    required String videoId,
    bool autoPlay = false,
    bool loop = false,
    bool mute = false,
  }) {
    return ReusableYoutubePlayerController(
      videoId: videoId,
      autoPlay: autoPlay,
      loop: loop,
      mute: mute,
    );
  }

  /// Method to close/dispose controller (for compatibility with old API)
  void close() {
    // This is kept for API compatibility but actual disposal
    // happens in the widget's dispose method
  }
}
