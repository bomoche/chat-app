import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FindFriends extends StatefulWidget {
  const FindFriends({Key? key}) : super(key: key);

  @override
  _FindFriendsState createState() => _FindFriendsState();
}

class _FindFriendsState extends State<FindFriends> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0C1C2E),
        title: const Text('Find Friends'),
      ),
      body: _buildFriendsList(),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('friends').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final friends = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendData = friends[index].data() as Map<String, dynamic>;
              final name = friendData['name'];
              final surname = friendData['surname'];

              return _buildFriendCard(name, surname);
            },
          );
        }
      },
    );
  }

  Widget _buildFriendCard(String name, String surname) {
    final displayName = '${name ?? "Unknown"} ${surname ?? "Unknown"}';

    return Card(
      color: const Color.fromRGBO(255, 255, 98, 0.98),
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(displayName),
        trailing: ElevatedButton(
          onPressed: () => {},
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(const Color(0xff0C1C2E)),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
          child: const Text('Chat'),
        ),
      ),
    );
  }
}
