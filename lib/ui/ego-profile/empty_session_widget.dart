import 'package:clairediary/ui/routes/routes.dart';
import 'package:flutter/material.dart';

import '../../widgets/empty_state_widget.dart';

class EmptySessionWidget extends StatelessWidget {
  const EmptySessionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.auto_stories_outlined, // CORRECT - Using built-in icon
      title: "Your Diary is Empty",
      message: "It looks like you haven't started a session yet. Tap the button below to create your first entry and share your thoughts.",
      buttonText: "Start a New Session",
      onButtonPressed: () {
        Navigator.of(context).pushNamed(AppRoutes.createSessionPage);
      },
    );
  }
}
