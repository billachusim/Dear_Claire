import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:flutter/material.dart';

import '../../utils/color.dart';
import '../Categories/category_sessions.dart';



class FeaturedCategories extends StatelessWidget {
  const FeaturedCategories({Key? key}) : super(key: key);

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
                  String featuredCategory1 = "love and relationship";
                  String thisCategory = featuredCategory1;
                  PageRouter.gotoWidget(
                      CategorySessions(visitedCategory: thisCategory,),
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
                    child: const Text("Love And Relationship",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "love and relationship";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                      },
                  ),
                ],
              ),
            ),



            GestureDetector(
              onTap: (){
                String featuredCategory1 = "life and living";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/lifeAndLiving.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Life And Living",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "life and Living";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),




            GestureDetector(
              onTap: (){
                String featuredCategory1 = "school and education";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/bookOrPhone.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("School And Education",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "school and education";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),



            GestureDetector(
              onTap: (){
                String featuredCategory1 = "happy and blessed";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/happyPony.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Happy And Blessed",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "happy and blessed";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),



            GestureDetector(
              onTap: (){
                String featuredCategory1 = "hate and abuse";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/hateAndAbuse.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Hate And Abuse",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "hate and abuse";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),



            GestureDetector(
              onTap: (){
                String featuredCategory1 = "work and career";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/workAndCareer.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Work And Career",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "work and career";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),



            GestureDetector(
              onTap: (){
                String featuredCategory1 = "sad and depressed";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/sadnessAndDepression.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Sadness And Depression",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "sad and depressed";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),



            GestureDetector(
              onTap: (){
                String featuredCategory1 = "prayer and thanksgiving";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/prayerAndThanksgiving.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Prayer And Thanksgiving",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "prayer and thanksgiving";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),




            GestureDetector(
              onTap: (){
                String featuredCategory1 = "marriage and family";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/marriageAndFamily.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Marriage And Family",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "marriage and family";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),





            GestureDetector(
              onTap: (){
                String featuredCategory1 = "childhood and memory";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/childhoodAndMemory.png'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Childhood And Memory",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "childhood and memory";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),




            GestureDetector(
              onTap: (){
                String featuredCategory1 = "sex and dating";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/sexAndDating.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Sex And Dating",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "sex and dating";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
                          context);
                    },
                  ),
                ],
              ),
            ),




            GestureDetector(
              onTap: (){
                String featuredCategory1 = "friends and fun";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
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
                        image: DecorationImage(image: AssetImage('assets/images/friendshipAndFun.gif'),
                            fit: BoxFit.fill)
                    ),
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text("Friends And Fun",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      String featuredCategory1 = "friends and fun";
                      String thisCategory = featuredCategory1;
                      PageRouter.gotoWidget(
                          CategorySessions(visitedCategory: thisCategory,),
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
