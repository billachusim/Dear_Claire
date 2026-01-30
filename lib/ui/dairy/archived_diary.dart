import 'package:clairediary/ui/ego-profile/empty_session_widget.dart';
import 'package:clairediary/ui/featured/model/session.dart';
import 'package:clairediary/widgets/ego_mode_session_card.dart';
import 'package:flutter/material.dart';
import 'package:clairediary/utils/constant.dart';
import 'package:clairediary/ui/splash_screen/rotate_logo.dart';

class ArchivedDiaryPage extends StatefulWidget {
  final String title;
  final bool showAppBar;

  ArchivedDiaryPage({
    Key? key,
    required this.title,
    this.showAppBar = false,
  }) : super(key: key);

  @override
  _ArchivedDiaryPageState createState() => _ArchivedDiaryPageState();
}

class _ArchivedDiaryPageState extends State<ArchivedDiaryPage> {

  Widget _buildContent() {
    return Stack(
      children: [
        StreamBuilder<List<Session>>(
          stream: firebaseServices.getArchivedDiarySessionsStream(),
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
