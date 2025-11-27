import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Define the type of media.
enum MediaType { image, video }

// A single item for our unified media list.
class MediaItem {
  final String networkUrl;
  final String? thumbnailUrl; // Only used for videos
  final MediaType type;
  final VoidCallback? onDelete;

  MediaItem({
    required this.networkUrl,
    this.thumbnailUrl,
    required this.type,
    this.onDelete,
  });
}

// The main reusable UNIFIED media viewer widget.
class UnifiedMediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final double aspectRatio;

  const UnifiedMediaViewer({
    super.key,
    required this.mediaItems,
    this.aspectRatio = 0.8, // A taller default aspect ratio
  });

  @override
  State<UnifiedMediaViewer> createState() => UnifiedMediaViewerState();
}

class UnifiedMediaViewerState extends State<UnifiedMediaViewer> {
  late PageController _pageController;

  // Map to hold controllers for each video page, keyed by index
  final Map<int, VideoPlayerController?> _videoControllers = {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        // Page has changed, pause the old video
        final oldController = _videoControllers[_currentPage];
        oldController?.pause();

        // Optionally, play the new one if it's a video
        final newController = _videoControllers[newPage];
        newController?.play();

        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }



  /// Public method to allow parent widgets to pause all videos.
  void pauseAllVideos() {
    // Iterate through all tracked video controllers and pause them.
    _videoControllers.values.forEach((controller) {
      if (controller?.value.isPlaying ?? false) {
        controller?.pause();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // A NotificationListener is used to solve the "trapped scrolling" problem.
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Allow the parent to scroll when the PageView is at the top or bottom.
        if (notification is OverscrollNotification && notification.overscroll != 0) {
          final parentScrollable = Scrollable.of(context);
          if (parentScrollable != null) {
            // Forward the scroll to the parent.
            parentScrollable.position.jumpTo(parentScrollable.position.pixels + notification.overscroll);
          }
        }
        return true; // We've handled the notification.
      },
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical, // Vertical doom-scrolling
          itemCount: widget.mediaItems.length,
          itemBuilder: (context, index) {
            final item = widget.mediaItems[index];
            // Render the correct widget based on media type.
            if (item.type == MediaType.video) {
              return _VideoPlayerPage(
                key: ValueKey('media_video_$index'),
                item: item,
                videoIndex: index,
                isMultiMedia: widget.mediaItems.length > 1,
                // Pass the callback to register the controller
                onControllerCreated: (controller) {
                  _videoControllers[index] = controller;
                },
              );
            } else {
              return _ImageViewerPage(
                key: ValueKey('media_image_$index'),
                item: item,
                isMultiMedia: widget.mediaItems.length > 1,
              );
            }
          },
        ),
      ),
    );
  }
}

// region: Internal Page Widgets for Video and Image

// This is the internal widget that manages a single VIDEO page.
class _VideoPlayerPage extends StatefulWidget {
  final MediaItem item;
  final int videoIndex;
  final bool isMultiMedia;
  final Function(VideoPlayerController?) onControllerCreated;
  final VoidCallback? onDelete;

  const _VideoPlayerPage({super.key,
    required this.item,
    required this.videoIndex,
    required this.onControllerCreated,
    this.isMultiMedia = false,
    this.onDelete});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // Keep state when off-screen

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final item = widget.item;
      // Check if the URL is a local file path or a network URL.
      if (item.networkUrl.startsWith('/')) { // Local file paths start with '/'
        _controller = VideoPlayerController.file(File(item.networkUrl));
      } else { // Otherwise, it's a network URL
        _controller = VideoPlayerController.networkUrl(Uri.parse(item.networkUrl));
      }

      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      await _controller!.initialize();
      await _controller!.setLooping(true);
      widget.onControllerCreated(_controller);
      if (mounted) {
        setState(() => _isInitialized = true);
        // --- SMART AUTOPLAY LOGIC ---
        // Only autoplay if it's NOT the first video in the feed.
        if (widget.videoIndex != 0) {
          _controller!.play();
          _isPlaying = true;
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
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    widget.onControllerCreated(null); // Unregister the controller
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bezelColor = isDarkMode ? Colors.pink : Colors.white;

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
          if (_isInitialized && !_isPlaying)
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

// endregion
