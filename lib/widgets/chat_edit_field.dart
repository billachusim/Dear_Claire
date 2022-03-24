import 'package:dear_claire/utils/color.dart';
import 'package:dear_claire/utils/helper.dart';
import 'package:dear_claire/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ChatEditField extends StatefulWidget {
  final Function(String value) onTap;
  final record;

  ChatEditField({Key? key, required this.onTap, this.record}) : super(key: key);

  @override
  _ChatEditFieldState createState() => _ChatEditFieldState();
}

class _ChatEditFieldState extends State<ChatEditField> {
  final TextEditingController _controller = TextEditingController();
  bool isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: SvgPicture.asset(
                  AppImages.appEmoji,
                  color: Colors.pink,
                  height: 24,
                )),
            CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: Icon(
                  Icons.linked_camera_rounded,
                  size: 30,
                  color: Colors.pink,
                ),
                ),
            Flexible(
              child: new ConstrainedBox(
                constraints: new BoxConstraints(
                  minWidth: getDeviceWidth(context),
                  maxWidth: getDeviceWidth(context),
                  minHeight: 20.0,
                  maxHeight: 135.0,
                ),
                child: new Scrollbar(
                  child: Container(
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Pallet.colorWhite,
                    ),
                    child: new TextField(
                      cursorColor: Pallet.colorSplashScreen,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: _controller,
                      onChanged: (text) {
                        if (text.length >= 1) {
                          setState(() {
                            isTyping = true;
                          });
                        } else {
                          setState(() {
                            isTyping = false;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.only(left: 13.0, right: 13.0),
                        hintText: "Positive vibes only...",
                        hintStyle: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            isTyping == true
                ? FloatingActionButton(
                    onPressed: () {
                      if (_controller.text.isNotEmpty)
                        widget.onTap(_controller.text);
                      _controller.text = '';
                    },
                    mini: true,
                    backgroundColor: Pallet.colorSplashScreen,
                    child: SvgPicture.asset(
                      AppImages.appSend,
                      height: 25,
                    ))
                : FloatingActionButton(
                    onPressed: () => widget.record!(),
                    mini: true,
                    backgroundColor: Pallet.colorPrimary,
                    child: Icon(
                      Icons.mic_rounded,
                      size: 35,
                    ),),
          ],
        ),
      ),
    );
  }
}
