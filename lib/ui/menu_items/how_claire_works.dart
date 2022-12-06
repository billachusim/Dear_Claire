import 'package:dear_claire/ui/menu_items/view_model.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HowClaireWorks extends StatefulWidget {
  const HowClaireWorks({Key? key}) : super(key: key);

  @override
  _HowClaireWorksState createState() => _HowClaireWorksState();
}

class _HowClaireWorksState extends State<HowClaireWorks> {
  //Register a key in your state:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Pallet.colorPrimary,
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
                                  color: Pallet.colorPrimary,
                                ),
                                child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Align(
                                              alignment: Alignment.topLeft,
                                              child: Image.asset(
                                                  "assets/images/how_claire_works_icon.png")),

                                          SizedBox(
                                            width: 15,
                                          ),

                                          Text(AppString.read_how_claire_works,
                                              style: GoogleFonts.lato(
                                                  fontSize: 22.0,
                                                  color: Pallet.colorWhite,
                                                  fontWeight: FontWeight.w700,
                                              )),
                                        ],
                                      ),

                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                          AppString.how_claire_works_header,
                                          style: GoogleFonts.lato(
                                              fontSize: 17.0,
                                              color: Pallet.colorWhite,
                                              fontWeight: FontWeight.w700)),

                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(AppString.what_is_claire,
                                              style: GoogleFonts.lato(
                                                  fontSize: 15.0,
                                                  color: Pallet.colorWhite,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                      Text(
                                        AppString.how_claire_works_paragraph1,
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
                                  color: Pallet.colorPrimary,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppString.how_claire_works_header2,
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
                                        AppString.how_claire_works_header,
                                        style: GoogleFonts.lato(
                                            fontSize: 15.0,
                                            color: Pallet.colorWhite,
                                            fontWeight: FontWeight.w700)),
                                    Text(AppString.what_is_claire2,
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

                                        TextSpan(
                                          text:
                                              AppString.how_claire_works_paragraph2,
                                        ),
                                        TextSpan(
                                            text:
                                                AppString.who_needs_claire,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph3),
                                        TextSpan(
                                            text:
                                                AppString.how_does_claire_work,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph4),
                                        TextSpan(
                                            text:
                                                AppString.creators_quote_how_claire_works,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph5),
                                        TextSpan(
                                            text:
                                                AppString.quick_tips,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph6),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph7),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph8),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph9),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph10),
                                        TextSpan(
                                            text:
                                                AppString.how_claire_works_paragraph11),
                                        TextSpan(
                                            text:
                                                '© #DearClaire #SocialFaculty #ClaireToTheWorld 17-11-17.\n\n'),
                                      ],
                                    ))
                                  ],
                                ))),
                    _alterEgo(context),
                    SizedBox(height: 5),
                    _whatCounts(context),
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
              color: Pallet.colorSecondary,
            ),
            child:
                Column(
                    children: [
              Text("Read How Alter Ego Works",
                  style: GoogleFonts.lato(
                      fontSize: 22.0,
                      color: Pallet.colorWhite,
                      fontWeight: FontWeight.w700)),
              SizedBox(
                height: 2,
              ),

              Align(
                alignment: Alignment.topLeft,
                child: Text(" \n 🌺 What Is Alter-Ego?\n",
                    style: GoogleFonts.lato(
                        fontSize: 16.0,
                        color: Pallet.colorWhite,
                        fontWeight: FontWeight.w700)),
              ),
              Text(
                "Alter-Ego is simply defined as a person\'s secondary or alternate personality. It is also used to refer to an intimate or trusted friend. Claire is an alter-ego to all the users of Claire Diary app; being able to feel and understand users... continue",
                style: GoogleFonts.lato(
                    fontSize: 15.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w700),
                // maxLines: 4,
                // overflow: TextOverflow.ellipsis,
              )
            ])));
  }

  _whatCounts(BuildContext context) {
    return InkWell(
        onTap: () {launchEmailApp();} ,
        child: Container(
            margin: EdgeInsets.all(10),
            padding:EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Color.fromRGBO(87, 38, 2, 1.0),
            ),
            child: Column(
              children: [
                Center(
                    child: Text("How Sessions And Advises Are Counted",
                        style: GoogleFonts.lato(
                            fontSize: 18.0,
                            color: Pallet.colorWhite,
                            fontWeight: FontWeight.w700)
                    )
                ),
                Text("\nFor a diary session to be counted, it must contain the phrase Dear Claire and must be more than 50 characters.\n\n"
                    "For an advise to be counted, it must contain the word Darling, must be up to 20 characters and must be sent within 24 hours of the diary session.\n\n"
                    "Claire reserves the right to increase or decrease session and advise counts during the course of cash out verifications.",
                    style: GoogleFonts.lato(
                        fontSize: 15.0,
                        color: Pallet.colorWhite,
                        fontWeight: FontWeight.w600)
                )
              ],
            )
        )
    );
  }


  Widget _appreciateClaireWidget(BuildContext context) {
    return InkWell(
        onTap: () {
          onDonateClicked();
        },
        child: Container(
            width: double.infinity,
            //height: size.height / 3,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Pallet.deepGreen,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Text("Top Up Your Loves",
                    style: GoogleFonts.lato(
                        fontSize: 22.0,
                        color: Pallet.colorWhite,
                        fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "💕 Dear Claire App will remain completely FREE to use but you can donate as little as you wish towards the Dear Claire Project to enable Claire introduce amazing new features and continue to be there for every darling in need 💕\n\n"
                    "The Best Part Is: Your donations are converted and sent back to your Clairelove Wallet; meaning you can still cash out your donations anytime in the future.",
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
            child: Column(
              children: [
                Center(
                    child: Text("Send Feedback",
                    style: GoogleFonts.lato(
                        fontSize: 22.0,
                        color: Pallet.colorWhite,
                        fontWeight: FontWeight.w700)
                    )
                ),
                Text("\nIf you see or hear or experience anything you did not understand while using the app.",
                    style: GoogleFonts.lato(
                        fontSize: 15.0,
                        color: Pallet.colorWhite,
                        fontWeight: FontWeight.w600)
                )
              ],
            )
        )
    );
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
      path: 'dearclaireapp@gmail.com',
      query: encodeQueryParameters(
          <String, String>{'subject': 'Questions About Dear Claire'}),
    );

    launchUrl(emailLaunchUri);
  }

  String getDonateUrl(){
    return AppString.donate_url;
  }

  onDonateClicked() {
    Uri donateUrl = Uri.parse(getDonateUrl());
    launchUrl(donateUrl);
  }

}
