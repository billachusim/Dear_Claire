import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum MediaType { image, video }

class MediaItem {
  final String networkUrl;
  final String? thumbnailUrl;
  final MediaType type;
  final VoidCallback? onDelete;

  MediaItem({
    required this.networkUrl,
    this.thumbnailUrl,
    required this.type,
    this.onDelete,
  });
}

class UnifiedMediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final double aspectRatio;

  const UnifiedMediaViewer({
    super.key,
    required this.mediaItems,
    this.aspectRatio = 0.8,
  });

  @override
  State<UnifiedMediaViewer> createState() => UnifiedMediaViewerState();
}

class UnifiedMediaViewerState extends State<UnifiedMediaViewer> {
  late PageController _pageController;
  final Map<int, VideoPlayerController?> _videoControllers = {};
  int _currentPage = 0;
  // ★ FIX: Track which videos were MANUALLY paused by the user.
  final Set<int> _manualPauseIndexes = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        // Pause the old video regardless of its state.
        final oldController = _videoControllers[_currentPage];
        oldController?.pause();

        final newController = _videoControllers[newPage];
        // ★ FIX: Only autoplay the new video if it wasn't manually paused.
        if (newController != null && !_manualPauseIndexes.contains(newPage)) {
          newController.play();
        }

        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose all controllers when the widget is removed.
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  /// Public method to allow parent widgets to pause all videos.
  /// Returns true if a video was playing and was paused.
  bool pauseAllVideos() {
    bool wasAPlayingVideo = false;
    _videoControllers.forEach((index, controller) {
      if (controller?.value.isPlaying ?? false) {
        controller?.pause();
        // ★ FIX: Remember that this video was manually paused from the outside.
        _manualPauseIndexes.add(index);
        wasAPlayingVideo = true;
      }
    });
    // We need to trigger a rebuild in the video pages to update the icon.
    setState(() {});
    return wasAPlayingVideo;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // ★ FIX: Refined NotificationListener to only act on Overscroll.
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // This is the "eaten scroll" fix. It only triggers on a true overscroll.
        if (notification is OverscrollNotification && notification.overscroll != 0) {
          final parentScrollable = Scrollable.of(context);
          if (parentScrollable != null) {
            parentScrollable.position.jumpTo(parentScrollable.position.pixels + notification.overscroll);
          }
          // Cancel the glow effect from the PageView.
          return true;
        }
        // Allow other notifications (like ScrollUpdate) to pass through.
        return false;
      },
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: widget.mediaItems.length,
          itemBuilder: (context, index) {
            final item = widget.mediaItems[index];
            if (item.type == MediaType.video) {
              return _VideoPlayerPage(
                key: ValueKey('media_video_$index'),
                item: item,
                videoIndex: index,
                isMultiMedia: widget.mediaItems.length > 1,
                onControllerCreated: (controller) {
                  _videoControllers[index] = controller;
                },
                // Pass a callback to handle manual pauses.
                onManualPause: () {
                  _manualPauseIndexes.add(index);
                },
                onDelete: item.onDelete,
              );
            } else {
              return _ImageViewerPage(
                key: ValueKey('media_image_$index'),
                item: item,
                isMultiMedia: widget.mediaItems.length > 1,
                onDelete: item.onDelete,
              );
            }
          },
        ),
      ),
    );
  }
}

// region: Internal Page Widgets

class _VideoPlayerPage extends StatefulWidget {
  final MediaItem item;
  final int videoIndex;
  final bool isMultiMedia;
  final Function(VideoPlayerController?) onControllerCreated;
  final VoidCallback onManualPause; // ★ FIX: New callback for manual pauses.
  final VoidCallback? onDelete;

  const _VideoPlayerPage({
    super.key,
    required this.item,
    required this.videoIndex,
    required this.onControllerCreated,
    required this.onManualPause,
    this.isMultiMedia = false,
    this.onDelete,
  });

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final item = widget.item;
      if (item.networkUrl.startsWith('/')) {
        _controller = VideoPlayerController.file(File(item.networkUrl));
      } else {
        _controller = VideoPlayerController.networkUrl(Uri.parse(item.networkUrl));
      }

      // ★ FIX: Add a listener to rebuild the UI when the playing state changes.
      _controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      await _controller!.initialize();
      await _controller!.setLooping(true);
      widget.onControllerCreated(_controller);

      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.videoIndex != 0) {
          _controller!.play();
        }
      }
    } catch (e) {
      print("Error initializing video player: $e");
      if (mounted) setState(() => _isInitialized = false);
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        widget.onManualPause(); // ★ FIX: Notify the parent of a manual pause.
      } else {
        _controller!.play();
      }
    });
  }

  @override
  void dispose() {
    widget.onControllerCreated(null);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bezelColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    // ★ FIX: The playing state is now ALWAYS read directly from the controller.
    final bool isPlaying = _controller?.value.isPlaying ?? false;

    return _buildMediaFrame(
      context: context,
      bezelColor: bezelColor,
      isMultiMedia: widget.isMultiMedia,
      onDelete: widget.onDelete,
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isInitialized && _controller != null)
            Center(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)))
          else
            _buildThumbnail(widget.item.thumbnailUrl),
          if (!_isInitialized) const CupertinoActivityIndicator(color: Colors.white, radius: 15),
          // ★ FIX: Icon visibility is now tied directly to the controller's state.
          if (_isInitialized && !isPlaying)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: Center(child: Icon(CupertinoIcons.play_circle, color: Colors.white.withOpacity(0.85), size: 60)),
            ),
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white30, backgroundColor: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}

// This is the internal widget that manages a single IMAGE page.
class _ImageViewerPage extends StatefulWidget {
  final MediaItem item;
  final bool isMultiMedia;
  final VoidCallback? onDelete;


  const _ImageViewerPage({super.key,
    required this.item,
    this.onDelete,
    this.isMultiMedia = false});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state when off-screen

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bezelColor = isDarkMode ? Colors.white : Colors.white;


    return _buildMediaFrame(
      context: context,
      bezelColor: bezelColor,
      isMultiMedia: widget.isMultiMedia,
      onDelete: widget.onDelete,
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: CachedNetworkImage(
          imageUrl: widget.item.networkUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => const Center(child: CupertinoActivityIndicator()),
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 60)),
        ),
      ),
    );
  }
}

// endregion

// region: Common UI Elements

// A shared frame for both image and video pages to avoid code duplication.
Widget _buildMediaFrame({
  required BuildContext context,
  required Color bezelColor,
  required Widget child,
  bool isMultiMedia = false,
  VoidCallback? onTap,
  VoidCallback? onDelete,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: bezelColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(color: Colors.black, child: child),
            if (isMultiMedia)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Icon(CupertinoIcons.chevron_down, color: Colors.white70, size: 24),
              ),

            if (onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.5),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onDelete,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// Helper to build the thumbnail view for videos.
Widget _buildThumbnail(String? thumbnailUrl) {
  if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(child: CupertinoActivityIndicator(color: Colors.white54)),
      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 60)),
    );
  }
  return const Center(child: Icon(Icons.movie, color: Colors.white24, size: 60));
}
