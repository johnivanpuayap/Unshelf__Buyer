import 'package:unshelf_buyer/utils/colors.dart';
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
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store Image
                Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: data['store_image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 30),

                // Store Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['store_name'], // Store Name
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ), // Heart button (Remove from following)
                IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.primaryColor),
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
        const SizedBox(
          height: 15,
        ),
        // Divider between store cards
        Divider(
          thickness: 0.2,
          height: 1,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final followingRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('following');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Following",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: AppColors.lightColor,
              height: 6.0,
            )),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: followingRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You aren't following any stores."));
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
