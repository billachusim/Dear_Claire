import 'package:dear_claire/ui/Categories/category_streams.dart';
import 'package:dear_claire/ui/Categories/users_sessions_by_moods.dart';
import 'package:dear_claire/ui/featured/public_sessions.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';

class FeaturedPage extends StatefulWidget {
  FeaturedPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FeaturedPageState createState() => _FeaturedPageState();
}

class _FeaturedPageState extends State<FeaturedPage> {

  bool showFilter = false;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Pallet.colorSecondaryDark,
        body: Stack(
          children: [
            //CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),

            Column(
            children: [

              FeaturedStatusStreams(),

              TheFeaturedSessions(),

              Container(
                decoration: BoxDecoration(
                  color: Colors.black
                ),
                child: Row(
                  children: [

                    Visibility(
                      visible: !showFilter,
                      child: TextButton(
                        style: TextButton.styleFrom(fixedSize: Size.fromHeight(10)),
                        onPressed: () {
                          setState(() {
                            showFilter = true;
                          });
                        },
                        child: Text(
                          showFilter == true? 'HIDE FILTER' :
                          showFilter == false? 'SHOW FILTER' :
                          "Show/Hide Filter",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    FeaturedSessionNotice(),
                  ],
                ),
              ),


              Container(
                decoration: BoxDecoration(
                    color: Colors.black
                ),
                child: Visibility(
                    visible: showFilter,
                    child: TrendingCategories()
                ),
              ),

              Container(
                decoration: BoxDecoration(
                    color: Colors.black
                ),
                child: Visibility(
                  visible: showFilter,
                    child: UsersMoodStream()
                ),
              ),

      ],
          ),
      ],
        ),
      ),
    );
  }
}
