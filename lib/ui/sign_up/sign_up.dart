import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:dear_claire/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPage createState() => _SignUpPage();
}

class _SignUpPage extends State<SignUpPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _secretCodeController = TextEditingController();
  TextEditingController _genderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();


  void _launchClairePolicySite() async =>
      await canLaunch("https://sites.google.com/view/claire-diary/claire-privacy-policy")
          ? await launch("https://sites.google.com/view/claire-diary/claire-privacy-policy")
          : throw 'Could not launch Instagram';



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Pallet.colorWhite,
      body: SafeArea(
        child: Stack(children: [
          SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(16.0),
                color: Pallet.colorWhite,
                child: Form(
                  key: _formKey,
                  child: Column(
                    //mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment:Alignment.topLeft,
                        child: Container(
                          padding:EdgeInsets.only(top:8, bottom: 8),
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

                      Text(AppString.create_ego_welcome,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.lato(
                              fontSize: 24.0,
                              color: Pallet.colorPrimaryDark,
                              //fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 2,
                      ),
                      Text(AppString.create_ego_note,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: Pallet.colorSecondaryDark,
                              fontWeight: FontWeight.w700)),
                      SizedBox(
                        height: 25,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(AppString.create_ego_sub_note,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorTextGray,
                                    fontWeight: FontWeight.w400)),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          Container(
                            color: Pallet.colorWhite,
                            child: TextFormField(
                                onChanged: (value) {},
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Enter Email";
                                  } else if (value.length < 4) {
                                    return "Email should be up to 4 digits";
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                                controller: _emailController,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(RegExp("[ ]")),
                                ],
                                decoration: new InputDecoration(
                                  hintText: "claireamaka@gmail.com",
                                  labelText: "Type your full Email Address",
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
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Pallet.colorBlack,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w400)),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          Container(
                            color: Pallet.colorWhite.withAlpha(20),
                            child: BuildPasswordField(
                                "****", _secretCodeController),
                          ),

                          SizedBox(
                            height: 25,
                          ),

                          Container(
                            color: Pallet.colorWhite,
                            child: TextFormField(
                                onChanged: (value) {},
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Enter a gender";
                                  }
                                },
                                textInputAction: TextInputAction.done,
                                controller: _genderController,
                                decoration: new InputDecoration(
                                  hintText: AppString.gender_hint_text,
                                  labelText: AppString.gender_label_text,
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
                                cursorColor: Pallet.colorBlack,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorBlack,
                                    fontWeight: FontWeight.w400)),
                          ),

                          SizedBox(height: 5,),

                          Container(
                            alignment: Alignment.center,
                            child: Text("By tapping Create Ego, you are accepting Dear Claire's Terms Of Use and Privacy Policy",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    color: Pallet.colorPrimary,
                                    fontWeight: FontWeight.w600)),
                          ),
                          GestureDetector(
                            onTap: _launchClairePolicySite,
                            child: Container(

                              alignment: Alignment.center,
                              child: Text("Tap here to open Terms Of Use and Privacy Policy",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.lato(
                                      fontSize: 10.0,
                                      color: Pallet.colorBlue,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),


                          SizedBox(
                            height: 40,
                          ),
                          GestureDetector(
                            onTap: () async {
                              var validate = _formKey.currentState!.validate();
                              if (validate) {
                                await _firebaseServices.register(
                                    context,
                                    _emailController.text,
                                    _secretCodeController.text,
                                  _genderController.text,
                                );
                              }
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 38,
                              decoration: BoxDecoration(
                                  color: Pallet.colorWhite,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6)),
                                  gradient: LinearGradient(colors: [
                                    Pallet.colorPrimary,
                                    Pallet.colorPrimaryDark
                                  ])),
                              child: Center(
                                child: Text(AppString.create_ego,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        fontSize: 16.0,
                                        color: Pallet.colorWhite,
                                        //fontStyle: FontStyle.normal,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 44,),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.login);
                          },
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(AppString.i_already_have_ego,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        fontSize: 12.0,
                                        color: Pallet.colorTextGray,
                                        fontWeight: FontWeight.w500)),
                                SizedBox(
                                  width: 2,
                                ),
                                Text(AppString.open_up,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                        fontSize: 13.0,
                                        color: Pallet.colorPrimary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
            ),
          ),

        ]),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }
}

class BuildPasswordField extends StatefulWidget {
  final hintText;
  final _secretCodeController;

  BuildPasswordField(this.hintText, this._secretCodeController);

  @override
  _BuildPasswordFieldState createState() => _BuildPasswordFieldState();
}

class _BuildPasswordFieldState extends State<BuildPasswordField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Pallet.colorWhite,
      child: TextFormField(
        onChanged: (value) {
        },
        validator: (value) {
          if (value!.isEmpty) {
            return "Enter Ego code. Ego Code means password.";
          } else if (value.length < 4) {
            return "Ego code should be up to 4 digits";
          }
          return null;
        },
        textInputAction: TextInputAction.next,
        controller: widget._secretCodeController,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: "Choose an Ego Code. It means password.",
          labelStyle: TextStyle(color: Pallet.colorTextGray),
          focusedBorder: new OutlineInputBorder(
              borderSide: new BorderSide(color: Pallet.colorPrimary)),
          enabledBorder: new OutlineInputBorder(
              borderSide: new BorderSide(
            color: Pallet.colorTextGray,
          )),
          suffixIcon: Container(
            width: 55,
            child: IconButton(
              color: Pallet.colorTextGray,
              onPressed: _togglePasswordView,
              icon: _isHidden
                  ? const Icon(Icons.visibility)
                  : const Icon(Icons.visibility_off),
            ),
          ),
          contentPadding: EdgeInsets.only(right: 15, left: 15),
        ),
        keyboardType: TextInputType.text,
        cursorColor: Pallet.colorBlack,
        style: GoogleFonts.lato(
            fontSize: 12.0,
            color: Pallet.colorBlack,
            //fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w400),
        obscureText: _isHidden,
      ),
    );
  }

  void _togglePasswordView() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }
}
