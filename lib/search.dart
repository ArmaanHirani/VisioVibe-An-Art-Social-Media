import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_2/login.dart';
import 'package:email_validator/email_validator.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search for email",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  await _searchForEmail(value);
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_searchResults[index]),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // Add the user as a friend
                      await _addFriend(_searchResults[index]);
                    },
                    child: Text("Add Friend"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchForEmail(String email) async {
    final User? user = _auth.currentUser;

    if (user!= null) {
      final List<String> searchResults = [];

      // Validate the email address
      if (EmailValidator.validate(email)) {
        // Query the Firestore for users with the given email
        final QuerySnapshot querySnapshot = await _firestore
           .collection('users')
           .where('email', isEqualTo: email.toLowerCase())
           .get();

        // If the email is associated with one or more users, add it to the search results
        if (querySnapshot.docs.isNotEmpty) {
          searchResults.add(email);
        }
      }

      setState(() {
        _searchResults = searchResults;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> _addFriend(String email) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser!= null) {
      // Query the Firestore for the user with the given email
      final QuerySnapshot querySnapshot = await _firestore
         .collection('users')
         .where('email', isEqualTo: email.toLowerCase())
         .get();

      if (querySnapshot.docs.isNotEmpty) {
        final String friendUid = querySnapshot.docs.first.id;

        final DocumentReference userRef = _firestore.collection('users').doc(currentUser.uid);

        await userRef.collection('friends').doc(friendUid).set({
          'email': email,
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('The user has been added as a friend.'),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
      );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}