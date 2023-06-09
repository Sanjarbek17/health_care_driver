// import http
import 'dart:convert';

import 'package:http/http.dart' as http;

// sendMessage function to send message to the user
Future<void> sendMessage(Map data) async {
  String url = 'https://fcm.googleapis.com/fcm/send';

  // header
  // this not secure, you should replace this with your server_key
  String serverKey = 'AAAAOnLyMKI:APA91bHwCqvFRCjShbQ58DU3Bxjr4Al0ULdG0RG2ukoYK_KyjzqWntJ_nSPpamESVXy7WS89NK9BePxFaQyCMKaMwD9KMti83cwmOOD1huxgpPaVNpNoI9mBQ-s4V-c_0bihGUNPWHf5';

  // header
  Map<String, String> header = {
    'Content-Type': 'application/json',
    'Authorization': 'key=$serverKey',
  };

  // body
  Map body = {
    "to": "/topics/user",
    "notification": {"title": "Ambulance", "body": "Help is on the way"},
    "data": data,
  };

  // encode Map to JSON
  String bodyEncoded = json.encode(body);

  Uri uri = Uri.parse(url);
  // send post request using http library
  var r = await http.post(uri, body: bodyEncoded, headers: header);

  // ignore: avoid_print
  print(r.statusCode);
}
