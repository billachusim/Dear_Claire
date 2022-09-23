import 'package:dear_claire/ui/Categories/mood_sessions.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';



class FeaturedMoods extends StatelessWidget {
   FeaturedMoods({Key? key}) : super(key: key);



   @override
  Widget build(BuildContext context) {
    int columnCount =3;
    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
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
