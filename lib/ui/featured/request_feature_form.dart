import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestFeatureForm extends StatefulWidget {
  const RequestFeatureForm({Key? key}) : super(key: key);

  @override
  _RequestFeatureFormState createState() => _RequestFeatureFormState();
}

class _RequestFeatureFormState extends State<RequestFeatureForm> {
  TextEditingController _sessionTitleController = TextEditingController();
  TextEditingController _sessionEgoNameController = TextEditingController();
  TextEditingController _whyFeatureController = TextEditingController();
  TextEditingController _value4Controller = TextEditingController();
  TextEditingController _value5Controller = TextEditingController();
  TextEditingController _value6Controller = TextEditingController();
  TextEditingController _value7Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool value4 = false;
  bool value5 = false;
  bool value6 = false;
  bool value7 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [

                Align(
                  alignment:Alignment.topLeft,
                  child: Container(
                    padding:EdgeInsets.only(left: 16, bottom: 8),
                    child: GestureDetector(
                        onTap: (){
                          print("Clicking on X");
                          Navigator.pop(context);
                        },
                        child: SvgPicture.asset("assets/images/ic_close.svg",
                          width: 17.0,
                          height: 17.0,)
                    ),
                  ),
                ),

                Container(
                  color: Pallet.colorGrey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(AppString.request_feature_form_header,
                          //textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Pallet.colorBlack,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        color: Pallet.colorWhite,
                        child: TextFormField(
                            onChanged: (value) {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Enter the Session Title";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _sessionTitleController,
                            decoration: new InputDecoration(
                              hintText: "title of session",
                              labelText: "Session Title",
                              labelStyle:
                              TextStyle(color: Pallet.colorTextGray),
                              focusedBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Pallet.colorPrimary)),
                              enabledBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Pallet.colorTextGray)),
                              contentPadding:
                              EdgeInsets.only(right: 15, left: 15),
                            ),
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorBlack,
                                fontWeight: FontWeight.w400)),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        color: Pallet.colorWhite,
                        child: TextFormField(
                            onChanged: (value) {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Enter the Session Ego Name";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _sessionEgoNameController,
                            decoration: new InputDecoration(
                              hintText: "ego name on the session",
                              labelText: "Session Ego Name",
                              labelStyle:
                              TextStyle(color: Pallet.colorTextGray),
                              focusedBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Pallet.colorPrimary)),
                              enabledBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Pallet.colorTextGray)),
                              contentPadding:
                              EdgeInsets.only(right: 15, left: 15),
                            ),
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorBlack,
                                fontWeight: FontWeight.w400)),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        color: Pallet.colorWhite,
                        child: TextFormField(
                            onChanged: (value) {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Explain Why Feature";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _whyFeatureController,
                            decoration: new InputDecoration(
                              hintText: "I will like to...",
                              labelText: "Write A Short Explanation",
                              labelStyle:
                              TextStyle(color: Pallet.colorTextGray),
                              focusedBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Pallet.colorPrimary)),
                              enabledBorder: new OutlineInputBorder(
                                  borderSide: new BorderSide(
                                      color: Pallet.colorTextGray)),
                              contentPadding:
                              EdgeInsets.only(right: 15, left: 15),
                            ),
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorBlack,
                                fontWeight: FontWeight.w400)),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Pallet.colorGrey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(AppString.switchHeaderTwo,
                          //textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Pallet.colorBlack,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only( top: 10.0,left: 20.0, right: 20.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                        child: Divider(height: 1, color: Pallet.grey,),
                      ),
                      customSwitch(AppString.switchText5,value5,onChangeFunction5),
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                        child: Divider(height: 1, color: Pallet.grey,),
                      ),
                      customSwitch(AppString.switchText6,value6,onChangeFunction6),
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                        child: Divider(height: 1, color: Pallet.grey,),
                      ),
                      customSwitch(AppString.request_feature_switchText7,value7,onChangeFunction7),

                    ],
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                  color: Pallet.colorGrey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(AppString.continue_feature_request_on_whatsapp,
                          //textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              fontSize: 13.0,
                              color: Pallet.colorBlack,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onContinueToWhatsAppClicked,
                  child: Container(
                    color: Pallet.green,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Image.asset('assets/images/ic_whatsapp_white.png',
                            height: 25, width: 25,),
                          Padding(
                            padding: const EdgeInsets.only(right: 75.0),
                            child: Text("CONTINUE TO WHATSAPP",
                                //textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                    fontSize: 16.0,
                                    color: Pallet.colorWhite,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customSwitch(String text, bool value, Function onChange){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 200,
          child: Text(text,
              //textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                  fontSize: 13.0,
                  color: Pallet.colorBlack,
                  fontWeight: FontWeight.w600)
          ),
        ),
        Spacer(),
        Switch(
            value: value,
            inactiveTrackColor: Pallet.colorGrey,
            activeTrackColor: Pallet.colorPink.withOpacity(0.3),
            activeColor: Pallet.colorPink,
            onChanged: (newValue) {
              onChange(newValue);
            })
      ],
    );

  }

  onChangeFunction4(bool newValue4){
    setState(() {
      if(!value4){
        _value4Controller.text = "Yes";
      } else{
        _value4Controller.text = "No";
      }
      value4 = newValue4;
      print("value4.. $value4, ${_value4Controller.text}");
    });
  }
  onChangeFunction5(bool newValue5){
    setState(() {
      if(!value5){
        _value5Controller.text = "Yes";
      } else {
        _value5Controller.text = "No";
      }
      value5 = newValue5;
      print("value5.. $value5, ${_value5Controller.text}");
    });
  }
  onChangeFunction6(bool newValue6){
    setState(() {
      if(!value6){
        _value6Controller.text = "Yes";
      } else {
        _value6Controller.text = "No";
      }
      value6 = newValue6;
      print("value6.. $value6, ${_value6Controller.text}");
    });
  }
  onChangeFunction7(bool newValue7){
    setState(() {
      if(!value7) {
        _value7Controller.text = "Agree";
      } else {
        _value7Controller.text = "No";
      }
      value7 = newValue7;
      print("value7.. $value7, ${_value7Controller.text}");
    });
  }

  String? getWhatsAppUrl(String payload ){
    return AppString.WHATSAPP_URL + (payload);
  }

  onContinueToWhatsAppClicked() {
    var whatsAppUrl = getWhatsAppUrl(getPayload() ?? "");
    launch(whatsAppUrl!);
  }

  String? getPayload(){
    var userUid = firebaseServices.currentUser!.uid.isEmpty ? "null" : firebaseServices.currentUser!.uid;

    var sessionTitle = _sessionTitleController.text.isEmpty ? "null" : _sessionTitleController.text;
    var sessionEgoName = _sessionEgoNameController.text.isEmpty ? "null" : _sessionEgoNameController.text;
    var whyFeature = _whyFeatureController.text.isEmpty ? "null" : _whyFeatureController.text;
    var ratedOnPlaystore = _value5Controller.text.isEmpty ? "No" : _value5Controller.text;
    var believeInClaire = _value6Controller.text.isEmpty ? "No" : _value6Controller.text;
    var readyToBeClaire = _value7Controller.text.isEmpty ? "No" : _value7Controller.text;
    var email = firebaseServices.currentUser!.email == null ? "null" : firebaseServices.currentUser!.email;


    return """
      Hi, Admin,
      I'm requesting to feature a session. These are the details:

      *UserId*: $userUid

      *Email*: $email

      *Session Title*: $sessionTitle

      *Session Ego Name*: $sessionEgoName

      *Write A Short Reason To Feature*: $whyFeature

      *Have you rated Claire Diary five stars with a short sweet review on Playstore?*: $ratedOnPlaystore

      *Do you truly believe in the Claire Project? That everyone deserves a true friend in need and indeed?*: $believeInClaire

      *This might cost nothing or up to 10,000 Claireloves?*: $readyToBeClaire
    """.trim();
  }
}

class MultiSwitchOptions extends StatefulWidget {
  const MultiSwitchOptions({Key? key}) : super(key: key);

  @override
  _MultiSwitchOptionsState createState() => _MultiSwitchOptionsState();
}

class _MultiSwitchOptionsState extends State<MultiSwitchOptions> {
  @override
  Widget build(BuildContext context) {
    return Container(

    );
  }
}
