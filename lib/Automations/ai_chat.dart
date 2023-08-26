import 'dart:async';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dear_claire/Automations/threedots.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import '../Admob/ad_state.dart';
import '../services/api_consts.dart';
import 'chatmessage.dart';

class AIChat extends StatefulWidget {
  @override
  _AIChat createState() => _AIChat();
}

class _AIChat extends State<AIChat> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  //ChatGPT? chatGPT;
  bool _isImageSearch = false;

  StreamSubscription? _subscription;
  bool _isTyping = false;

  BannerAd? aiChatTopBanner;
  bool _bannerIsLoaded = false;

  @override
  void initState() {
    super.initState();
    //chatGPT = ChatGPT.instance.builder(API_KEY);
  }

  @override
  void dispose() {
    //chatGPT!.genImgClose();
    _subscription?.cancel();
    super.dispose();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);

    // Implement a top location banner ad unit.
    adState.initialization.then((status) {
      setState(() {
        aiChatTopBanner = BannerAd(
            size: AdSize.banner,
            adUnitId: adState.aiChatTopBanner,
            request: const AdRequest(),
            listener: BannerAdListener(
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
              },
            )
        )
          ..load();
        _bannerIsLoaded = true;
      });
    });
  }


  // Link for api - https://beta.openai.com/account/api-keys

  /*void _sendMessage() {
    if (_controller.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "A Darling",
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    _controller.clear();

    if (_isImageSearch) {
      final request = GenerateImage(message.text, 1, size: "512x512");

      _subscription = chatGPT!
          .generateImageStream(request)
          .asBroadcastStream()
          .listen((response) {
        Vx.log(response.data!.last!.url!);
        insertNewData(response.data!.last!.url!, isImage: true);
      });
    } else {
      final request = CompleteReq(
          prompt: message.text, model: kTranslateModelV3, max_tokens: 200);

      _subscription = chatGPT!
          .onCompleteStream(request: request)
          .distinct()
          .first
          .asStream()
          .listen((response) {
        print(response!.choices.first.text.trim());
        insertNewData(response.choices.first.text.trim(), isImage: false);
      });
   }
  }*/

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "Cl(ai)re",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            //onSubmitted: (value) => _sendMessage(),
            decoration: const InputDecoration.collapsed(
                hintText: "Question/description"),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            _isImageSearch = false;
           // _sendMessage();
          },
        ),

        TextButton(
            onPressed: () {
              _isImageSearch = true;
              //_sendMessage();
            },
            child: const Text("Generate Image"))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("AI Chat")),
        body: SafeArea(
          child: Column(
            children: [
              // Top ad unit is here
              if (aiChatTopBanner != null && _bannerIsLoaded)
                SizedBox(
                  height: 60,
                  child: AdWidget(ad: aiChatTopBanner!),
                )
              else
                SizedBox(height: 70, child: Text('Relevant ads only', style: TextStyle(color: Colors.white),),),

              Flexible(
                  child: ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _messages[index];
                    },
                  )),
              if (_isTyping) const ThreeDots(),
              const Divider(
                height: 1.0,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: _buildTextComposer(),
              )
            ],
          ),
        ));
  }
}
