import 'package:dear_claire/services/firebase_services.dart';
import 'package:dear_claire/ui/login/login_screen.dart';
import 'package:dear_claire/ui/routes/routes.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AlterEgoLoginPage extends StatefulWidget {
  const AlterEgoLoginPage({Key? key}) : super(key: key);

  @override
  _AlterEgoLoginPageState createState() => _AlterEgoLoginPageState();
}

class _AlterEgoLoginPageState extends State<AlterEgoLoginPage> {

  TextEditingController _emailController = TextEditingController();
  TextEditingController _secretCodeController = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();

  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {

    //sharedPreference.getAlterEgoAccessCode();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Pallet.colorSecondary,
          centerTitle: true,
          title: Text('Alter Ego Mode',
              textAlign: TextAlign.start,
              maxLines: 1,
              style: GoogleFonts.lato(
                  fontSize: 26.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w600)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding:EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8,),
                      Align(
                        alignment:Alignment.topLeft,
                        child: Text(
                          '''Welcome,''',
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.lato(
                              height: 1.171875,
                              fontSize: 24.0,
                              color: Pallet.colorSecondary,
                              fontWeight: FontWeight.w700),

                        ),
                      ),
                      Align(
                        alignment:Alignment.topLeft,
                        child: Text(AppString.alter_ego_login_note,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.lato(
                              height: 1.171875,
                              fontSize: 14.0,
                              color: Pallet.colorSecondaryDark,
                              fontWeight: FontWeight.w600),

                        ),
                      ),
                      SizedBox(height: 50,),
                      Container(
                        color: Pallet.colorWhite,
                        child: TextFormField(
                            onChanged: (value) {},
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Enter a valid ClaireId";
                              }
                            },
                            //onSaved: _emailController.text,
                            textInputAction: TextInputAction.next,
                            controller: _emailController,
                            decoration: new InputDecoration(
                              hintText: "claire123",
                              labelText: "ClaireId",
                              labelStyle: TextStyle(
                                  color: Pallet.colorTextGray
                              ),
                              focusedBorder: new OutlineInputBorder(
                                  borderSide:
                                  new BorderSide(color: Pallet.colorPrimary)),
                              enabledBorder: new OutlineInputBorder(
                                  borderSide:
                                  new BorderSide(color: Pallet.colorTextGray)),
                              contentPadding: EdgeInsets.only(
                                  right: 15, left: 15),
                            ),
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.lato(
                                fontSize: 12.0,
                                color: Pallet.colorBlack,
                                fontWeight: FontWeight.w400)
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Container(
                        color: Pallet.colorWhite.withAlpha(20),
                        child: BuildSecretCodeField("******", _secretCodeController),
                      ),
                      SizedBox(height: 51,),
                      _signInBtn(),
                      SizedBox(height: 30,),
                      Text('Or',style: TextStyle(color: Pallet.colorSecondaryDark, fontSize: 16, fontWeight: FontWeight.w600),),
                      SizedBox(height: 30,),
                      _requestAccessBtn(),
                    ]
                ),
              ),
            ),
          ),
        ));
  }


  Widget _signInBtn(){
    return InkWell(
      onTap: () async {
        var validate =  _formKey.currentState!.validate();
        if(validate){
          setState(() {
            sharedPreference.setAlterEgoId(_emailController.text);
            sharedPreference.setAlterEgoAccessCode(_secretCodeController.text);
          });
          await _firebaseServices.getUserAlterEgo(context,_emailController.text, _secretCodeController.text);
        }
      },
      child: Container(
        padding: EdgeInsets.all(5),
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          gradient: LinearGradient(
            begin: Alignment(-0.37857140550652835, -1.9473685559777252),
            end: Alignment(1.2428571464417884, 2.526316110739735),
            stops: [0.0, 0.856177031993866, 1.0],
            colors: [
              Pallet.colorPrimary,
              Pallet.colorSecondary,
              Pallet.colorSecondaryDark,
            ],
          ),
        ),
        child: Center(
            child: Text('<  SWITCH  >',
             style: GoogleFonts.lato(
                  fontSize: 12.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w700),
            ),
        ),
      ),
    );
  }


  Widget _requestAccessBtn(){
    return InkWell(
      onTap: () {
        Navigator. pop(context);
        Navigator.of(context).pushNamed(AppRoutes.howAlterEgoWorks);
      },
      child: Container(
        padding: EdgeInsets.all(5),
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          gradient: LinearGradient(
            begin: Alignment(-0.37857140550652835, -1.9473685559777252),
            end: Alignment(1.2428571464417884, 2.526316110739735),
            stops: [0.0, 0.856177031993866, 1.0],
            colors: [
              Pallet.colorBlue,
              Pallet.green,
              Pallet.deepGreen,
            ],
          ),
        ),
        child: Center(
          child: Text('REQUEST  ACCESS',
            style: GoogleFonts.lato(
                fontSize: 12.0,
                color: Pallet.colorWhite,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

}






