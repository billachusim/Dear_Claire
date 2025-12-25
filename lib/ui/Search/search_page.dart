import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clairediary/ui/Search/custom_search_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../Admob/ad_state.dart';
import '../../utils/mood.dart';
import '../../utils/strings.dart';
import '../Categories/category_sessions.dart';
import '../Categories/mood_sessions.dart';
import '../featured/model/session.dart';
import '../routes/page_router_animation.dart';

// Data class to hold information for each keyword section
class SearchKeyword {
  final String title;
  final String category;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  SearchKeyword({required this.title, required this.category, required this.stream});
}

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key, required String title}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late final List<SearchKeyword> _keywords;

  // --- Animation Controller for filter icon ---
  late final AnimationController _filterIconController;
  late final Animation<double> _filterIconAnimation;

  // --- Filtering State ---
  String? _selectedContinent;
  int? _selectedMoodId;

  // --- Admob Ad Units ---
  BannerAd? searchPageMiddleBanner;
  BannerAd? searchPageBottomBanner;
  BannerAd? searchPageMiddleBanner2;
  BannerAd? searchPageBottomBanner2;

  @override
  void initState() {
    super.initState();
    _keywords = _initializeKeywords();
    _filterIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _filterIconAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _filterIconController, curve: Curves.easeInOut),
    );
  }

  // Centralized method to create the list of keywords to avoid repetition
  List<SearchKeyword> _initializeKeywords() {
    // Helper to reduce boilerplate
    Stream<QuerySnapshot<Map<String, dynamic>>> createStream(String category) {
      return FirebaseFirestore.instance
          .collection(AppString.appFeaturedSessions)
          .where("category1", isEqualTo: category)
          .where("repliesEnabled", isEqualTo: true)
          .where("archived", isEqualTo: false)
          .where("flagged", isEqualTo: false)
          .orderBy('timeLastActivity', descending: true)
          .limit(AppString.appSessionLength)
          .snapshots();
    }

    return [
      SearchKeyword(title: AppString.im_so_happy, category: "happy and blessed", stream: createStream("happy and blessed")),
      SearchKeyword(title: AppString.relationship_issues, category: "love and relationship", stream: createStream("love and relationship")),
      SearchKeyword(title: AppString.sad_and_depressed, category: "sad and depressed", stream: createStream("sad and depressed")),
      SearchKeyword(title: "School and Work", category: "school and education", stream: createStream("school and education")),
      SearchKeyword(title: "Make New Friends", category: "friends and fun", stream: createStream("friends and fun")),
      SearchKeyword(title: "Sick and Tired", category: "health and fitness", stream: createStream("health and fitness")),
      SearchKeyword(title: "Marriage and Family", category: "marriage and family", stream: createStream("marriage and family")),
      SearchKeyword(title: "Sex and Dating", category: "sex and dating", stream: createStream("sex and dating")),
      SearchKeyword(title: "Comedy and Entertainment", category: "comedy and entertainment", stream: createStream("comedy and entertainment")),
      SearchKeyword(title: "Single and Lonely", category: "single and lonely", stream: createStream("single and lonely")),
      SearchKeyword(title: "Parents and Children", category: "parents and children", stream: createStream("parents and children")),
      SearchKeyword(title: "Prayer and Thanksgiving", category: "prayer and thanksgiving", stream: createStream("prayer and thanksgiving")),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load ads only if they haven't been loaded yet
    if (searchPageMiddleBanner == null) {
      final adState = Provider.of<AdState>(context, listen: false);
      _loadBannerAds(adState);
    }
  }

  void _loadBannerAds(AdState adState) {
    adState.initialization.then((status) {
      if (!mounted) return; // Ensure widget is still in the tree
      setState(() {
        searchPageMiddleBanner = _createBannerAd(adState.searchPageMiddleBannerAdUnitId);
        searchPageBottomBanner = _createBannerAd(adState.searchPageBottomBannerAdUnitId);
        searchPageMiddleBanner2 = _createBannerAd(adState.searchPageMiddleBannerAdUnitId2);
        searchPageBottomBanner2 = _createBannerAd(adState.searchPageBottomBannerAdUnitId2);
      });
    });
  }

  BannerAd _createBannerAd(String adUnitId) {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterIconController.dispose();
    searchPageMiddleBanner?.dispose();
    searchPageBottomBanner?.dispose();
    searchPageMiddleBanner2?.dispose();
    searchPageBottomBanner2?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final searchBarColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final searchBarTextColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text("Explore Sessions",
            style: GoogleFonts.lato(
                fontSize: 25.0,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: ScaleTransition(
              scale: _filterIconAnimation,
              child: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 35,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(searchBarColor, searchBarTextColor),
          Expanded(
            child: _searchQuery.isNotEmpty || _selectedContinent != null || _selectedMoodId != null
                ? _buildSearchResults()
                : _buildKeywordSections(),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Sessions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // --- Location Filter ---
              ListTile(
                leading: const Icon(Icons.location_on),
                trailing: DropdownButton<String>(
                  value: _selectedContinent,
                  hint: const Text('By Continent'),
                  items: ['Africa', 'Asia', 'Europe', 'North America', 'South America', 'Australia']
                      .map((continent) => DropdownMenuItem(value: continent, child: Text(continent)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContinent = value;
                      _selectedMoodId = null; // Clear other filter
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 8),
              // --- Mood Filter ---
              ListTile(
                leading: const Icon(Icons.mood),
                trailing: DropdownButton<int>(
                  value: _selectedMoodId,
                  hint: const Text('      By Mood'),
                  items: Mood.MOODS.where((mood) => mood.id != -1 && mood.id != 0)
                      .map((mood) => DropdownMenuItem(value: mood.id, child: Text(mood.name!)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      // First, close the dialog
                      Navigator.of(context).pop();
                      // Then navigate to the MoodSessionsPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MoodSessions(sessionMood: value),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Widget for the search bar
  Widget _buildSearchBar(Color? searchBarColor, Color searchBarTextColor) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: searchBarTextColor),
        onChanged: (value) => setState(() {
          _searchQuery = value;
          _selectedContinent = null;
          _selectedMoodId = null;
        }),
        decoration: InputDecoration(
          hintText: "Search sessions...",
          hintStyle: TextStyle(color: searchBarTextColor.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: searchBarTextColor),
          filled: true,
          fillColor: searchBarColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  // Widget for displaying the list of keyword sections
  Widget _buildKeywordSections() {
    return ListView.builder(
      itemCount: _keywords.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final keyword = _keywords[index];
        // --- AD INTEGRATION ---
        if (index == 3 && searchPageMiddleBanner != null) {
          return Column(children: [_AdWidget(bannerAd: searchPageMiddleBanner), _KeywordSection(keyword: keyword)]);
        }
        if (index == 7 && searchPageBottomBanner != null) {
          return Column(children: [_AdWidget(bannerAd: searchPageBottomBanner), _KeywordSection(keyword: keyword)]);
        }
        return _KeywordSection(keyword: keyword);
      },
    );
  }

  // Widget for displaying results from search or filtering
  Widget _buildSearchResults() {
    Query query = FirebaseFirestore.instance.collection(AppString.appFeaturedSessions);

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchQuery)
          .where('title', isLessThan: _searchQuery + 'z');
    } else if (_selectedContinent != null) {
      // This is disabled for now, pending data model changes
      // final countries = _getCountriesForContinent(_selectedContinent!);
       // query = query.where('location', whereIn: countries);
    } else if (_selectedMoodId != null) {
      query = query.where('moodId', isEqualTo: _selectedMoodId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No sessions found."));
        }

        final sessionList = snapshot.data!.docs
            .map((doc) => Session.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          itemCount: sessionList.length,
          itemBuilder: (context, index) {
            return CustomSearchCard(
              element: sessionList[index],
              visitedEgoName: '',
              visitedUsersID: '',
            );
          },
        );
      },
    );
  }

  List<String> _getCountriesForContinent(String continent) {
    switch (continent) {
      case 'Africa':
        return ['Nigeria', 'Ghana', 'Kenya', 'South Africa'];
      case 'Asia':
        return ['India', 'China', 'Japan', 'South Korea'];
      case 'Europe':
        return ['United Kingdom', 'Germany', 'France', 'Italy'];
      case 'North America':
        return ['USA', 'Canada', 'Mexico'];
      case 'South America':
        return ['Brazil', 'Argentina', 'Colombia'];
      case 'Australia':
        return ['Australia', 'New Zealand'];
      default:
        return [];
    }
  }
}

// A reusable widget for each "keyword" section to keep the main build method clean
class _KeywordSection extends StatelessWidget {
  const _KeywordSection({Key? key, required this.keyword}) : super(key: key);

  final SearchKeyword keyword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () {
              PageRouter.gotoWidget(
                  CategorySessions(visitedCategory: keyword.category), context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: theme.chipTheme.backgroundColor ?? theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                keyword.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: theme.chipTheme.labelStyle?.color ??
                      (isDarkMode ? Colors.black : Colors.white),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: keyword.stream,
            builder: (context, session) {
              if (session.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!session.hasData || session.data!.docs.isEmpty) {
                return Center(
                  child: Text("No sessions available.",
                      style: GoogleFonts.lato(fontSize: 15.0, color: Colors.grey)),
                );
              }

              final sessionList = session.data!.docs
                  .map((e) => Session.fromJson(e.data()))
                  .toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: sessionList.length,
                itemBuilder: (context, index) {
                  return CustomSearchCard(
                    element: sessionList[index],
                    visitedEgoName: '',
                    visitedUsersID: '',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Helper widget to display an ad banner safely
class _AdWidget extends StatelessWidget {
  final BannerAd? bannerAd;
  const _AdWidget({Key? key, this.bannerAd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bannerAd != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        height: 60,
        child: AdWidget(ad: bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
