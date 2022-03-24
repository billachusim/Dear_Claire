import 'package:dear_claire/ui/Categories/category_sessions.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../routes/page_router_animation.dart';
import '../routes/routes.dart';

class CategoryStreams extends StatefulWidget {

  CategoryStreams({Key? key,}) : super(key: key);

  @override
  _CategoryStreamsState createState() => _CategoryStreamsState();
}

class _CategoryStreamsState extends State<CategoryStreams> {

  @override
  Widget build(BuildContext context) {
    return
      Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        height: 70,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[

            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "love and relationship";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
              },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                      alignment: Alignment.center,
                        child: Text(AppString.love_and_relationship_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),

            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory2 = "school and education";
                String thisCategory = featuredCategory2;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.school_and_education_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory3 = "hate and abuse";
                String thisCategory = featuredCategory3;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.hate_and_abuse_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory4 = "happy and blessed";
                String thisCategory = featuredCategory4;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.happy_and_blessed_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory5 = "sad and depressed";
                String thisCategory = featuredCategory5;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.depression_and_anxiety_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "sex and dating";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.sex_and_dating_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "life and living";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.life_and_living_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "work and career";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.work_and_career_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "prayer and thanksgiving";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.prayer_and_thanksgiving_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "health and fitness";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.health_and_fitness_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "friends and fun";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.friends_and_fun_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "marriage and family";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.marriage_and_family_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "single and lonely";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.single_and_lonely_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


            GestureDetector(onTap: (){
              setState(() {
                String featuredCategory1 = "childhood and memory";
                String thisCategory = featuredCategory1;
                PageRouter.gotoWidget(
                    CategorySessions(visitedCategory: thisCategory,),
                    context);
              });
            },
              child: Container(
                width: 120.0,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                  children: [
                    SizedBox(height: 3,),
                    Align(
                        alignment: Alignment.center,
                        child: Text(AppString.childhood_and_memory_category,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 17,
                          ),
                        )),
                  ],
                ),
              ),
            ),


          ],
        ),
      );
  }
}