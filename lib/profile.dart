import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_2/login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  String _email = '';
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchEmail();
    _fetchImages();
  }

  Future<void> _fetchEmail() async {
    User? user = _auth.currentUser;
    if (user != null && mounted) {
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        setState(() {
          _email = (snapshot.data() as Map<String, dynamic>)['email'];
        });
      }
    }
  }

  Future<void> _fetchImages() async {
    User? user = _auth.currentUser;
    if (user!= null) {
      QuerySnapshot snapshot = await _firestore
        .collection('user_images')
        .doc(user.uid)
        .collection('images')
        .orderBy('timestamp', descending: true)
        .get();
      setState(() {
        _imageUrls = snapshot.docs.map<String>((doc) => doc['imageUrl']).toList();
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _addImageToFirestore(String imageUrl) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('user_images').doc(user.uid).collection('images').add({
        'imageUrl': imageUrl,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      print('No user logged in');
    }
  }

  Future<void> _uploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile!= null) {
      final File imageFile = File(pickedFile.path);

      // Upload image to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      TaskSnapshot snapshot = await storage.ref().child('images/${_auth.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg').putFile(imageFile);

      if (snapshot.state == TaskState.success) {
        String imageUrl = await snapshot.ref.getDownloadURL();
        await _addImageToFirestore(imageUrl);
        setState(() {
          _imageUrls.add(imageUrl);
        });
      } else {
        print('Error uploading image');
      }
    }
  }

 Future<String> _uploadImageToFirebaseStorage(File imageFile) async {
    // Implement the uploading of the image to Firebase Storage
    FirebaseStorage storage = FirebaseStorage.instance;
    TaskSnapshot snapshot = await storage.ref().child('images/${_auth.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg').putFile(imageFile);

    if (snapshot.state == TaskState.success) {
      // Get the image URL after uploading
      String imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } else {
      print('Error uploading image');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
        title: Text("Profile"),
      ),
      body: Column(
        children: [
          Text(_email, style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              itemCount: _imageUrls.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return Image.network(_imageUrls[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _uploadImage,
            heroTag: null,
            child: Icon(Icons.add_a_photo),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _signOut,
            heroTag: null,
            child: Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}