import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/color.dart';
import '../../utils/helper.dart';
import '../../utils/strings.dart';
import '../../widgets/toast.dart';
import '../Categories/category_sessions.dart';



class FeaturedCategories extends StatelessWidget {
  FeaturedCategories({Key? key}) : super(key: key);

  final TextEditingController _searchController = TextEditingController();


  @override
  Widget build(BuildContext context) {
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
                                  Navigator.of(context)
                                      .pushReplacementNamed(AppRoutes.home);
                                  showToast("Press back again to exit.");
                                },
                                child: Container(
                                  child: SvgPicture.asset("assets/images/ic_close.svg",
                                    width: 20.0,
                                    height: 20.0,
                                    color: Colors.white,),
                                )
                            ),
                          ),
                          SizedBox(width: 10,),
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
                                      hintText: "Search By Categories",
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
                            image: DecorationImage(image: AssetImage('assets/images/HappyMiddles.jpeg'),
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
                            image: DecorationImage(image: AssetImage('assets/images/DearDiary.jpg'),
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
