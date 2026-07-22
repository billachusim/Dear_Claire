import 'package:clairediary/services/firebase_services.dart';
import 'package:clairediary/services/user_model.dart';
import 'package:clairediary/ui/visited_user_ego_page/visited_user_model.dart';
import 'package:clairediary/utils/color.dart';
import 'package:clairediary/utils/sharedpreferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// create global instance of firebase service
final FirebaseServices firebaseServices = FirebaseServices();
/// create global instance of UserModel
UserModel userModel = UserModel();
/// create a global instance of the visited user model
VisitedUserModel visitedUserModel = VisitedUserModel();
/// create global instance of sharedPreferences global service
final SharedPreference sharedPreference = SharedPreference();


class AppConstants {
  //static const Float LASH_DELAY = 1500L;
  static const String EVENT_OPEN_ALTER_EGO = "EVENT_OPEN_ALTER_EGO";
  static const String INSTAGRAM_PAGE_URL = "https://www.instagram.com/socialfaculty";
  static const String APP_DYNAMIC_LINK =
      "https://claire.page.link/featured";
  static const String WHATSAPP_URL = "https://api.whatsapp.com/send?phone=2348188578955&text=";
  static const String AGORA_APP_ID = "b476113d691f42dcb7bc6882021afc9c";


  static List<TextStyle> DIARY_FONT_STYLES = [
    GoogleFonts.roboto(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.pacifico(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.lato(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.orbitron(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.openSans(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.montserrat(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.oswald(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.raleway(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.ptSans(fontSize: 36, color:Pallet.colorWhite),
    GoogleFonts.merriweather(fontSize: 36, color:Pallet.colorWhite),


  ];

  static List<String> USER_SESSION_MOODS = [
    'Current Mood',
    "Happy 😊", "Sad 😞", "Excited 😁", "In Love ❤", " Out of Love 💔",  "Depressed 😢", "Motivated 💃",
    "Anxious 😩", "Sick 🤢", "Afraid 😨", "Surprised 😲", "Jealous 🙄", "Upside-down 🙃", "Embarrassed 😳",
    "Gingered 💪", "Fly 👼", "Claire 🌺",
  ];

  static List<Text> ALTER_EGO_FONT_STYLES = [
    Text('Roboto Regular', style:GoogleFonts.roboto(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Pacifico', style:GoogleFonts.pacifico(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Lato', style:GoogleFonts.lato(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Pacifico', style:GoogleFonts.orbitron(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Open Sans', style:GoogleFonts.openSans(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Montserrat', style:GoogleFonts.montserrat(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Oswald', style:GoogleFonts.oswald(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Raleway', style:GoogleFonts.raleway(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Pt Sans', style:GoogleFonts.ptSans(fontSize: 16.sp, fontWeight: FontWeight.bold)),
    Text('Merriweather', style:GoogleFonts.merriweather(fontSize: 16.sp, fontWeight: FontWeight.bold)),

  ];

  static const List<Color> DIARY_COLORS =
  [
    Color(0xFF121212), // Material Design Dark Surface
    Color(0xFF1A1A1A), // Rich Black
    Color(0xFF0D0D0D), // Midnight Black
    Color(0xFF282828), // Matte Black
    Color(0xFF2F4F4F), // Slate Black
    Color(0xFF202124), // Raven Black
    Color(0xFF181818), // Black Pearl
    Color(0xFF000033), // Midnight Blue
    Color(0xFF330033), // Deep Purple
    Color(0xFF36023D), // colorSecondaryDark from Pallet
    Color(0xFF003300), // Kashmir Green
    Color(0xFF330000), // Burnt Umber
    Color(0xFF001219), // Deep Velvety Black
    Color(0xFF0F111A), // Deep Ocean
    Color(0xFF24292e), // Github Dark
    Color(0xFF2D2A2E), // Monokai Pro
    Color(0xFF282A36), // Dracula
    Color(0xFF36454F), // Charcoal Black
    Color(0xFF1B2240), // Dark Blue
    Color(0xFF390000), // Dark Red
    Color(0xFF6E247F),
    Color(0xFF6200EA),
    Color(0xFFE5642D),
    Color(0xFF36127B),
    Color(0xFF38383A),
    Color(0xFF202067),
    Color(0xFF432807),
    Color(0xFF5B6103),
    Color(0xFF7C0D1E),
    Color(0xFF540351),
    Color(0xFF131A62),
    Color(0xFF212121),
    Color(0xFF880E4F),
    Color(0xFF1B5E20),
    Color(0xFF004D40)
  ];

  static const List<String> DIARY_COLORS_HEXCODE =
  [
    "#121212", "#1A1A1A", "#0D0D0D", "#282828",
    "#2F4F4F", "#202124", "#181818", "#000033",
    "#330033", "#36023D", "#003300", "#330000",
    "#001219", "#0F111A", "#24292e", "#2D2A2E",
    "#282A36", "#36454F", "#1B2240", "#390000",
    "#6E247F", "#6200EA", "#E5642D", "#36127B",
    "#38383A", "#202067", "#432807", "#5B6103",
    "#7C0D1E", "#540351", "#131A62", "#212121",
    "#880E4F", "#1B5E20", "#004D40"
  ];

  static const List<String> TOAST_NUMBERS =
  [
    "Toast1", "Toast2", "Toast3", "Toast4",
    "Toast5", "Toast6", "Toast7", "Toast8",
    "Toast9", "Toast10", "Toast11", "Toast12",
    "Toast13", "Toast14", "Toast15","Toast16",
    "Toast17", "Toast18", "Toast19"
  ];

  static const String PREF_KEY_USER_AVATAR_URL = "PREF_KEY_USER_AVATAR_URL";
  static const String PREF_KEY_USER_FCM_ID = "PREF_KEY_USER_FCM_ID";
  static const String PREF_KEY_USER_GENDER = "PREF_KEY_USER_GENDER";
  static const String PREF_KEY_USER_NICKNAME = "PREF_KEY_USER_NICKNAME";
  static const String PREF_KEY_USER_EMAIL = "PREF_KEY_USER_EMAIL";
  static const String PREF_KEY_USER_USER_TYPE = "PREF_KEY_USER_USER_TYPE";
  static const String PREF_KEY_USER_ID = "PREF_KEY_USER_ID";
  static const String PREF_KEY_ALTER_EGO_ID = "PREF_KEY_ALTER_EGO_ID";
  static const String PREF_KEY_ALTER_EGO_ACCESS_CODE = "PREF_KEY_ALTER_EGO_ACCESS_CODE";
  static const String PREF_KEY_USER_SECRET_CODE = "PREF_KEY_USER_SECRET_CODE";
  static const String PREF_KEY_USER_LAST_UNLOCKED = "PREF_KEY_USER_LAST_UNLOCKED";
  static const String PREF_KEY_USER_TIME_REGISTERED = "PREF_KEY_USER_TIME_REGISTERED";
  static const String PREF_KEY_COMPLETED_ALTER_EGO_ORIENTATION = "PREF_KEY_COMPLETED_ALTER_EGO_ORIENTATION";
  static const String PREF_KEY_EGO_MESSAGE = "PREF_KEY_EGO_MESSAGE";

  static const String PREF_KEY_SESSION_UPDATE_NOTIFICATION_ENABLED =
      "PREF_KEY_SESSION_UPDATE_NOTIFICATION_ENABLED";
  static const String PREF_KEY_DAILY_REMINDER_ENABLED = "PREF_KEY_DAILY_REMINDER_ENABLED";
  static const String PREF_KEY_DAILY_REMINDER_HOUR = "PREF_KEY_DAILY_REMINDER_HOUR";
  static const String PREF_KEY_ALTER_EGO_HAS_DONATED = "PREF_KEY_ALTER_EGO_HAS_DONATED";

  static const String PREF_THEME = "PREF_THEME";

}

extension StingExtentions on String {
  String get svg => 'assets/images/svg/$this.svg';
  String get png => 'assets/images/png/$this.png';
}
