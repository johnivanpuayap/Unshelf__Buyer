import 'package:unshelf_buyer/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewPage extends StatefulWidget {
  final String orderId;
  final String storeId;
  final String orderDocId;

  const ReviewPage({
    Key? key,
    required this.orderId,
    required this.storeId,
    required this.orderDocId,
  }) : super(key: key);

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final ValueNotifier<int> _rating = ValueNotifier<int>(0);

  Future<double> getStoreRating() async {
    // Fetch all reviews for the store
    QuerySnapshot reviewSnapshot =
        await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).collection('reviews').get();

    // Check if there are any reviews
    if (reviewSnapshot.docs.isEmpty) {
      return 0.0; // Return 0.0 if there are no reviews
    }

    // Calculate the sum of all ratings
    int totalRating = 0;
    for (var doc in reviewSnapshot.docs) {
      totalRating += doc['rating'] as int; // Assuming the rating field is an int
    }

    // Calculate the average rating
    double averageRating = totalRating / reviewSnapshot.docs.length;

    // Round the result to 2 decimal places
    return double.parse(averageRating.toStringAsFixed(2));
  }

  Future<void> submitReview() async {
    final reviewData = {
      'orderId': widget.orderId,
      'buyerId': FirebaseAuth.instance.currentUser!.uid,
      'storeId': widget.storeId,
      'rating': _rating.value,
      'description': _descriptionController.text,
    };

    // Mark the order as reviewed
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderDocId).update({'isReviewed': true});

    // Save the review to Firestore
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('reviews')
        .doc(widget.orderDocId)
        .set(reviewData);

    // Calculate the new store rating
    double newRating = await getStoreRating();

    // Update the store's rating in the store document
    await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).update({'rating': newRating});

    // Show a success message and pop the screen
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review submitted successfully')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Leave a Review",
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Rate the Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => _rating.value = index + 1,
                  icon: ValueListenableBuilder<int>(
                    valueListenable: _rating,
                    builder: (context, value, _) => Icon(
                      Icons.star,
                      color: value > index ? Colors.amber : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Write a short review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitReview,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
