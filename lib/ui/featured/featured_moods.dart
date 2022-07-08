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
          crossAxisCount: 2,
          children: [
            GestureDetector(
              onTap: (){
                int? featuredSessionMood = 1;
                int? moodId = featuredSessionMood;
                PageRouter.gotoWidget(
                    MoodSessions(sessionMood: moodId),
                    context);
              },
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/feelingHappy.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Feeling Happy",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 1;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/sadAndDepressed.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Ugh. So Sad",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 2;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/newExcited.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Excited!",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 3;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/fallingInLove.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Falling In Love",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 4;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/fallinOutOfLove.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Falling Out Of Love",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 5;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/feelingDepressed.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Depressed",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 6;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/feelingMotivated.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("I'm Motivated",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 7;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/upsideDown.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("So Anxious Right Now",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 8;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/sick.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Feeling Sick",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 9;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/afraid.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("I'm Afraid",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 10;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/surprise.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Surprise!",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 11;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/jealous.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("I'm Getting Jealous",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 12;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/upsideDown.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("I'm Upside Down",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 13;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/embarrased.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("So Embarrassed",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 14;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/feelingGingered.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("I'm Feeling Gingered",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 15;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/feelingFly.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("I'm Feeling Fly",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 16;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
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
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    margin: EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(image: AssetImage('assets/images/icon.jpeg'),
                            fit: BoxFit.fill)
                    ),
                    child: RotateImage(40, 40),
                  ),
                  TextButton(
                    child: const Text("I'm Feeling Claire",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      int? featuredSessionMood = 17;
                      int? moodId = featuredSessionMood;
                      PageRouter.gotoWidget(
                          MoodSessions(sessionMood: moodId),
                          context);
                    },
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }
}
