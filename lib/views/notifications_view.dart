import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({Key? key}) : super(key: key);

  Future<void> _removeFromFavorites(String productId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoriteRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(productId);

    await favoriteRef.delete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: cs.primary,
          elevation: 0,
          toolbarHeight: 65,
          title: Text(
            "Notifications",
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
        body: Center(
          child: Text(
            "You have no notifications.",
            style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3));
  }
}
