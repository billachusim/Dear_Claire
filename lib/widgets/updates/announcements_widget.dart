import 'package:dear_claire/utils/helper.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/color.dart';

class UpdatesAndAnnouncements extends StatelessWidget {
  const UpdatesAndAnnouncements({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Pallet.colorSecondary,
        appBar: AppBar(
          backgroundColor: Pallet.colorPrimary,
          centerTitle: false,
          title: Text('Updates & Announcements',
              textAlign: TextAlign.start,
              maxLines: 1,
              style: GoogleFonts.lato(
                  fontSize: 24.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w600)),
        ),
        body: ListView(
          children: [
            Center(
              child: Container(
                height: getDeviceHeight(context),
                width: getDeviceWidth(context),
                child: WebView(
                  initialUrl: 'https://clairetweets.netlify.app',
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {},
                ),
              ),
            )
          ],
        ));
  }
}
