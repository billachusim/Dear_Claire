import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/constant.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterwave/core/flutterwave.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class DonatePage extends StatefulWidget {
  DonatePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedAmount = "";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Pallet.colorPrimaryDark,
        title: Text(widget.title,style: GoogleFonts.lato(
            fontSize: 24.0,
            color: Pallet.colorWhite,
            fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Form(
            key: this.formKey,
            child: ListView(
              children: <Widget>[
                SizedBox(
                  height: 30,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40, top: 40),
                    child: Text("Thank you for your support",
                        //textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                            fontSize: 24.0,
                            color: Pallet.colorBlack,
                            fontWeight: FontWeight.w700)),
                  ),
                ),

                GestureDetector(
                  //onTap: _showSingleChoiceDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text("Kindly select your preferred amount to proceed",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              fontSize: 16.0,
                              color: Pallet.colorTextGray,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                Container(
                  color: Pallet.colorWhite,
                  child: TextFormField(
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                      validator: (value) =>
                      value!.isNotEmpty ? null : "Amount is required",
                      controller: this.amountController,
                      readOnly: true,
                      onTap: this._openBottomSheet,
                      decoration: new InputDecoration(
                        labelText: "Amount",
                        labelStyle:
                        TextStyle(color: Pallet.colorBlack),
                        focusedBorder: new OutlineInputBorder(
                            borderSide: new BorderSide(
                                color: Pallet.colorPrimary)),
                        enabledBorder: new OutlineInputBorder(
                            borderSide: new BorderSide(
                                color: Pallet.colorTextGray)),
                        contentPadding:
                        EdgeInsets.only(right: 15, left: 15),
                      ),
                      cursorColor: Pallet.colorBlack,
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
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {},
                      validator: (value) =>
                      value!.isNotEmpty ? null : "Phone number is required",
                      controller: this.phoneController,
                      //readOnly: true,
                      //onTap: this._openBottomSheet,
                      decoration: new InputDecoration(
                        labelText: "Phone number",
                        labelStyle:
                        TextStyle(color: Pallet.colorBlack),
                        focusedBorder: new OutlineInputBorder(
                            borderSide: new BorderSide(
                                color: Pallet.colorPrimary)),
                        enabledBorder: new OutlineInputBorder(
                            borderSide: new BorderSide(
                                color: Pallet.colorTextGray)),
                        contentPadding:
                        EdgeInsets.only(right: 15, left: 15),
                      ),
                      cursorColor: Pallet.colorBlack,
                      style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: Pallet.colorBlack,
                          fontWeight: FontWeight.w400)),
                ),
                SizedBox(
                  height: 100,
                ),
                GestureDetector(
                  onTap: this._onPressed,
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
                      child: Text("Proceed",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: Pallet.colorWhite,
                              //fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _onPressed() {
    print('Clicked onPressed');
    if (this.formKey.currentState!.validate()) {
      this._handlePaymentInitialization();
    }
  }

  _handlePaymentInitialization() async {
    var uuid = Uuid();
    userModel = await firebaseServices.getUserInfo();
    print('');
    var transactionRef = userModel.nickname! + this.amountController.text.toString().trim() + uuid.v1();
    print('Show user details $transactionRef');
    final flutterwave = Flutterwave.forUIPayment(
        context: this.context,
        amount: this.amountController.text.toString().trim(),
        currency: "NGN",
        acceptAccountPayment: true,
        acceptCardPayment: true,
        acceptMpesaPayment: true,
        acceptGhanaPayment: true,
        acceptUSSDPayment: true,
        acceptBankTransfer: true,
        acceptFrancophoneMobileMoney: true,
        //isPermanent: true,
        publicKey: AppString.ravePublicKay,
        encryptionKey: AppString.raveSecretKay,
        email: userModel.email!,
        fullName: userModel.nickname!,
        phoneNumber: this.phoneController.text.toString().trim(),
        txRef: transactionRef,
        narration: AppString.appName,
        isDebugMode: false,

    );
    final response = await flutterwave.initializeForUiPayments();

    if (response != null) {
      this.showLoading(response.data!.status);
    } else {
      this.showLoading("No Response!");
    }
  }

  void _openBottomSheet() {
    showModalBottomSheet(
        context: this.context,
        builder: (context) {
          return this._getCurrency();
        });
  }

  Widget _getCurrency() {
    final amounts = [
      Amount.TWO,
      Amount.FIVE,
      Amount.ONE_K,
      Amount.TWO_K,
    ];
    return Container(
      height: 250,
      margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
      color: Colors.white,
      child: ListView.builder(
        itemCount: amounts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: GestureDetector(
              onTap: (){
            this._handleCurrencyTap(amounts[index], index);
              },
                child: Center(child: Column(
                  children: [
                    Text(amounts[index],
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 4),
                    Divider(height: 1)
                  ],
                ),
                )
            ),
          );
        },
      )
    );
  }

  _handleCurrencyTap(String amount, int index) {
    this.setState(() {
      this.selectedAmount = amount;
      index == 0 ? this.amountController.text = "200" :
      index == 1 ? this.amountController.text = "500" :
      index == 2 ? this.amountController.text = "1000" :
      index == 3 ? this.amountController.text = "2000" :
      this.amountController.text = amount;
    });
    Navigator.pop(this.context);
  }

  Future<void> showLoading(String? message) {
    return showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 50,
            child: Text(message!),
          ),
          actions: [
            FlatButton(
              child: Text('Dismiss'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }
}

class Amount{
  static const one = 1;
  static const two = 2;
  static const four = 4;
  static const seven = 7;

  static const String TWO = "₦200 (Less than \$$one)";
  static const String FIVE = "₦500 (Less than \$$two)";
  static const String ONE_K = "₦1000 (Less than \$$four)";
  static const String TWO_K = "₦2000 (Less than \$$seven)";
}

final List<String> amounts = [
  '200',
  '500',
  '1000',
  '2000',
];

class SingleNotifier extends ChangeNotifier {
  String _currentAmount = amounts[0];
  SingleNotifier();

  String get currentCountry => _currentAmount;

  updateAmount(String value) {
    if (value != _currentAmount) {
      _currentAmount = value;
      notifyListeners();
    }
  }
}