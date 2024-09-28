import 'package:flutter/material.dart';

class EgoStream extends StatefulWidget {
  @override
  _EgoStreamState createState() => _EgoStreamState();
}

class _EgoStreamState extends State<EgoStream> {

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
        body: Material(
          child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              height: 90,
              child: ListView(
                // This next line does the trick.
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  Container(
                    width: 160.0,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(35)
                    ),
                  ),
                  Container(
                    width: 160.0,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(35)
                    ),
                  ),
                  Container(
                    width: 160.0,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(35)
                    ),
                  ),
                  Container(
                    width: 160.0,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(35)
                    ),
                  ),
                  Container(
                    width: 160.0,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(35)
                    ),
                  ),
                ],
              ),
            ),
        ),
      );
  }
}