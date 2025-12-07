import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/strings.dart';
import 'package:clairediary/widgets/toast.dart';
import 'package:flutter/material.dart';

// A model to hold the data for each quick session button
class QuickSessionItem {
  final String title;
  final String buttonText;
  final String sessionTitle;
  final String sessionMessage;
  final int mood;
  final Color color;
  final double width;

  QuickSessionItem({
    required this.title,
    required this.buttonText,
    required this.sessionTitle,
    required this.sessionMessage,
    required this.mood,
    required this.color,
    required this.width,
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
    QuickSessionItem(title: "I'm Alive!", buttonText: "I'm Alive!", sessionTitle: "Feeling Alive Today", sessionMessage: "Dear Claire, I'm feeling so alive today!", mood: 1, color: Colors.green, width: 77.0),
    QuickSessionItem(title: "Falling in love!", buttonText: "Falling in love!", sessionTitle: "Falling in Love Today", sessionMessage: "Dear Claire,\nHmmm. Something's in the air o...\nIt seems like I'm falling in love today!", mood: 4, color: Colors.red, width: 110.0),
    QuickSessionItem(title: "Feeling gingered!", buttonText: "Feeling gingered!", sessionTitle: "Feeling Gingered Today", sessionMessage: "Dear Claire, I'm so motivated and ready to face today!\nGinger oh ginger... Na you dey ginger me o ginger!", mood: 15, color: Colors.orange, width: 135.0),
    QuickSessionItem(title: "Fly!", buttonText: "Fly!", sessionTitle: "Feeling So Fly!", sessionMessage: "Dear Claire, I'm feeling so fly today. Woo!\nFlamboyance is a state of mind.\nNobody can tell me anything.", mood: 16, color: Colors.purple, width: 45.0),
    QuickSessionItem(title: "Mtcheew, Sad", buttonText: "Mtcheew, Sad", sessionTitle: "Feeling Sad", sessionMessage: "Dear Claire, I'm feeling sad.\nWhat could this be? I'm thinking, lost in my sad thoughts.", mood: 2, color: Colors.blueAccent, width: 112.0),
    QuickSessionItem(title: "Surprise!", buttonText: "Surprise!", sessionTitle: "Surprise!!!", sessionMessage: "Dear Claire, I'm really surprised. WOW!", mood: 11, color: Colors.brown, width: 75.0),
    QuickSessionItem(title: "Anxious", buttonText: "Anxious", sessionTitle: "So Anxious Today", sessionMessage: "Dear Claire,\nI'm kinda feeling anxious today txmqaqkcqtfch.\nI really need to get hold of myselfkc", mood: 8, color: Colors.blueGrey, width: 80.0),
    QuickSessionItem(title: "Sick and tired", buttonText: "Sick and tired", sessionTitle: "Sick And Tired", sessionMessage: "Dear Claire, I'm just so sick and tired.", mood: 9, color: Colors.black54, width: 107.0),
    QuickSessionItem(title: "I'm jealous", buttonText: "I'm jealous", sessionTitle: "Jealous Mood", sessionMessage: "Dear Claire,\nHmmm. This must be jealousy all over me. I don't think I'm envious though.", mood: 12, color: Colors.black, width: 85.0),
    QuickSessionItem(title: "Heartbroken", buttonText: "Heartbroken", sessionTitle: "Out Of Love", sessionMessage: "Dear Claire,\nI'm falling out of love again.\nI don't want to get philosophical but our mistakes only leads us to becoming a better version of ourselves.\nHeartbroken, yet, we move.", mood: 5, color: Colors.red, width: 105.0),
    QuickSessionItem(title: "I'm afraid", buttonText: "I'm afraid", sessionTitle: "I'm Afraid Right Now", sessionMessage: "Dear Claire, I'm afraid.\nJust afraid. I'll be careful. I promise.", mood: 10, color: Colors.deepPurpleAccent, width: 80.0),
    QuickSessionItem(title: "I'm embarrassed", buttonText: "I'm embarrassed", sessionTitle: "I'm So Embarrassed", sessionMessage: "Dear Claire, I'm feeling so embarrassed right now!\n I feel like the ground should open up beneath me and let me in.", mood: 14, color: Colors.brown, width: 130.0),
    QuickSessionItem(title: "I love Claire!", buttonText: "I love Claire!", sessionTitle: "Oh My Claire!", sessionMessage: "Dear Claire, I love you!.", mood: 17, color: Colors.deepPurple, width: 100.0),
    QuickSessionItem(title: "Excited!", buttonText: "Excited!", sessionTitle: "I'm excited!", sessionMessage: "Dear Claire, Hala!\nI'm feeling so excited today!\nI'm so actually hyperactive right now. Woooo!! E for energy!.", mood: 3, color: Colors.pink, width: 70.0),
    QuickSessionItem(title: "Depressed", buttonText: "Depressed", sessionTitle: "I'm Depressed", sessionMessage: "Dear Claire,\nI think I'm feeling depressed today.\nI'm doing my best to shake out the beast.", mood: 6, color: Colors.amber, width: 85.0),
    QuickSessionItem(title: "Upside down", buttonText: "Upside down", sessionTitle: "Up Side Is Down!", sessionMessage: "Dear Claire,\n I'm feeling upside down today!\n Like... The up side is down... I repeat... The up side is down!", mood: 13, color: Colors.black, width: 105.0),
  ];

  @override
  Widget build(BuildContext context) {
    // Helper function to create a single button
    Widget _buildQuickSessionButton(QuickSessionItem item) {
      return GestureDetector(
        onTap: () {
          sessionTitleController.text = item.sessionTitle;
          sessionTextEditingController.text = item.sessionMessage;

          // We call the function passed from the parent
          createQuickSession(item.mood);

          Navigator.of(context).pop();
          showToast(AppString.started_new_session);
        },
        child: Container(
          width: item.width,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            item.buttonText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    // Helper function to create a row of buttons
    Widget _buildRow(List<QuickSessionItem> items) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map(_buildQuickSessionButton).toList(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(2),
              height: 20,
              width: 160,
              decoration: BoxDecoration(
                color: Pallet.colorWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Start A Quick AI Session",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          _buildRow(_quickSessionItems.sublist(0, 4)),
          const SizedBox(height: 8),
          _buildRow(_quickSessionItems.sublist(4, 8)),
          const SizedBox(height: 8),
          _buildRow(_quickSessionItems.sublist(8, 12)),
          const SizedBox(height: 8),
          _buildRow(_quickSessionItems.sublist(12, 16)),
        ],
      ),
    );
  }
}
