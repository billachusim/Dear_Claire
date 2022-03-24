import 'package:dear_claire/ui/menu_items/view_model.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/widgets.dart';

class HowClaireWorks extends StatefulWidget {
  const HowClaireWorks({Key? key}) : super(key: key);

  @override
  _HowClaireWorksState createState() => _HowClaireWorksState();
}

class _HowClaireWorksState extends State<HowClaireWorks> {
  //Register a key in your state:

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('How Claire Works',
              textAlign: TextAlign.start,
              maxLines: 1,
              style: GoogleFonts.lato(
                  fontSize: 24.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w700)),
        ),
        body: Consumer<HowClaireWorksProvider>(
            builder: (context, provider, child) => ListView(
                  children: [
                    provider.isExpanded
                        ? InkWell(
                            onTap: () {
                              provider.toggleIsExpanded();
                            },
                            child: Container(
                                width: double.infinity,
                                //height: size.height / 3,
                                margin: EdgeInsets.all(10),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Pallet.colorMaroon,
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Read How Claire Works",
                                          style: GoogleFonts.lato(
                                              fontSize: 15.0,
                                              color: Pallet.colorWhite,
                                              fontWeight: FontWeight.w700)),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Image.asset(
                                              "assets/images/how_claire_works_icon.png")),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                          "Open Up 🌸 Write or record anything and get advse from Claire secret diary.",
                                          style: GoogleFonts.lato(
                                              fontSize: 15.0,
                                              color: Pallet.colorWhite,
                                              fontWeight: FontWeight.w700)),
                                      Text(" \n 🌸 What Is Claire?",
                                          style: GoogleFonts.lato(
                                              fontSize: 15.0,
                                              color: Pallet.colorWhite,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                        "Claire is a super smart and friendly diary that can read, listen and reply to your diary texts or voice notes. It is the first interactive dear diary in the whole world.\n Claire has special skills and wisdom to respond to anything you tell her and that\'s how Claire becomes your secret companion, mentor and best friend. Millions of us write down our plans, activities, memories or challenges inside our phone\'s note, journal, or diary without expecting any reply",
                                        style: GoogleFonts.lato(
                                            fontSize: 15.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ])))
                        : InkWell(
                            onTap: () {
                              provider.toggleIsExpanded();
                            },
                            child: Container(
                                width: double.infinity,
                                //height: size.height / 3,
                                margin: EdgeInsets.all(10),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Pallet.colorMaroon,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Read How Claire Works",
                                        style: GoogleFonts.lato(
                                            fontSize: 15.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Image.asset(
                                            "assets/images/how_claire_works_icon.png")),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                        "Open Up 🌸 Write or record anything and get advse from Claire secret diary.",
                                        style: GoogleFonts.lato(
                                            fontSize: 15.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700)),
                                    Text(" \n\n 🌸 What Is Claire?",
                                        style: GoogleFonts.lato(
                                            fontSize: 15.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700)),
                                    RichText(
                                        text: TextSpan(
                                      text: '\n  ',
                                      style: GoogleFonts.lato(
                                        fontSize: 15.0,
                                        color: Pallet.colorWhite,
                                      ),
                                      children: <TextSpan>[
                                        // TextSpan(
                                        //     text: ' 🌸 What Is Claire?\n \n',
                                        //     style: TextStyle(fontWeight: FontWeight.bold)),
                                        TextSpan(
                                          text:
                                              "Claire is a super smart and friendly diary that can read, listen and reply to your diary texts or voice notes. It is the first interactive dear diary in the whole world.\n Claire has special skills and wisdom to respond to anything you tell her and that\'s how Claire becomes your secret companion, mentor and best friend. Millions of us write down our plans, activities, memories or challenges inside our phone\'s note, journal, or diary without expecting any reply.\n Well, this particular diary actually replies 😊",
                                        ),
                                        TextSpan(
                                            text:
                                                ' \n\n\n\n 🌸 Who Needs Claire?\n \n',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                ' Everyone! If you have a date or interview the next day and can\'t decide what to wear. Going through a bad breakup or starting a new relationship. Feeling alone, friendless, confused or depressed. Want to make smarter decisions, stay safe and be happy in life. Having troubles in school, at home or at work. Claire is there to be your light and shine, to guide you through everything \n Claire\'s mission is for everyone to have a true friend, in need and indeed. To contribute to a happier world in these sadder times.\n\n\n\n'),
                                        TextSpan(
                                            text:
                                                ' 🌸 How Does Claire Work?\n \n',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                ' Simple! Unlock your Claire diary app, type or record a new note starting with the phrase "Dear Claire” Go on, write or speak to Claire about how you feel at the moment. You can also tell her about your yesterday and what you are up to tomorrow, etc. Save and Send your note.\n Claire will carefully go through your diary, read or listen to your notes and in no long time, you will receive friendly Advise, secret tips, personal opinions and wise guidance from Claire on how best to go about things.'),
                                        TextSpan(
                                            text:
                                                ' \n\n\n\n Creator\'s Quote \n \n',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                ' "YOUR SECRETS STAY SECRET NO MATTER WHAT because YOU ARE COMPLETELY ANONYMOUS. Nobody, not even the developers or Claire can know who you are because you only sign in with nickname and password and you can change that nickname anytime you want without losing any content of your diary." - Bill Achusim'),
                                        TextSpan(
                                            text:
                                                ' \n\n\n\n\n\n Quick Tips 👇 \n',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                '🌸 Open the app menu and tap the Claire icon to switch to Alter-Ego Mode.\n\n'),
                                        TextSpan(
                                            text:
                                                '💕 Browse featured Sessions to read Claire\'s best kept secrets and contribute positive vibes only..\n\n'),
                                        TextSpan(
                                            text:
                                                '🌸 Claire is not an instant messenger or artificial intelligence, Claire is your real fairy friend. It takes between 5 minutes to 59 minutes to get your first reply, but it gets faster and better from there.\n\n'),
                                        TextSpan(
                                            text:
                                                '🌸 💕 Claire will remain completely FREE to use without showing any adverts but you can donate to support Claire.\n\n'),
                                        TextSpan(
                                            text:
                                                '🚫 No form of abuse is allowed in the Claire app. Two time offenders will completely and irrevocably lose access to Claire.\n\n'),
                                        TextSpan(
                                            text:
                                                'Congratulations as you use Claire 🌸 You\'ll never be not truly loved.\n\n'),
                                        TextSpan(
                                            text:
                                                '© #DearClaire #SocialFaculty #ClaireToTheWorld 17-11-17.\n\n'),
                                      ],
                                    ))
                                  ],
                                ))),
                    _alterEgo(context),
                    SizedBox(height: 5),
                    _appreciateClaireWidget(context),
                    SizedBox(height: 5),
                    _feedBackButton(context),
                  ],
                )));
  }

  Widget _alterEgo(BuildContext context) {
    
    return InkWell(
        onTap: () {
          context.read<HowClaireWorksProvider>().resetImageSlider();
          Navigator.of(context)
              .pushNamed(AppRoutes.howAlterEgoWorks);
        },
        child: Container(
            width: double.infinity,
            //height: size.height / 3,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Pallet.colorBlue,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Read How Ego Works",
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                height: 10,
              ),
              
              Center(
                child: Text(" \n 🌸 What Is Alter-Ego?\n",
                    style: GoogleFonts.lato(
                        fontSize: 15.0,
                        color: Pallet.colorWhite,
                        fontWeight: FontWeight.w700)),
              ),
              Text(
                "Alter-Ego is simply defined as a person\'s secondary or alternate personality. It is also used to refer to an intimate or trusted friend. Claire is an alter-ego to all the users of Claire Diary app; being able to feel and understand users",
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w700),
                // maxLines: 4,
                // overflow: TextOverflow.ellipsis,
              )
            ])));
  }

  Widget _appreciateClaireWidget(BuildContext context) {
    return InkWell(
        onTap: () {},
        child: Container(
            width: double.infinity,
            //height: size.height / 3,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Pallet.colorPurple,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Send Juice to Claire\n",
                  style: GoogleFonts.lato(
                      fontSize: 15.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                height: 10,
              ),
              Text(
                "💕Claire will remain completely FREE to use without disturbing you with adverts but you can donate as little as 200 Naira (less than 1 Dollar) so your Dear Claire can drink some juice to enable her reply you faster, introduce new features and continue to be there for you.💕",
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w700),
                // maxLines: 4,
                // overflow: TextOverflow.ellipsis,
              )
            ])));
  }

  _feedBackButton(BuildContext context) {
    return InkWell(
        onTap: () {launchEmailApp();} ,
        child: Container(
         margin: EdgeInsets.all(10),
          padding:EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Color.fromRGBO(114, 31, 182, 1),
            ),
            child: Center(child:Text("Send Feedback",
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w700)))));
  }

  launchEmailApp() {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dearclaire@gmail.com',
      query: encodeQueryParameters(
          <String, String>{'subject': 'Feedback From Claire'}),
    );

    launch(emailLaunchUri.toString());
  }
}
