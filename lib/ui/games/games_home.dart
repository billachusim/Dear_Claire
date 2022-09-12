import 'package:dear_claire/ui/routes/page_router_animation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/color.dart';

class GamesHome extends StatelessWidget {
  const GamesHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Pallet.colorSecondary,
        appBar: AppBar(
          backgroundColor: Pallet.colorPrimary,
          centerTitle: false,
          title: Text('Claire Games',
              textAlign: TextAlign.start,
              maxLines: 1,
              style: GoogleFonts.lato(
                  fontSize: 24.0,
                  color: Pallet.colorWhite,
                  fontWeight: FontWeight.w600)),
        ),
        body: ListView(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.spaceShooter);
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 130,
                          width: 300,
                          decoration: BoxDecoration(
                            image: DecorationImage(image: AssetImage('assets/images/spaceShooter.png'),
                            fit: BoxFit.fill)
                          ),
                          child: Container(),
                        ),
                        TextButton(
                          child: const Text("Shoot Bad Vibes",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.spaceShooter);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.ticTacToe);
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 130,
                          width: 300,
                          decoration: BoxDecoration(
                              image: DecorationImage(image: AssetImage('assets/images/tictactoe.png'),
                                  fit: BoxFit.fill)
                          ),
                          child: Container(),
                        ),
                        TextButton(
                          child: const Text("Tic Tac Toe",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.ticTacToe);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            )
          ],
        ));
  }
}
