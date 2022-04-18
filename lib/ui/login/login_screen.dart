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

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _secretCodeController = TextEditingController();
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
        child: SingleChildScrollView(
          child: Container(
              padding: EdgeInsets.all(16.0),
              color: Pallet.colorWhite,
              child: Form(
                key: _formKey,
                child: Stack(
                  children: <Widget>[
                    Column(
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

                        Text(AppString.ego_login_welcome,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 24.0,
                                color: Pallet.colorPrimaryDark,
                                //fontStyle: FontStyle.normal,
                                fontWeight: FontWeight.w700)),
                        SizedBox(
                          height: 2,
                        ),
                        Text(AppString.ego_login_note,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.lato(
                                fontSize: 14.0,
                                color: Pallet.colorSecondaryDark,
                                fontWeight: FontWeight.w600)),
                        SizedBox(
                          height: 40,
                        ),
                        Center(
                          child: Text(AppString.ego_login_sub_note,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorTextGray,
                                  fontWeight: FontWeight.w400)),
                        ),
                        SizedBox(
                          height: 10,
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
                                hintText: "johndoe@gmail.com",
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
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.lato(
                                  fontSize: 12.0,
                                  color: Pallet.colorBlack,
                                  fontWeight: FontWeight.w400)),
                        ),
                        SizedBox(
                          height: 35,
                        ),
                        Container(
                          color: Pallet.colorWhite.withAlpha(20),
                          child: BuildSecretCodeField(
                              "****", _secretCodeController),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          alignment: Alignment.topRight,
                          child: Text("Forgot Ego Code?",
                              textAlign: TextAlign.right,
                              style: GoogleFonts.lato(
                                  fontSize: 15.0,
                                  color: Pallet.colorBlack,
                                  fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(height: 5,),

                        Container(
                          alignment: Alignment.center,
                          child: Text("By tapping Open Up, you are accepting Dear Claire's Terms Of Use and Privacy Policy",
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
                          height: 41,
                        ),

                        GestureDetector(
                          onTap: () async {
                            var validate = _formKey.currentState!.validate();
                            if (validate) {
                              await _firebaseServices.signIn(
                                  context,
                                  _emailController.text,
                                  _secretCodeController.text);
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
                              child: Text(AppString.open_up,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                      fontSize: 16.0,
                                      color: Pallet.colorWhite,
                                      //fontStyle: FontStyle.normal,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),

                        SizedBox(height: 54),

                        Align(
                          alignment: Alignment.bottomCenter,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.signUp);
                            },
                            child: Container(
                              alignment: Alignment.bottomCenter,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(AppString.im_new_here,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.lato(
                                          fontSize: 12.0,
                                          color: Pallet.colorTextGray,
                                          fontWeight: FontWeight.w500)),
                                  SizedBox(
                                    width: 2,
                                  ),
                                  Text(AppString.create_ego,
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
                  ],
                ),
              )),
        ),
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

class BuildSecretCodeField extends StatefulWidget {
  final hintText;
  final _secretCodeController;

  BuildSecretCodeField(this.hintText, this._secretCodeController);

  @override
  _BuildSecretCodeField createState() => _BuildSecretCodeField();
}

class _BuildSecretCodeField extends State<BuildSecretCodeField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Pallet.colorWhite,
      child: TextFormField(
        onChanged: (value) {},
        validator: (value) {
          if (value!.isEmpty) {
            return "Enter Ego code";
          } else if (value.length < 4) {
            return "Ego code should be up to 4 digits";
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        controller: widget._secretCodeController,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: "Ego Code",
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
          contentPadding:
              EdgeInsets.only(top: 15, bottom: 15, right: 15, left: 15),
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
