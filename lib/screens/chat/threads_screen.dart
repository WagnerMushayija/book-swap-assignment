// @ lib/screens/chat/threads_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThreadsScreen extends StatelessWidget {
  const ThreadsScreen({super.key});

  // Helper to get user email from Firestore.
  Future<String> _getUserEmail(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()!.containsKey('email')) {
        return doc.data()!['email'];
      }
      // This fallback is returned when a user document is NOT found in Firestore.
      return 'Unknown User';
    } catch (e) {
      // This will catch network errors or other issues.
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChatProvider>();
    final me = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: prov.threads(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No chats yet'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i].data();
              final members = List<String>.from(d['members']);
              final otherUid = members.firstWhere((x) => x != me.uid, orElse: () => me.uid);
              final chatId = prov.chatIdWith(otherUid);

              return FutureBuilder<String>(
                future: _getUserEmail(otherUid), // Fetch the email
                builder: (context, emailSnapshot) {
                  final displayName = emailSnapshot.hasData ? emailSnapshot.data! : 'Loading...';

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(displayName),
                    subtitle: Text(d['lastText'] ?? 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      if (emailSnapshot.connectionState == ConnectionState.done) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chatId,
                              otherUid: otherUid,
                              otherUserEmail: displayName,
                            ),
                          ),
                        );
                      }
                    },
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
