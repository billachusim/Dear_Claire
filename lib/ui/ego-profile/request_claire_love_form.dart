import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestClaireLoveForm extends StatefulWidget {
  final String currentWithdrawal;
  final String totalLoveCount;
  final String userId;
  final String currentWithdrawable;
  final String totalWithdrawn;

  const RequestClaireLoveForm({Key? key,
    required this.currentWithdrawal,
    required this.totalLoveCount,
    required this.userId,
    required this.currentWithdrawable,
    required this.totalWithdrawn}) : super(key: key);

  @override
  _RequestClaireLoveFormState createState() => _RequestClaireLoveFormState();
}

class _RequestClaireLoveFormState extends State<RequestClaireLoveForm> {
  TextEditingController _accountNumberController = TextEditingController();
  TextEditingController _bankNameController = TextEditingController();
  TextEditingController _nameOnAccountController = TextEditingController();
  TextEditingController _whyRequestController = TextEditingController();
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
                  child: Row(
                    children: [
                      Container(
                        padding:EdgeInsets.only(left: 20, top:4, bottom: 4),
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

                      SizedBox( width: 12,),

                      Text(
                        "Request Clairelove Form",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                          color: Pallet.colorSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Pallet.colorGrey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(AppString.request_clairelove_form_header,
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
                                return "Enter";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _accountNumberController,
                            decoration: new InputDecoration(
                              hintText: "enter bank account number",
                              labelText: "Account Number",
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
                            keyboardType: TextInputType.number,
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
                                return "enter bank name";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _bankNameController,
                            decoration: new InputDecoration(
                              hintText: "Bank Of The Rising Sun",
                              labelText: "Bank Name",
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
                                return "enter bank name";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _nameOnAccountController,
                            decoration: new InputDecoration(
                              hintText: "Clairechi Naomi Peperempe",
                              labelText: "Name On Account",
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
                                return "What's the need?";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _whyRequestController,
                            decoration: new InputDecoration(
                              hintText: "I will like to...",
                              labelText: "What will this cash be used for?",
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
                      customSwitch(AppString.requestLoveSwitchText7,value7,onChangeFunction7),

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
                      child: Text(AppString.request_clairelove_bottom_header,
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
    var userId = widget.userId.isEmpty ? "null" : widget.userId;
    var totalLove = widget.totalLoveCount.isEmpty ? "null" : widget.totalLoveCount;
    var currentRequest = widget.currentWithdrawal.isEmpty ? "null" : widget.currentWithdrawal;
    var withdrawableLoves = widget.currentWithdrawable.isEmpty ? "null" : widget.currentWithdrawable;
    var totalWithdrawn = widget.totalWithdrawn.isEmpty ? "null" : widget.totalWithdrawn;



    var accountNumber = _accountNumberController.text.isEmpty ? "null" : _accountNumberController.text;
    var bankName = _bankNameController.text.isEmpty ? "null" : _bankNameController.text;
    var whyRequest = _whyRequestController.text.isEmpty ? "null" : _whyRequestController.text;
    var ratedOnPlaystore = _value5Controller.text.isEmpty ? "No" : _value5Controller.text;
    var believeInClaire = _value6Controller.text.isEmpty ? "No" : _value6Controller.text;
    var agreeToTerms = _value7Controller.text.isEmpty ? "No" : _value7Controller.text;
    var email = firebaseServices.currentUser!.email == null ? "null" : firebaseServices.currentUser!.email;


    return """
      Hi, Admin,
      I'm requesting some cash for the month. These are the details:

      *UserId*: $userId

      *Email*: $email
      
      *Total Love*: $totalLove
      
      *Current Withdrawable*: $withdrawableLoves
      
      *Total Withdrawn*: $totalWithdrawn
      
      *Current Request in Naira*: $currentRequest

      *Account Number*: $accountNumber

      *Bank Name*: $bankName

      *Write A Short Need*: $whyRequest

      *Have you rated Claire Diary five stars with a short sweet review on Playstore?*: $ratedOnPlaystore

      *Do you truly believe in the Claire Project? That everyone deserves a true friend in need and indeed?*: $believeInClaire

      *Claire reserves all rights around the use of Claire Love?*: $agreeToTerms
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
