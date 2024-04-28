import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_2/chatFun.dart';

class ChatScreen extends StatefulWidget {
  final String friendId;

  ChatScreen({required this.friendId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  String _friendEmail = '';

  @override
  void initState() {
    super.initState();
    _getFriendEmail();
  }

  _getFriendEmail() async {
    final DocumentSnapshot doc =
        await _firestore.collection('users').doc(widget.friendId).get();
    setState(() {
      _friendEmail = doc['email'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_friendEmail),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('friends')
                    .doc(widget.friendId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final List<DocumentSnapshot> messages = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot message = messages[index];

                      return ListTile(
                        title: Text(message['text']),
                        subtitle: Text(
                            message['senderId'] == _auth.currentUser!.uid
                                ? 'You'
                                : 'Friend'),
                        leading: CircleAvatar(
                          child: Text(
                              message['senderId'] == _auth.currentUser!.uid
                                  ? 'You'
                                  : 'Friend'),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        tileColor: message['senderId'] == _auth.currentUser!.uid
                            ? Colors.grey[300]
                            : Colors.white,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        final Chat chat = Chat(
                          text: _messageController.text,
                          senderId: _auth.currentUser!.uid,
                          timestamp: Timestamp.now(),
                        );

                        _firestore
                            .collection('users')
                            .doc(_auth.currentUser!.uid)
                            .collection('friends')
                            .doc(widget.friendId)
                            .collection('messages')
                            .add(chat.toMap());

                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
