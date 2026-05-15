import 'package:unshelf_buyer/utils/colors.dart';
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
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');

    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          toolbarHeight: 65,
          title: const Text(
            "Notifications",
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: AppColors.lightColor,
              height: 6.0,
            ),
          ),
        ),
        body: const Center(
          child: Text("You have no notifications."),
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3));
  }
}
