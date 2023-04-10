import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/ui/Search/custom_search_card.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../Admob/ad_state.dart';
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

  //final TextEditingController _searchController = TextEditingController();


  /// Get Featured sessions for "I'm so happy" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showHappySearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "happy and blessed")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .orderBy('timeLastActivity', descending: true)
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
        .orderBy('timeLastActivity', descending: true)
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
        .orderBy('timeCreated', descending: true)
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
        .orderBy('timeCreated', descending: true)
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
        .orderBy('timeCreated', descending: true)
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
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }


  /// Get Featured sessions for "Comedy and entertainment" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showComedyAndEntertainmentSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "comedy and entertainment")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .orderBy('timeLastActivity', descending: true)
        .limit(AppString.appSessionLength)
        .snapshots();
  }

  /// Get Featured sessions for "Parents and children" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showParentsAndChildrenSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "parents and children")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .orderBy('timeLastActivity', descending: true)
        .limit(AppString.appSessionLength)
        .snapshots();
  }

  /// Get Featured sessions for "Single and lonely" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showSingleAndLonelySearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "single and lonely")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }

  /// Get Featured sessions for "Prayer and thanksgiving" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showPrayerAndThanksgivingSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "prayer and thanksgiving")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }

  /// Get Featured sessions for "marriage and family" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showMarriageAndFamilySearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "marriage and family")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }


  /// Get Featured sessions for "Sex and dating" search
  /// But not flagged or even archived
  Stream<QuerySnapshot<Map<String, dynamic>>> showSexAndDatingSearches() {
    return FirebaseFirestore.instance
        .collection(AppString.appFeaturedSessions)
        .where("category1", isEqualTo: "sex and dating")
        .where("repliesEnabled", isEqualTo: true)
        .where("archived", isEqualTo: false)
        .where("flagged", isEqualTo: false)
        .limit(AppString.appSessionLength)
        .orderBy('timeCreated', descending: true)
        .snapshots();
  }



  // Admob Ad Units.
  BannerAd? searchPageMiddleBanner;
  BannerAd? searchPageBottomBanner;
  BannerAd? searchPageMiddleBanner2;
  BannerAd? searchPageBottomBanner2;
  bool _bannerIsLoaded = false;


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
            request: const AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )..load();
        _bannerIsLoaded = true;
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
    super.didChangeDependencies();
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
        body: Stack(
           children: [
             ListView(
              children: [
                SizedBox(height: 7,),
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
                SizedBox(height: 10,),

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
                SizedBox(height: 10,),

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
                SizedBox(height: 10,),


                // Top ad unit is here
                if (searchPageMiddleBanner != null && _bannerIsLoaded)
                  SizedBox(
                    height: 60,
                    child: AdWidget(ad: searchPageMiddleBanner!),
                  )
                else
                  SizedBox(height: 70, child: Text('Relevant ads only', style: TextStyle(color: Colors.white),),),

                SizedBox(height: 10,),

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
                SizedBox(height: 10,),

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
                SizedBox(height: 10,),

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
                SizedBox(height: 10,),


                // Top ad unit is here
                if (searchPageBottomBanner != null && _bannerIsLoaded)
                  SizedBox(
                    height: 60,
                    child: AdWidget(ad: searchPageBottomBanner!),
                  )
                else
                  SizedBox(height: 70, child: Text('Relevant ads only', style: TextStyle(color: Colors.white),),),




                SizedBox(height: 10,),


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
                            String featuredCategory1 = "marriage and family";
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
                            child: Text( "Marriage and Family",
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
                        stream: showMarriageAndFamilySearches(),
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
                SizedBox(height: 10,),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "sex and dating";
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
                              "Sex and dating sessions",
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
                        stream: showSexAndDatingSearches(),
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
                SizedBox(height: 10,),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "comedy and entertainment";
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
                              "Comedy and entertainment",
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
                        stream: showComedyAndEntertainmentSearches(),
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
                SizedBox(height: 10,),

                // Top ad unit is here
                if (searchPageMiddleBanner2 != null && _bannerIsLoaded)
                  SizedBox(
                    height: 60,
                    child: AdWidget(ad: searchPageMiddleBanner2!),
                  )
                else
                  SizedBox(height: 70, child: Text('Relevant ads only', style: TextStyle(color: Colors.white),),),

                SizedBox(height: 10,),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "single and lonely";
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
                              "Single and lonely",
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
                        stream: showSingleAndLonelySearches(),
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
                SizedBox(height: 10,),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "parents and children";
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
                              "Parents and children",
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
                        stream: showParentsAndChildrenSearches(),
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
                SizedBox(height: 10,),

                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(onTap: (){
                        setState(() {
                          String featuredCategory1 = "prayer and thanksgiving";
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
                              "Prayer and thanksgiving",
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
                        stream: showPrayerAndThanksgivingSearches(),
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
                SizedBox(height: 10,),

                // Top ad unit is here
                if (searchPageBottomBanner2 != null && _bannerIsLoaded)
                  SizedBox(
                    height: 60,
                    child: AdWidget(ad: searchPageBottomBanner2!),
                  )
                else
                  SizedBox(height: 70, child: Text('Relevant ads only', style: TextStyle(color: Colors.white),),),

                SizedBox(height: 10,),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
