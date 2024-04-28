  import 'package:cloud_firestore/cloud_firestore.dart';


class Chat {
    final String text;
    final String senderId;
    final Timestamp timestamp;

    Chat({required this.text, required this.senderId, required this.timestamp});

    Map<String, dynamic> toMap() {
      return {
        'text': text,
        'senderId': senderId,
        'timestamp': timestamp,
      };
    }
  }