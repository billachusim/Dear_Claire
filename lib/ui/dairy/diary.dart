import 'package:clairediary/ui/ego-profile/empty_session_widget.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';

class DiaryPage extends StatefulWidget {
  final String title;
  final bool showAppBar;

  DiaryPage({
    Key? key,
    required this.title,
    this.showAppBar = false,
  }) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {

  Widget _buildContent() {
    return Stack(
      children: [
        StreamBuilder<List<Session>>(
          stream: firebaseServices.getDiarySessionsStream(),
          builder: (context, AsyncSnapshot<List<Session>> sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: RotateImage(50, 50));
            }
            if (sessionSnapshot.hasError) {
              return Center(child: Text("Error loading diary."));
            }
            if (!sessionSnapshot.hasData || sessionSnapshot.data!.isEmpty) {
              return EmptySessionWidget();
            }

            // Use the data from the stream snapshot
            return ListView(
              children: [
                SizedBox(height: 10),
                DiarySessionNotice(),
                SizedBox(height: 10),
                ...sessionSnapshot.data!
                    .map((element) => EgoModeSessionCard(
                  element: element,
                  visitedUsersID: '',
                  visitedEgoName: '',
                ))
                    .toList(),
              ],
            );
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // If showAppBar is true, build the page with a Scaffold and AppBar
    if (widget.showAppBar) {
      bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      Color appBarTextColor = isDarkMode ? Colors.white : Colors.black;
      Color appBarBackgroundColor = isDarkMode ? Colors.black : Colors.white;

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: TextStyle(color: appBarTextColor)),
          backgroundColor: appBarBackgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: appBarTextColor),
          automaticallyImplyLeading: true, // Ensures back button is shown
        ),
        body: _buildContent(), // Use the extracted content widget
      );
    } else {
      // Otherwise, return only the content, to be used inside another Scaffold (like HomePage)
      // The PopScope and SafeArea are intentionally removed here as they are handled by the parent Scaffold.
      return _buildContent();
    }
  }
}

/// This shows a notice header about featured sessions.
class DiarySessionNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          "ONLY YOUR Diary Sessions appear here. Archive can be found on Ego page.\n"
              "Open Up, write or record, share or save it and Claire will be there for you.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
