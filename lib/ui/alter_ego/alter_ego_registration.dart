import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AlterEgoRegistration extends StatefulWidget {
  const AlterEgoRegistration({Key? key}) : super(key: key);

  @override
  _AlterEgoRegistrationState createState() => _AlterEgoRegistrationState();
}

class _AlterEgoRegistrationState extends State<AlterEgoRegistration> {
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _fullAddressController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _nameOfSchoolController = TextEditingController();
  TextEditingController _nameOfBestFriendController = TextEditingController();
  TextEditingController _bestFriendNumController = TextEditingController();
  TextEditingController _amountDonatedController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _facebookNameController = TextEditingController();
  TextEditingController _instagramUserNameController = TextEditingController();
  TextEditingController _shortBioController = TextEditingController();
  TextEditingController _value1Controller = TextEditingController();
  TextEditingController _value2Controller = TextEditingController();
  TextEditingController _value3Controller = TextEditingController();
  TextEditingController _value4Controller = TextEditingController();
  TextEditingController _value5Controller = TextEditingController();
  TextEditingController _value6Controller = TextEditingController();
  TextEditingController _value7Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool value1 = false;
  bool value2 = false;
  bool value3 = false;
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
                Container(
                  color: Pallet.colorGrey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(AppString.alter_ego_orientation_first_header,
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
                      Container(
                        color: Pallet.colorWhite,
                        child: TextFormField(
                            onChanged: (value) {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Enter full name";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _fullNameController,
                            decoration: new InputDecoration(
                              hintText: "Nne Chike",
                              labelText: "Full Name",
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
                                return "Enter full address";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _fullAddressController,
                            decoration: new InputDecoration(
                              hintText: "No 16 Solo Ogun street, Aguda, Lagos, Nigeria",
                              labelText: "Full Address",
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
                                return "Enter a valid phone number";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _phoneController,
                            decoration: new InputDecoration(
                              hintText: "+2348188578955",
                              labelText: "Phone Number",
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
                            keyboardType: TextInputType.phone,
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
                                return "Enter your age";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _ageController,
                            decoration: new InputDecoration(
                              hintText: "16",
                              labelText: "Age",
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
                                return "Enter name of your school or occupation";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _nameOfSchoolController,
                            decoration: new InputDecoration(
                              hintText: "University Of Mumbai",
                              labelText: "Name of School Or Occupation",
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
                                return "Enter your best friends or relative name";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _nameOfBestFriendController,
                            decoration: new InputDecoration(
                              hintText: "Tochi",
                              labelText: "Name of Best Friend Or Relative",
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
                                return "Enter your best friends or relative phone number";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _bestFriendNumController,
                            decoration: new InputDecoration(
                              hintText: "08011110000",
                              labelText: "Phone Number of Best Friend Or Relative",
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
                            keyboardType: TextInputType.phone,
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
                                return "Enter an amount you donated";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _amountDonatedController,
                            decoration: new InputDecoration(
                              hintText: "₦1000",
                              labelText: "Amount Donated",
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
                                return "Enter a valid email";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _emailController,
                            decoration: new InputDecoration(
                              hintText: "dearclaireapp@gmail.com",
                              labelText: "Email",
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
                                return "Enter your Facebook Name";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _facebookNameController,
                            decoration: new InputDecoration(
                              hintText: "Sandra Ezra Chidimma",
                              labelText: "Facebook Name",
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
                                return "Enter your Instagram Username";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _instagramUserNameController,
                            decoration: new InputDecoration(
                              hintText: "@socialfaculty",
                              labelText: "Instagram Username",
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
                                return "Enter a short bio of yourself";
                              }
                            },
                            textInputAction: TextInputAction.next,
                            controller: _shortBioController,
                            decoration: new InputDecoration(
                              hintText: "I am this and that",
                              labelText: "Write a Short Bio About Inner Self",
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
                      customSwitch(AppString.switchText1,value1,onChangeFunction1),
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                        child: Divider(height: 1, color: Pallet.grey,),
                      ),
                      customSwitch(AppString.switchText2,value2,onChangeFunction2),
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                        child: Divider(height: 1, color: Pallet.grey,),
                      ),
                      customSwitch(AppString.switchText3,value3,onChangeFunction3),
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                        child: Divider(height: 1, color: Pallet.grey,),
                      ),
                      customSwitch(AppString.switchText4,value4,onChangeFunction4),
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
                      customSwitch(AppString.switchText7,value7,onChangeFunction7),

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
                      child: Text(AppString.switchBottomHeader,
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
  onChangeFunction1(bool newValue1){
    setState(() {
      if(!value1){
        _value1Controller.text = "Yes";
      } else{
        _value1Controller.text = "No";
      }
      value1 = newValue1;
      print("value1.. $value1, ${_value1Controller.text}");
    });
  }

  onChangeFunction2(bool newValue2){
    setState(() {
      if(!value2){
        _value2Controller.text = "Yes";
      } else {
          _value2Controller.text = "No";
      }
      value2 = newValue2;
      print("value2.. $value2, ${_value2Controller.text}");
    });
  }
  onChangeFunction3(bool newValue3){
    setState(() {
      if(!value3){
        _value3Controller.text = "Yes";
      } else {
        _value3Controller.text = "No";
      }
      value3 = newValue3;
      print("value3.. $value3, ${_value3Controller.text}");
    });
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
        _value7Controller.text = "Yes";
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
    var fullName = _fullNameController.text.isEmpty ? "null" : _fullNameController.text;
    var fullAddress = _fullAddressController.text.isEmpty ? "null" : _fullAddressController.text;
    var phoneNumber = _phoneController.text.isEmpty ? "null" : _phoneController.text;
    var age = _ageController.text.isEmpty ? "null" : _ageController.text;
    var nameOfSchoolOrOccupation = _nameOfSchoolController.text.isEmpty ? "null" : _nameOfSchoolController.text;
    var nameOfFriendOrRelative = _nameOfBestFriendController.text.isEmpty ? "null" : _nameOfBestFriendController.text;
    var phoneNumberFriendOrRelative = _bestFriendNumController.text.isEmpty ? "null" : _bestFriendNumController.text;
    var amountDonated = _amountDonatedController.text.isEmpty ? "null" : _amountDonatedController.text;
    var emailAddress = _emailController.text.isEmpty ? "null" : _emailController.text;
    var facebookName = _facebookNameController.text.isEmpty ? "null" : _facebookNameController.text;
    var instagramUsername = _instagramUserNameController.text.isEmpty ? "null" : _instagramUserNameController.text;
    var shortBio = _shortBioController.text.isEmpty ? "null" : _shortBioController.text;
    var interestedInBecoming = _value1Controller.text.isEmpty ? "No" : _value1Controller.text;
    var makeWorldBetter = _value2Controller.text.isEmpty ? "No" : _value2Controller.text;
    var followingOnInstagram = _value3Controller.text.isEmpty ? "No" : _value3Controller.text;
    var learnedOnInstagram = _value4Controller.text.isEmpty ? "No" : _value4Controller.text;
    var ratedOnPlaystore = _value5Controller.text.isEmpty ? "No" : _value5Controller.text;
    var believeInClaire = _value6Controller.text.isEmpty ? "No" : _value6Controller.text;
    var readyToBeClaire = _value7Controller.text.isEmpty ? "No" : _value7Controller.text;
    var email = firebaseServices.currentUser!.email == null ? "null" : firebaseServices.currentUser!.email;


    return """
      I'm ready for the final Clairentation. These are my details:

      *UserId*: $userUid

      *Email*: $email

      *FullName*: $fullName
            
      *FullAddress*: $fullAddress

      *PhoneNumber*: $phoneNumber

      *Age*: $age

      *Name Of School Or Occupation*: $nameOfSchoolOrOccupation

      *Name Of Friend Or Relative*: $nameOfFriendOrRelative

      *Phone Number Of Friend Or Relative*: $phoneNumberFriendOrRelative

      *Amount Donated*: $amountDonated

      *Email Address*: $emailAddress

      *Facebook Name*: $facebookName

      *Instagram Username*: $instagramUsername

      *Write a Short Bio About Inner Self*: $shortBio

      *Are you truly interested in becoming an Alter-Ego not just to read random people's Diary Sessions but to reply to them with happy vibes and good advises?*: $interestedInBecoming

      *Do you believe that the world will be a better place if people treat other people like themselves wish to be treated?*: $makeWorldBetter

      *Are you following @socialfaculty on Instagram?*: $followingOnInstagram

      *Did you first learn about Claire on Instagram?*: $learnedOnInstagram

      *Have you rated Claire Diary five stars with a short sweet review on Playstore?*: $ratedOnPlaystore

      *Do you truly believe in the Claire Project? That everyone deserves a true friend in need and indeed?*: $believeInClaire

      *Are you ready to become Claire now?*: $readyToBeClaire
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
