import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../utils/color.dart';
import '../Categories/category_sessions.dart';



class FeaturedCategories extends StatelessWidget {
  const FeaturedCategories({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Pallet.colorSecondary,
        body: SingleChildScrollView(
          child: Column(
            children: [


              StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: [

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "happy and blessed";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),

                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 1,
                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "school and education";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "work and career";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "sex and dating";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 4,
                    mainAxisCellCount: 2,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "love and relationship";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
                        height: 100,
                        width: 150,
                        margin: EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: AssetImage('assets/images/loveGif.gif'),
                                fit: BoxFit.fill)
                        ),
                        child: Container(),
                      ),
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "hate and abuse";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 1,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "life and living";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "prayer and thanksgiving";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "sad and depressed";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 4,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "health and fitness";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
                        height: 100,
                        width: 150,
                        margin: EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: AssetImage('assets/images/bikeGirl.gif'),
                                fit: BoxFit.fill)
                        ),
                        child: Container(),
                      ),
                    ),
                  ),


                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "marriage and family";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "friends and fun";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),


                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "single and lonely";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
                        height: 100,
                        width: 150,
                        margin: EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: AssetImage('assets/images/tooShy.gif'),
                                fit: BoxFit.fill)
                        ),
                        child: Container(),
                      ),
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 1,

                    child: GestureDetector(
                      onTap: (){
                        String featuredCategory1 = "childhood and memory";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      },
                      child: Container(
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
                    ),
                  ),
                ],
              ),

            ],
          ),
        )
    );
  }
}
