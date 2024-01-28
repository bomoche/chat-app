import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late File? _selectedImage;
  late String _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = '';
    _selectedImage = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xff0C1C2E),
      ),
      body: FutureBuilder(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Display user profile with fetched data
            final user = snapshot.data as Map<String, dynamic>;

            return Column(
              children: [
                // Circular profile picture
                GestureDetector(
                  onTap: () => _pickImage(),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : NetworkImage(_imageUrl) as ImageProvider<Object>,
                  ),
                ),
                const SizedBox(height: 16),
                // User details
                _buildUserDetailItem(Icons.person, 'Name', user['name']),
                _buildUserDetailItem(Icons.person, 'Surname', user['surname']),
                _buildUserDetailItem(Icons.email, 'Email', user['email']),
                _buildUserDetailItem(
                    Icons.location_on, 'Location', user['location']),
                _buildUserDetailItem(Icons.cake, 'Birthday', user['dob']),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildUserDetailItem(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value ?? 'N/A'),
    );
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = _auth.currentUser;
    final uid = user?.uid;

    if (uid != null) {
      final userData = await _firestore.collection('users').doc(uid).get();
      return userData.data() as Map<String, dynamic>;
    } else {
      throw 'User not authenticated';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      DefaultCacheManager().emptyCache();
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // Upload the selected image to Firebase Storage
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    final user = _auth.currentUser;
    final uid = user?.uid;

    if (uid != null && _selectedImage != null) {
      final storageRef =
          _storage.ref().child('profile_images').child('$uid.jpg');
      print('Uploading image...');
      final uploadTask = storageRef.putFile(_selectedImage!);

      await uploadTask.whenComplete(() async {
        print('Upload complete!');
        final imageUrl = await storageRef.getDownloadURL();

        await _firestore
            .collection('users')
            .doc(uid)
            .update({'profilePicture': imageUrl});

        setState(() {
          _imageUrl = imageUrl;
        });
      });
    }
  }
}
