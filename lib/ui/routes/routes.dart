import 'package:dear_claire/ui/Categories/category_sessions.dart';
import 'package:dear_claire/ui/alter_ego/alter_ego_homepage.dart';
import 'package:dear_claire/ui/alter_ego/alter_ego_login.dart';
import 'package:dear_claire/ui/alter_ego/alter_ego_registration.dart';
import 'package:dear_claire/ui/alter_ego/new_diaries_page.dart';
import 'package:dear_claire/ui/auth/auth_selection.dart';
import 'package:dear_claire/ui/bottom_nav/stack_index_home.dart';
import 'package:dear_claire/ui/chats/chatrooms.dart';
import 'package:dear_claire/ui/create_session/create_session_page.dart';
import 'package:dear_claire/ui/dairy/diary.dart';
import 'package:dear_claire/ui/donate/donate.dart';
import 'package:dear_claire/ui/ego-profile/clairevatar.dart';
import 'package:dear_claire/ui/ego-profile/profile.dart';
import 'package:dear_claire/ui/ego-profile/request_claire_love_form.dart';
import 'package:dear_claire/ui/games/games_home.dart';
import 'package:dear_claire/ui/games/space_shooter.dart';
import 'package:dear_claire/ui/games/tic_tac_toe.dart';
import 'package:dear_claire/ui/games/whot.dart';
import 'package:dear_claire/ui/featured/ego_mode_session_detail.dart';
import 'package:dear_claire/ui/featured/request_feature_form.dart';
import 'package:dear_claire/ui/login/login_screen.dart';
import 'package:dear_claire/ui/menu_items/how_claire_works.dart';
import 'package:dear_claire/ui/menu_items/how_alter_ego_works.dart';
import 'package:dear_claire/ui/menu_items/view_model.dart';
import 'package:dear_claire/ui/sign_up/sign_up.dart';
import 'package:dear_claire/widgets/route_error_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Search/search_page.dart';
import '../splash_screen/custom_splash.dart';
import '../visited_user_ego_page/visited_user_ego_page.dart';

User? currentUser = FirebaseAuth.instance.currentUser;


class AppRoutes {
  static const home = '/featured';
  static const archivedSessions = '/archived_sessions';
  static const diarySessions = '/diary_sessions';
  static const newDiaries = '/newDiaries';
  static const login = '/login';
  static const signUp = '/signUp';
  static const authSelection = '/authSelection';
  static const alterEgoLogin = '/alterEgoLogin';
  static const alterEgoHomepage = '/alterEgoHomepage';
  static const createSessionPage = '/create_session';
  static const egoModeSessionDetail = '/egoModeSessionDetail';
  static const donate = '/donate';
  static const howClaireWorks = '/how_claire_works';
  static const howAlterEgoWorks = '/how_alter_ego_works';
  static const alterEgoRegistration = '/alterEgoRegistration';
  static const requestFeatureForm = '/requestFeatureForm';
  static const requestClaireLoveForm = '/requestClaireLoveForm';
  static const editClairevatar = '/editClairevatar';
  static const searchPage = '/searchPage';
  static const egoPage = '/egoPage';
  static const diaryRooms = '/diaryRooms';
  static const spaceShooter = '/spaceShooter';
  static const ticTacToe = '/ticTacToe';
  static const whot = '/whot';
  static const visitedUserEgoPage = '/visitedUserEgoPage';
  static const customSplashPage = '/customSplash';
  static const categorySessions = '/categorySessions';
  static const games = '/games';


}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // E.g Navigator.of(context).pushNamed(AppRoutes.featured);
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<dynamic>(
          builder: (_) => HomePage(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.newDiaries:
        return MaterialPageRoute<dynamic>(
          builder: (_) => NewDiariesPage(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.diarySessions:
        return MaterialPageRoute<dynamic>(
          builder: (_) => DiaryPage(title: "Dear Claire"),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.login:
        return MaterialPageRoute<dynamic>(
          builder: (_) => LoginPage(),
          settings: settings,
          fullscreenDialog: true,
        );
      case AppRoutes.signUp:
        return MaterialPageRoute<dynamic>(
          builder: (_) => SignUpPage(),
          settings: settings,
          fullscreenDialog: true,
        );
      case AppRoutes.alterEgoHomepage:
        return MaterialPageRoute<dynamic>(
          builder: (_) => AlterEgoHomePage(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.alterEgoLogin:
        return MaterialPageRoute<dynamic>(
          builder: (_) => AlterEgoLoginPage(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.authSelection:
        return MaterialPageRoute<dynamic>(
          builder: (_) => AuthSelectionPage(),
          settings: settings,
          fullscreenDialog: true,
        );
      case AppRoutes.donate:
        return MaterialPageRoute<dynamic>(
          builder: (_) => DonatePage(title: "Donate",),
          settings: settings,
          fullscreenDialog: true,
        );


      case AppRoutes.createSessionPage:
        return MaterialPageRoute<dynamic>(
          builder: (_) => CreateSessionPage(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.egoModeSessionDetail:
        return MaterialPageRoute<dynamic>(
          builder: (_) => EgoModeSessionDetail(featuredSessionModel: ''),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.howClaireWorks:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
              create: (_) => HowClaireWorksProvider(), child: HowClaireWorks()),
          settings: settings,
          fullscreenDialog: true,
        );


        case AppRoutes.howAlterEgoWorks:
         return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
              create: (_) => HowClaireWorksProvider(), child: HowAlterEgoWorks()),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.alterEgoRegistration:
        return MaterialPageRoute<dynamic>(
          builder: (_) => AlterEgoRegistration(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.requestFeatureForm:
        return MaterialPageRoute<dynamic>(
          builder: (_) => RequestFeatureForm(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.requestClaireLoveForm:
        return MaterialPageRoute<dynamic>(
          builder: (_) => RequestClaireLoveForm(currentWithdrawal: '', totalLoveCount: '', userId: '', totalWithdrawn: '', currentWithdrawable: '',),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.editClairevatar:
        return MaterialPageRoute<dynamic>(
          builder: (_) => EditClairevatar(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.searchPage:
        return MaterialPageRoute<dynamic>(
          builder: (_) => SearchPage(title: 'Search Claire',),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.customSplashPage:
        return MaterialPageRoute<dynamic>(
          builder: (_) => CustomSplashPage(),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.categorySessions:
        return MaterialPageRoute<dynamic>(
          builder: (_) => CategorySessions(visitedCategory: ""),
          settings: settings,
          fullscreenDialog: true,
        );

      case AppRoutes.egoPage:
        return MaterialPageRoute<dynamic>(
          builder: (_) => EgoProfilePage(),
          settings: settings,
          fullscreenDialog: false,
        );

      case AppRoutes.spaceShooter:
        return MaterialPageRoute<dynamic>(
          builder: (_) => SpaceShooter(),
          settings: settings,
          fullscreenDialog: false,
        );

      case AppRoutes.ticTacToe:
        return MaterialPageRoute<dynamic>(
          builder: (_) => TicTacToe(),
          settings: settings,
          fullscreenDialog: false,
        );

      case AppRoutes.whot:
        return MaterialPageRoute<dynamic>(
          builder: (_) => Whot(),
          settings: settings,
          fullscreenDialog: false,
        );

      case AppRoutes.diaryRooms:
        return MaterialPageRoute<dynamic>(
          builder: (_) => ChatRoomsPage(),
          settings: settings,
          fullscreenDialog: false,
        );

      case AppRoutes.visitedUserEgoPage:
        return MaterialPageRoute<dynamic>(
          builder: (_) => VisitedUserEgoProfilePage(visitedUsersID: currentUser!.uid, visitedEgoName: 'Activities',),
          settings: settings,
          fullscreenDialog: false,
        );

      case AppRoutes.games:
        return MaterialPageRoute<dynamic>(
          builder: (_) => GamesHome(),
          settings: settings,
          fullscreenDialog: true,
        );


      default:
        return MaterialPageRoute<dynamic>(
          builder: (_) => ErrorPage(),
          settings: settings,
          fullscreenDialog: true,
        );
    }
  }
}
