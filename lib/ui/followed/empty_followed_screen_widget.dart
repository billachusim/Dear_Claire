import 'package:clairediary/widgets/empty_state_widget.dart'; // Corrected import path
import 'package:flutter/material.dart';

import '../routes/routes.dart';

class EmptyFollowedSessionWidget extends StatelessWidget {
  const EmptyFollowedSessionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_alt_outlined, // CORRECT - Using built-in icon
      title: "You're Not Following Anyone",
      message: "Follow sessions that interest you to provide real-time support and see how stories unfold.",
      buttonText: "Find Sessions to Follow",
      onButtonPressed: () {
        Navigator.of(context).pushNamed(AppRoutes.searchPage);
      },
    );
  }
}
