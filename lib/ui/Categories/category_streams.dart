import 'package:clairediary/ui/Categories/category_sessions.dart';
import 'package:flutter/material.dart';
import '../routes/page_router_animation.dart';

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
        margin: const EdgeInsets.only(top: 4),
        height: 40,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ListView(
            shrinkWrap: true,
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
                  width: 90.0,
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
                          child: Text("Love",
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
                  width: 90.0,
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
                          child: Text("School",
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
                  width: 90.0,
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
                          child: Text("Hate",
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
                  width: 90.0,
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
                          child: Text("Happy",
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
                  width: 95.0,
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
                          child: Text("Depression",
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
                  width: 90.0,
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
                          child: Text("Sex",
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
                  width: 90.0,
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
                          child: Text("Life",
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
                  width: 90.0,
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
                          child: Text("Work",
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
                  width: 90.0,
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
                          child: Text("Prayer",
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
                  width: 90.0,
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
                          child: Text("Health",
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
                  width: 90.0,
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
                          child: Text("Friends",
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
                  width: 90.0,
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
                          child: Text("Marriage",
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
                  width: 90.0,
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
                          child: Text("Single",
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
                  width: 90.0,
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
                          child: Text("Childhood",
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
        ),
      );
  }
}