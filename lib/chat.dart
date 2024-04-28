import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_2/chatScreen.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').doc(_auth.currentUser!.uid).collection('friends').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<DocumentSnapshot> friends = snapshot.data!.docs;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot friend = friends[index];

              return ListTile(
                title: Text(friend['email']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(friendId: friend.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}