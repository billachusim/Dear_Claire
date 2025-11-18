import 'package:clairediary/ui/featured/public_sessions.dart';
import 'package:flutter/material.dart';

class FeaturedPage extends StatefulWidget {
  FeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {

  @override
  void initState() {
    super.initState();
  }


  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [

            FeaturedStatusStreams(),

            TheFeaturedSessions(),

          ],
        ),
      ),
    );
  }
}
