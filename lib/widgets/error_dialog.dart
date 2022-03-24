import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ErrorDialog {

  final BuildContext context;
  ErrorDialog(this.context);

  void show (String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Text(title, style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),),
        ),
        content: new Text(message, style: TextStyle(fontSize: 16),),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true, child: new Text("Ok"),
            onPressed: () => Navigator.of(context).pop(),),

        ],
      ),
    );
  }

}
