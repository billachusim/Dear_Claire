import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIChat extends StatefulWidget {
  @override
  _AIChat createState() => _AIChat();
}

class _AIChat extends State<AIChat> {
  final apiKey = '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';
  final endpoint = 'https://api.openai.com/v1/engines/davinci/completions';
  final _textController = TextEditingController();
  late String _advice = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dear Claire'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Enter your session',
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Send user input to OpenAI API and get advice
              _advice = await _getAdvice(_textController.text);
              setState(() {});
            },
            child: Text('Get advice'),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: Text(_advice.toString(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getAdvice(String input) async {
    try {
      final body = jsonEncode({
        'prompt': input,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      final uri = Uri.https('api.openai.com', '/v1/engines/davinci/completions');
      final response = await http.post(uri, headers: headers, body: body);
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print("RESPONSE BODY IS: ${response.body}");
        print(response.statusCode);

        return response.body;
      } else {
        throw Exception('Failed to get advice. Error: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to get advice. Please check your internet connection');
    }
  }


}
