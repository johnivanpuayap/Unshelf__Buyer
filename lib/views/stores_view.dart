import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

class StoresView extends StatelessWidget {
  const StoresView({super.key});

  Widget _buildStoreCard(Map<String, dynamic> data, String storeId, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StoreView(storeId: storeId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store Image
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        offset: const Offset(0, 1),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0xFF1F2A20).withValues(alpha: 0.06),
                        offset: const Offset(0, 8),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: data['store_image_url'] ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Store Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['store_name'] ?? '', // Store Name
                        style: tt.titleSmall?.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Divider between store cards
        Divider(
          thickness: 0.5,
          height: 1,
          color: cs.outline.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final storesRef = FirebaseFirestore.instance.collection('stores');

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                    return MapPage();
                  },
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              );
            },
            icon: Icon(Icons.place, color: cs.secondary),
            label: Text("Near Me", style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
          ),
          const SizedBox(width: 8)
        ],
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "Stores",
          style: tt.headlineSmall?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: cs.primary.withValues(alpha: 0.6),
            height: 4.0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: storesRef.snapshots(),
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
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
