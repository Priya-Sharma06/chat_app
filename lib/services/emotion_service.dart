import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class EmotionService {
  static Future<Map<String, dynamic>?> detect(
      FirebaseFirestore firestore) async {
    final fiveMinutesAgo =
        DateTime.now().subtract(Duration(minutes: 5));

    final snapshot = await firestore
        .collection('messages')
        .where('timestamp',
            isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .get();

    final messages =
        snapshot.docs.map((e) => e['text'] as String).toList();

    if (messages.isEmpty) return null;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/analyze_bulk_emotions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}