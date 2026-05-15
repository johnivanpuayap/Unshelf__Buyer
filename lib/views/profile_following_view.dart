import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/store_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowingView extends StatelessWidget {
  const FollowingView({super.key});

  Future<void> _removeFromFollowing(String storeId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final followingRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('following').doc(storeId);

    await followingRef.delete();
  }

  Widget _buildStoreCard(Map<String, dynamic> data, String storeId, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                  return StoreView(storeId: storeId);
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: data['store_image_url'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['store_name'],
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: cs.primary),
                  onPressed: () {
                    _removeFromFollowing(storeId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Successfully removed from following list.'),
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 0.5, color: cs.outline),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final followingRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('following');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "Following",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: cs.secondary, height: 4.0),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: followingRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "You aren't following any stores.",
                style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final followingDoc = snapshot.data!.docs[index];
              final storeId = followingDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
                builder: (context, storeSnapshot) {
                  if (storeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final storeData = storeSnapshot.data!;
                  return _buildStoreCard(storeData.data() as Map<String, dynamic>, storeId, context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
