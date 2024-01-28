import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitesScreen extends StatefulWidget {
  const InvitesScreen({Key? key}) : super(key: key);

  @override
  _InvitesScreenState createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invites'),
      ),
      body: _buildInvitesList(),
    );
  }

  Widget _buildInvitesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('invites').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final invites = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final inviteData = invites[index].data() as Map<String, dynamic>;
              return _buildInviteCard(
                inviteData['senderUserId'],
                inviteData['recipientUserId'],
                inviteData['status'],
                inviteData['senderName'],
                inviteData['senderSurname'],
                invites[index].id,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildInviteCard(
    String senderUserId,
    String recipientUserId,
    String status,
    String? name,
    String? surname,
    String inviteId,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('Invite from ${name ?? 'Unknown'} ${surname ?? 'Unknown'}'),
        subtitle: Text('Status: $status'),
        trailing: status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _acceptInvite(
                      inviteId,
                      senderUserId,
                      recipientUserId,
                      name!,
                      surname!,
                    ),
                    child: const Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () => _deleteInvite(inviteId),
                    child: const Text('Decline'),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _acceptInvite(
    String inviteId,
    String senderUserId,
    String recipientUserId,
    String name,
    String surname,
  ) async {
    FirebaseFirestore.instance
        .collection('invites')
        .doc(inviteId)
        .update({'status': 'accepted'});

    _addFriend(senderUserId, recipientUserId);
    _addFriend(recipientUserId, senderUserId);
    _deleteInvite(inviteId);

    _addFriendshipToCollection(senderUserId, recipientUserId, name, surname);
    _addFriendshipToCollection(recipientUserId, senderUserId, name, surname);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Friendship Accepted'),
          content: Text('You are now friends with $name $surname.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _addFriend(String userId, String friendId) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'friends': FieldValue.arrayUnion([friendId]),
    });
  }

  void _addFriendshipToCollection(
    String userId,
    String friendId,
    String friendName,
    String friendSurname,
  ) {
    FirebaseFirestore.instance.collection('friends').doc(userId).set({
      friendId: {
        'name': friendName,
        'surname': friendSurname,
      }
    }, SetOptions(merge: true));
  }

  void _deleteInvite(String inviteId) {
    FirebaseFirestore.instance.collection('invites').doc(inviteId).delete();
  }
}
