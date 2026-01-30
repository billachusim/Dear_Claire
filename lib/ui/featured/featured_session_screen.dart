import 'dart:async';
import 'package:clairediary/ui/featured/public_sessions.dart';
import 'package:clairediary/utils/global_app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FeaturedPage extends StatefulWidget {
  final String title;
  final ScrollController scrollController; // Exposed for parent control

  FeaturedPage({
    Key? key,
    required this.title,
    required this.scrollController, // Pass controller from parent
  }) : super(key: key);

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightFactor;
  Completer<void>? _refreshCompleter;

  @override
  void initState() {
    super.initState();

    // Animation controller for smooth shrinking/expanding
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightFactor = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.value = 1.0;

    // Use the controller from the parent widget
    widget.scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Detect scroll direction
    if (widget.scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_animationController.value != 0.0 &&
          !_animationController.isAnimating) {
        _animationController.animateTo(0.0); // Shrink
      }
    } else if (widget.scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (_animationController.value != 1.0 &&
          !_animationController.isAnimating) {
        _animationController.animateTo(1.0); // Expand
      }
    }
  }

  @override
  void dispose() {
    // We no longer dispose the scrollController here since it's managed by the parent
    widget.scrollController.removeListener(_scrollListener);
    _animationController.dispose();
    super.dispose();
  }

  // --- START: PULL-TO-REFRESH LOGIC ---
  Future<void> _handleRefresh() {
    _refreshCompleter = Completer<void>();
    // Trigger the global refresh stream
    App.refreshFeed.add(true);

    // This simulates a network request delay and completes the completer.
    // In a real app, you might wait for an actual data fetch confirmation.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete();
      }
    });

    return _refreshCompleter!.future;
  }
  // --- END: PULL-TO-REFRESH LOGIC ---

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            SizeTransition(
              sizeFactor: _heightFactor,
              axisAlignment: -1.0,
              child: FeaturedStatusStreams(),
            ),
            TheFeaturedSessions(
              scrollController: widget.scrollController,
              onRefresh: _handleRefresh, // Pass the refresh handler
            ),
          ],
        ),
      ),
    );
  }
}
