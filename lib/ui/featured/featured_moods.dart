import 'package:dear_claire/ui/Categories/mood_sessions.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/color.dart';
import '../../utils/helper.dart';
import '../../utils/strings.dart';



class FeaturedMoods extends StatelessWidget {
   FeaturedMoods({Key? key}) : super(key: key);

   final TextEditingController _searchController = TextEditingController();


   @override
  Widget build(BuildContext context) {
    int columnCount =3;
    return Scaffold(
        backgroundColor: Pallet.colorSecondary,
        body: SingleChildScrollView(
          child: Column(
            children: [

              Container(
                padding: EdgeInsets.only(top: 10),
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    color: Pallet.colorSecondaryDark),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Align(
                            alignment:Alignment.centerLeft,
                            child: GestureDetector(
                                onTap: (){
                                  print("Clicking on X");
                                  Navigator.pop(context);
                                },
                                child: SvgPicture.asset("assets/images/ic_close.svg",
                                  width: 17.0,
                                  height: 17.0,
                                  color: Colors.white,)
                            ),
                          ),
                          SizedBox(width: 10,),
                          FloatingActionButton(
                            heroTag: "searchRecord",
                            onPressed: () => {},
                            mini: true,
                            backgroundColor: Pallet.colorWhite,
                            child: Icon(
                              Icons.mic_rounded,
                              size: 19,
                              color: Pallet.colorPrimary,
                            ),),
                          Expanded(
                            child: new ConstrainedBox(
                              constraints: new BoxConstraints(
                                minWidth: getDeviceWidth(context),
                                maxWidth: getDeviceWidth(context),
                                minHeight: 35.0,
                                maxHeight: 40.0,
                              ),
                              child: Scrollbar(
                                child: Container(
                                  padding: EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Pallet.colorWhite,
                                  ),
                                  child: TextField(
                                    cursorColor: Pallet.colorSplashScreen,
                                    keyboardType: TextInputType.text,
                                    maxLines: 1,
                                    cursorHeight: 33,
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding:
                                      EdgeInsets.only(left: 13.0, right: 13.0, top: 1, bottom: 1),
                                      hintText: "Search By Moods",
                                      hintStyle: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Pallet.colorSecondary,
                                        fontSize: 22,
                                      ),
                                      counterText: '',
                                    ),
                                    maxLength: 160,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          FloatingActionButton(
                              heroTag: "searchWrite",
                              onPressed: () {
                                if (_searchController.text.isNotEmpty)
                                  // saveEgoMessage();
                                  _searchController.clear();
                              },
                              mini: true,
                              backgroundColor: Pallet.colorWhite,
                              child: SvgPicture.asset(
                                AppImages.appSend,
                                color: Pallet.colorPrimary,
                                height: 20,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              AnimationLimiter(
                child: GridView.count(
                    shrinkWrap: true,
                    physics:
                    BouncingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                    crossAxisCount: columnCount,
                    children: [

                      AnimationConfiguration.staggeredGrid(
                        position: 1,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 1;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🤣',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 2,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 2;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😔',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 3,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 3;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🤗',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 4,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 4;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😍',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 5,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 5;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🥵',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 6,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 6;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🥴',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 7,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 7;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🤓',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 8,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 8;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🤒',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 9,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 9;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🤢',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 10,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 10;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😱',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 11,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 11;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😮',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 12,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 12;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😈',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 13,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 13;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🙃',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 14,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 14;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😓',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 15,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 15;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '🤩',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 16,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 16;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: Center(
                                child: Text(
                                  '😇',
                                  style: TextStyle(
                                    fontSize: 90,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      AnimationConfiguration.staggeredGrid(
                        position: 17,
                        duration: Duration(milliseconds: 500),
                        columnCount: columnCount,
                        child: ScaleAnimation(
                          duration: Duration(milliseconds: 900),
                          curve: Curves.fastLinearToSlowEaseIn,
                          child: FadeInAnimation(

                            child: GestureDetector(
                              onTap: (){
                                int? featuredSessionMood = 17;
                                int? moodId = featuredSessionMood;
                                PageRouter.gotoWidget(
                                    MoodSessions(sessionMood: moodId),
                                    context);
                              },
                              child: RotateImage(80, 80),
                            ),
                          ),
                        ),
                      ),

                    ]
                ),
              ),
            ],
          ),
        )
    );
  }
}
