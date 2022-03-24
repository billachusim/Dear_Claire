import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dear_claire/utils/color.dart';
import 'package:flutter/material.dart';

class FirstoreTest extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    // FirebaseFirestore.instance
    //     .collection('sessions')
    //     .orderBy("timeCreated", descending: true)
    //     .limit(50)
    //     .get()
    //     .then((QuerySnapshot querySnapshot) {
    //   querySnapshot.docs.forEach((doc) {
    //     print(doc["userNickname"]);
    //     print("Showing sessions" + doc["userNickname"]);
    //   });
    // });
    CollectionReference sessions =
    FirebaseFirestore.instance.collection('sessions');
    return Scaffold(
      backgroundColor: Pallet.colorSplashScreen,
      body: SafeArea(
        child: Center(
          child: StreamBuilder(
              stream: sessions.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot){
                if (!snapshot.hasData) {
                  return Center(child: Text('Loading'));
                }
                print("Showing Loading data... ");
                //var items = sessions.toString();
                print("Showing Sessions data... ${snapshot.toString()}");
                return ListView(

                  children: snapshot.data!.docs.map((sessions){
                    print("Showing Loading data... ");
                    var items = sessions.data().toString();
                    print("Showing Sessions data... $items");
                    return Center(
                      child: ListTile(
                        //title: Text(sessions.data().toString()),
                      ),
                    );
                  }).toList(),
                );
              }),
        ),
      ),
    );
  }
}