import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/Search/custom_search_card.dart';
import 'package:dear_claire/ui/splash_screen/custom_rotate_bacground.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
import '../../utils/helper.dart';
import '../../utils/strings.dart';
import '../Categories/category_sessions.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key? key, required this.title, this.record}) : super(key: key);

  final String title;
  final record;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Session>? _sessionList = [];

  final TextEditingController _searchController = TextEditingController();


  /// Get Featured sessions for "I'm so happy" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showHappySearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
       // .where("moodId", isEqualTo: 1)
        .where("category1", isEqualTo: "happy and blessed")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
       // .orderBy('timeLastActivity', descending: true)
        .limit(AppString.appSessionLength)
        .snapshots();
  }

  /// Get Featured sessions for "Relationship Issues" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showRelationshipIssuesSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "love and relationship")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
       // .orderBy('timeLastActivity', descending: true)
        .limit(AppString.appSessionLength)
        .snapshots();
  }

  /// Get Featured sessions for "Sad and depressed" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showSadAndDepressedSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "sad and depressed")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
    // .orderBy('timeCreated', descending: true)
        .snapshots();
  }

  /// Get Featured sessions for "School and work" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showSchoolAndWorkSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "school and education")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
    // .orderBy('timeCreated', descending: true)
        .snapshots();
  }

  /// Get Featured sessions for "Make new friends" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showMakeNewFriendsSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "friends and fun")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
    // .orderBy('timeCreated', descending: true)
        .snapshots();
  }


  /// Get Featured sessions for "Sick and tired" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showSickAndTiredSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "health and fitness")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
    // .orderBy('timeCreated', descending: true)
        .snapshots();
  }



  // Admob Ad Units.
  late BannerAd searchPageMiddleBanner;
  late BannerAd searchPageBottomBanner;
  late BannerAd searchPageMiddleBanner2;
  late BannerAd searchPageBottomBanner2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        searchPageMiddleBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.searchPageMiddleBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        searchPageBottomBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.searchPageBottomBannerAdUnitId,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });


    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        searchPageMiddleBanner2 = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.searchPageMiddleBannerAdUnitId2,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });

    // Implementing a bottom location banner ad unit.
    super.didChangeDependencies();
    adState.initialization.then((status) {
      setState(() {
        searchPageBottomBanner2 = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.searchPageBottomBannerAdUnitId2,
            request: AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
      });
    });
  }




  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.5), // Set this height
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                            onPressed: () => widget.record!(),
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
                                      hintText: AppString.search_bar_hint,
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
            ],
          ),
        ),
        body: Stack(
           children: [
             CustomRotateImage(getDeviceHeight(context), getDeviceWidth(context)),
             ListView(
              children: [
                SizedBox(height: 7,),
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                        AppString.featured_searches,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: Pallet.colorWhite,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 200,
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Pallet.colorPrimary,
                          borderRadius: BorderRadius.circular(25)
                        ),
                        child: GestureDetector(onTap: (){
                          setState(() {
                            String featuredCategory1 = "happy and blessed";
                            String thisCategory = featuredCategory1;
                            PageRouter.gotoWidget(
                                CategorySessions(visitedCategory: thisCategory,),
                                context);
                          });
                        },
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Pallet.colorWhite,
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.im_so_happy,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showHappySearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedEgoName: '', visitedUsersID: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(onTap: (){
                      setState(() {
                        String featuredCategory1 = "love and relationship";
                        String thisCategory = featuredCategory1;
                        PageRouter.gotoWidget(
                            CategorySessions(visitedCategory: thisCategory,),
                            context);
                      });
                    },
                      child: Container(
                        width: 200,
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: Pallet.colorPrimary,
                            borderRadius: BorderRadius.circular(25)
                        ),
                        child: Container(
                          height: 18,
                          width: 200,
                          decoration: BoxDecoration(
                              color: Pallet.colorWhite,
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            AppString.relationship_issues,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                    Container(
                      child: StreamBuilder(
                        stream: showRelationshipIssuesSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "sad and depressed";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.sad_and_depressed,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showSadAndDepressedSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedEgoName: '', visitedUsersID: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                // Top ad unit is here
                if(searchPageMiddleBanner == null)
                  SizedBox(height: 70)
                else
                  Container(
                    height: 60,
                    child: AdWidget(ad: searchPageMiddleBanner),
                  ),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "school and education";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.school_and_work,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showSchoolAndWorkSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "friends and fun";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.make_new_friends,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showMakeNewFriendsSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "health and fitness";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.sick_and_tired,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showSickAndTiredSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                // Top ad unit is here
                if(searchPageBottomBanner == null)
                  SizedBox(height: 70)
                else
                  Container(
                    height: 60,
                    child: AdWidget(ad: searchPageBottomBanner),
                  ),





                /// More Lists

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 200,
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: Pallet.colorPrimary,
                            borderRadius: BorderRadius.circular(25)
                        ),
                        child: GestureDetector(onTap: (){
                          setState(() {
                            String featuredCategory1 = "happy and blessed";
                            String thisCategory = featuredCategory1;
                            PageRouter.gotoWidget(
                                CategorySessions(visitedCategory: thisCategory,),
                                context);
                          });
                        },
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.im_so_happy,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showHappySearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedEgoName: '', visitedUsersID: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "love and relationship";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.relationship_issues,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showRelationshipIssuesSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "sad and depressed";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.sad_and_depressed,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showSadAndDepressedSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedEgoName: '', visitedUsersID: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                // Top ad unit is here
                if(searchPageMiddleBanner2 == null)
                  SizedBox(height: 70)
                else
                  Container(
                    height: 60,
                    child: AdWidget(ad: searchPageMiddleBanner2),
                  ),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "school and education";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.school_and_work,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showSchoolAndWorkSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "friends and fun";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.make_new_friends,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showMakeNewFriendsSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "health and fitness";
                          String thisCategory = featuredCategory1;
                          PageRouter.gotoWidget(
                              CategorySessions(visitedCategory: thisCategory,),
                              context);
                        });
                      },
                        child: Container(
                          width: 200,
                          alignment: Alignment.topLeft,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Pallet.colorPrimary,
                              borderRadius: BorderRadius.circular(25)
                          ),
                          child: Container(
                            height: 18,
                            width: 200,
                            decoration: BoxDecoration(
                                color: Pallet.colorWhite,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              AppString.sick_and_tired,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      child: StreamBuilder(
                        stream: showSickAndTiredSearches(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> session) {
                          if (session.connectionState == ConnectionState.waiting) {
                            return Text('');
                          }
                          if (!session.hasData) {
                            return Center(
                              child: Text("No Session data",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 15.0,
                                      color: Pallet.colorBlack,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            );
                          }
                          if (session.hasData) {
                            // clear list
                            _sessionList!.clear();

                            session.data!.docs.map((e) {
                              _sessionList!.add(Session.fromJson(e.data()));
                            }).toList();

                            return Scrollbar(
                              child: SizedBox(height: 200,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._sessionList!
                                        .map((element) =>
                                        CustomSearchCard(element: element, visitedUsersID: '', visitedEgoName: '',))
                                        .toList(),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ],
                ),

                // Top ad unit is here
                if(searchPageBottomBanner2 == null)
                  SizedBox(height: 70)
                else
                  Container(
                    height: 60,
                    child: AdWidget(ad: searchPageBottomBanner2),
                  ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
