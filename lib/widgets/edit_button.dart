import 'package:dear_claire/utils/color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class EditButton extends StatelessWidget {
  Function()? onPressed;

  EditButton({Key? key, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Pallet.colorWhite)),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/ic_edit.svg', height: 13,),
              Text(
                ' Edit',
                style: GoogleFonts.lato(
                    fontSize: 12.0,
                    color: Pallet.colorWhite,
                    fontWeight: FontWeight.w400)
              ),
            ],
          ),
        ),
        onPressed: onPressed);
  }
}