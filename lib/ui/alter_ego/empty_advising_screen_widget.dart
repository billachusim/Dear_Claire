import 'package:clairediary/widgets/empty_state_widget.dart'; // Corrected import path
import 'package:flutter/material.dart';

class EmptyAdvisingSessionWidget extends StatelessWidget {
  const EmptyAdvisingSessionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.forum_outlined,
      title: "No Advising Sessions",
      message: "You aren't currently advising on any sessions. Find a diary in the 'All' tab to offer your support and guidance.",
      buttonText: "Browse All Sessions",
      onButtonPressed: () {},
    );
  }
}
