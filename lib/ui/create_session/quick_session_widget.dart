import 'package:clairediary/utils/color.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';

// A model to hold the data for each quick session button
class QuickSessionItem {
  final String title;
  final String buttonText;
  final String sessionTitle;
  final String sessionMessage;
  final int mood;

  QuickSessionItem({
    required this.title,
    required this.buttonText,
    required this.sessionTitle,
    required this.sessionMessage,
    required this.mood,
  });
}

class QuickSessionWidget extends StatelessWidget {
  final TextEditingController sessionTitleController;
  final TextEditingController sessionTextEditingController;
  final Function(int) createQuickSession; // Accepts mood as a parameter

  QuickSessionWidget({
    Key? key,
    required this.sessionTitleController,
    required this.sessionTextEditingController,
    required this.createQuickSession,
  }) : super(key: key);

  // List of all quick session items
  final List<QuickSessionItem> _quickSessionItems = [
    QuickSessionItem(title: "I'm Alive!", buttonText: "I'm Alive!", sessionTitle: "Feeling Alive Today", sessionMessage: "Dear Claire, I'm feeling so alive today!", mood: 1),
    QuickSessionItem(title: "Falling in love!", buttonText: "Falling in love!", sessionTitle: "Falling in Love Today", sessionMessage: "Dear Claire,\nHmmm. Something's in the air o...\nIt seems like I'm falling in love today!", mood: 4),
    QuickSessionItem(title: "Feeling gingered!", buttonText: "Feeling gingered!", sessionTitle: "Feeling Gingered Today", sessionMessage: "Dear Claire, I'm so motivated and ready to face today!\nGinger oh ginger... Na you dey ginger me o ginger!", mood: 15),
    QuickSessionItem(title: "Fly!", buttonText: "Fly!", sessionTitle: "Feeling So Fly!", sessionMessage: "Dear Claire, I'm feeling so fly today. Woo!\nFlamboyance is a state of mind.\nNobody can tell me anything.", mood: 16),
    QuickSessionItem(title: "Mtcheew, Sad", buttonText: "Mtcheew, Sad", sessionTitle: "Feeling Sad", sessionMessage: "Dear Claire, I'm feeling sad.\nWhat could this be? I'm thinking, lost in my sad thoughts.", mood: 2),
    QuickSessionItem(title: "Surprise!", buttonText: "Surprise!", sessionTitle: "Surprise!!!", sessionMessage: "Dear Claire, I'm really surprised. WOW!", mood: 11),
    QuickSessionItem(title: "Anxious", buttonText: "Anxious", sessionTitle: "So Anxious Today", sessionMessage: "Dear Claire,\nI'm kinda feeling anxious today txmqaqkcqtfch.\nI really need to get hold of myselfkc", mood: 8),
    QuickSessionItem(title: "Sick and tired", buttonText: "Sick and tired", sessionTitle: "Sick And Tired", sessionMessage: "Dear Claire, I'm just so sick and tired.", mood: 9),
    QuickSessionItem(title: "I'm jealous", buttonText: "I'm jealous", sessionTitle: "Jealous Mood", sessionMessage: "Dear Claire,\nHmmm. This must be jealousy all over me. I don't think I'm envious though.", mood: 12),
    QuickSessionItem(title: "Heartbroken", buttonText: "Heartbroken", sessionTitle: "Out Of Love", sessionMessage: "Dear Claire,\nI'm falling out of love again.\nI don't want to get philosophical but our mistakes only leads us to becoming a better version of ourselves.\nHeartbroken, yet, we move.", mood: 5),
    QuickSessionItem(title: "I'm afraid", buttonText: "I'm afraid", sessionTitle: "I'm Afraid Right Now", sessionMessage: "Dear Claire, I'm afraid.\nJust afraid. I'll be careful. I promise.", mood: 10),
    QuickSessionItem(title: "I'm embarrassed", buttonText: "I'm embarrassed", sessionTitle: "I'm So Embarrassed", sessionMessage: "Dear Claire, I'm feeling so embarrassed right now!\n I feel like the ground should open up beneath me and let me in.", mood: 14),
    QuickSessionItem(title: "I love Claire!", buttonText: "I love Claire!", sessionTitle: "Oh My Claire!", sessionMessage: "Dear Claire, I love you!.", mood: 17),
    QuickSessionItem(title: "Excited!", buttonText: "Excited!", sessionTitle: "I'm excited!", sessionMessage: "Dear Claire, Hala!\nI'm feeling so excited today!\nI'm so actually hyperactive right now. Woooo!! E for energy!.", mood: 3),
    QuickSessionItem(title: "Depressed", buttonText: "Depressed", sessionTitle: "I'm Depressed", sessionMessage: "Dear Claire,\nI think I'm feeling depressed today.\nI'm doing my best to shake out the beast.", mood: 6),
    QuickSessionItem(title: "Upside down", buttonText: "Upside down", sessionTitle: "Up Side Is Down!", sessionMessage: "Dear Claire,\n I'm feeling upside down today!\n Like... The up side is down... I repeat... The up side is down!", mood: 13),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24.0),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 2.0),
            child: Text(
              "Start A Quick Diary Session",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
              child: Wrap(
                spacing: 12.0, // Horizontal spacing
                runSpacing: 16.0, // Vertical spacing
                children: _quickSessionItems.map((item) {
                  return ActionChip(
                    label: Text(item.buttonText),
                    onPressed: () {
                      sessionTitleController.text = item.sessionTitle;
                      sessionTextEditingController.text = item.sessionMessage;
                      createQuickSession(item.mood);
                      Navigator.of(context).pop();
                      showToast("New session created!");
                    },
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    elevation: 0,
                    pressElevation: 0,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
