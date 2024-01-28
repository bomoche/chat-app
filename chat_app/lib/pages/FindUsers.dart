// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FindUsers extends StatefulWidget {
  const FindUsers({super.key});

  @override
  State<FindUsers> createState() => _FindUsersState();
}

class _FindUsersState extends State<FindUsers> {
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
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final users = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = userData['userId'];
              final name = userData['name'];
              final surname = userData['surname'];

              return _buildFriendCard(userId, name, surname);
            },
          );
        }
      },
    );
  }

  Widget _buildFriendCard(String userId, String name, String surname) {
    final displayName = '$name $surname ';

    return Card(
      color: const Color.fromRGBO(255, 255, 98, 0.98),
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(displayName),
        trailing: ElevatedButton(
          onPressed: () => _sendInvite(userId, displayName),
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(const Color(0xff0C1C2E)),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
          child: const Text('Invite'),
        ),
      ),
    );
  }

  void _sendInvite(String recipientUserId, String recipientName) async {
    final senderUserId = FirebaseAuth.instance.currentUser?.uid;
    final invitesRef = FirebaseFirestore.instance.collection('invites');
    final usersRef = FirebaseFirestore.instance.collection('users');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Sending Invite'),
          content: Text('Please wait while we send the invite...'),
        );
      },
    );

    final senderUserData = (await usersRef.doc(senderUserId).get()).data();
    final senderName = senderUserData?['name'];
    final senderSurname = senderUserData?['surname'];

    final existingInvite = await invitesRef
        .where('senderUserId', isEqualTo: senderUserId)
        .where('recipientUserId', isEqualTo: recipientUserId)
        .get();

    Navigator.of(context).pop();

    if (existingInvite.docs.isEmpty) {
      final inviteId = '$senderUserId-$recipientUserId';

      await invitesRef.doc(inviteId).set({
        'senderUserId': senderUserId,
        'recipientUserId': recipientUserId,
        'status': 'pending',
        'recipientName': recipientName,
        'senderName': senderName,
        'senderSurname': senderSurname,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite sent successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite already sent')),
      );
    }
  }
}
