import 'package:clairediary/ui/featured/public_sessions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FeaturedPage extends StatefulWidget {
  FeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

// Replace the entire _FeaturedPageState class in featured_session_screen.dart

class _FeaturedPageState extends State<FeaturedPage> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Animation controller for smooth shrinking/expanding
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightFactor = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initial state is expanded (value 0.0 means fully visible if using reverse logic,
    // or 1.0 for visible. Let's use 1.0 for visible).
    _animationController.value = 1.0;

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Detect scroll direction
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_animationController.value != 0.0 && !_animationController.isAnimating) {
        _animationController.animateTo(0.0); // Shrink
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (_animationController.value != 1.0 && !_animationController.isAnimating) {
        _animationController.animateTo(1.0); // Expand
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // SizeTransition handles the shrinking effect
            SizeTransition(
              sizeFactor: _heightFactor,
              axisAlignment: -1.0,
              child: FeaturedStatusStreams(),
            ),

            // Pass the controller to the child
            TheFeaturedSessions(scrollController: _scrollController),
          ],
        ),
      ),
    );
  }
}
