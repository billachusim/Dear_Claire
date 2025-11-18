import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/featured/model/session.dart';

class Reaction {
  final String value;
  final Widget icon;

  Reaction({
    required this.value,
    required this.icon,
  });
}

class MetooButton extends StatefulWidget {
  final Function(Reaction, int) onReactionChanged;
  final int? cheers;
  final int? thanks;
  final int? sorry;
  final int? me2;
  final Color color;
  final Session session;

  const MetooButton({
    Key? key,
    required this.onReactionChanged,
    this.cheers,
    this.thanks,
    this.sorry,
    this.me2,
    required this.color,
    required this.session,
  }) : super(key: key);

  @override
  State<MetooButton> createState() => _MetooButtonState();
}

class _MetooButtonState extends State<MetooButton>
    with SingleTickerProviderStateMixin {
  late Reaction selectedReaction;
  late int selectedCount;
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late final List<Reaction> reactions = [
    Reaction(
      value: 'Cheers👍',
      icon: Text(
        '${widget.cheers ?? 0} Cheers👍',
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.amber,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    Reaction(
      value: 'Thanks💕',
      icon: Text(
        '${widget.thanks ?? 0} Thanks💕',
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.red,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    Reaction(
      value: 'Sorry🖐',
      icon: Text(
        '${widget.sorry ?? 0} Sorry🖐',
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.deepPurple,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    Reaction(
      value: 'Me2🌺',
      icon: Text(
        '${widget.me2 ?? 0} Me2🌺',
        style: GoogleFonts.lato(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  ];

  void _incrementReactionCount(String reaction) {
    setState(() {
      switch (reaction) {
        case 'Cheers👍':
          selectedCount = (widget.cheers ?? 0) + 1;
          break;
        case 'Thanks💕':
          selectedCount = (widget.thanks ?? 0) + 1;
          break;
        case 'Sorry🖐':
          selectedCount = (widget.sorry ?? 0) + 1;
          break;
        case 'Me2🌺':
          selectedCount = (widget.me2 ?? 0) + 1;
          break;
      }
    });
  }


  @override
  void initState() {
    super.initState();
    selectedReaction = _reactionForMood(widget.session.moodId ?? 0);
    selectedCount = _countForReaction(selectedReaction.value);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutBack,
        ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Reaction _reactionForMood(int moodId) {
    switch (moodId) {
      case -1:
      case 0:
      case 1:
      case 11:
      case 17:
        return reactions[3]; // Me2
      case 2:
      case 5:
      case 6:
      case 8:
      case 9:
      case 10:
      case 12:
      case 13:
      case 14:
        return reactions[2]; // Sorry
      case 3:
      case 4:
      case 7:
      case 16:
        return reactions[0]; // Cheers
      default:
        return reactions[3];
    }
  }

  int _countForReaction(String reaction) {
    switch (reaction) {
      case 'Cheers👍':
        return widget.cheers ?? 0;
      case 'Thanks💕':
        return widget.thanks ?? 0;
      case 'Sorry🖐':
        return widget.sorry ?? 0;
      case 'Me2🌺':
        return widget.me2 ?? 0;
      default:
        return 0;
    }
  }

  void _showPopup() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Detect taps outside the popup
            GestureDetector(
              onTap: () async {
                await _animationController.reverse();
                _overlayEntry?.remove();
                _overlayEntry = null;
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent, // full screen
              ),
            ),
            Positioned(
              left: position.dx,
              top: position.dy - 80, // above button
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: reactions.map((r) {
                            return GestureDetector(
                              onTap: () async {
                                await _animationController.reverse();
                                _overlayEntry?.remove();
                                _overlayEntry = null;

                                // Update local UI immediately
                                _incrementReactionCount(r.value);
                                selectedReaction = r;

                                // Call external callback to update DB
                                widget.onReactionChanged(r, selectedCount);
                              },
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                child: r.icon,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context)!.insert(_overlayEntry!);
    _animationController.forward(from: 0.0);
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPopup,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // count badge instead of smiley
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selectedCount.toString(),
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            selectedReaction.value,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
