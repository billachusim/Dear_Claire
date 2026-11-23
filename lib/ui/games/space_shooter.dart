// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class SpaceShooter extends StatefulWidget {
  const SpaceShooter({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SpaceShooterState();
  }
}

class _SpaceShooterState extends State<SpaceShooter> {
  late final WebViewController _webViewController; // Updated initialization
  String filePath = 'assets/web_games/space/index.html';

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController with JavaScript mode
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    // Load the HTML content from assets
    _loadHtmlFromAssets();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: WebViewWidget(
          controller: _webViewController, // Use the updated controller
        ),
      ),
    );
  }

  Future<void> _loadHtmlFromAssets() async {
    String fileHtmlContents = await rootBundle.loadString(filePath);
    final uri = Uri.dataFromString(
      fileHtmlContents,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );
    _webViewController.loadRequest(uri); // Updated to use loadRequest
  }
}
