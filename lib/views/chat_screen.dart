import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/chat_view.dart';
import 'package:unshelf_buyer/views/basket_view.dart';

import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "Chat",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: cs.surface,
              child: Icon(
                Icons.shopping_basket,
                color: cs.primary,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BasketView(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: cs.secondary, height: 4.0),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').orderBy('store_name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }

          if (snapshot.hasData) {
            return ListView.separated(
              separatorBuilder: (BuildContext context, int index) {
                return Divider(height: 1, color: cs.outline);
              },
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data = snapshot.data!.docs[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatView(
                          receiverName: data['store_name'],
                          receiverUserID: data.id,
                        ),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: CachedNetworkImageProvider(data['store_image_url']),
                  ),
                  title: Text(data['store_name'], style: tt.bodyLarge),
                );
              },
            );
          } else {
            return const Text('Ongoing');
          }
        },
      ),
    );
  }
}
