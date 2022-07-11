import 'package:dear_claire/ui/Categories/mood_sessions.dart';
import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:dear_claire/ui/splash_screen/rotate_logo.dart';
import 'package:flutter/material.dart';

import '../../utils/color.dart';



class FeaturedMoods extends StatelessWidget {
  const FeaturedMoods({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Pallet.colorSecondary,
        body: GridView.count(
          shrinkWrap: true,
          addAutomaticKeepAlives: true,
          crossAxisCount: 3,
          children: [
            GestureDetector(
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



            GestureDetector(
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




            GestureDetector(
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



            GestureDetector(
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



            GestureDetector(
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



            GestureDetector(
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



            GestureDetector(
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



            GestureDetector(
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




            GestureDetector(
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




            GestureDetector(
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




            GestureDetector(
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




            GestureDetector(
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



            GestureDetector(
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




            GestureDetector(
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




            GestureDetector(
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




            GestureDetector(
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




            GestureDetector(
              onTap: (){
                int? featuredSessionMood = 17;
                int? moodId = featuredSessionMood;
                PageRouter.gotoWidget(
                    MoodSessions(sessionMood: moodId),
                    context);
              },
              child: RotateImage(80, 80),
            ),
          ],
        )
    );
  }
}
