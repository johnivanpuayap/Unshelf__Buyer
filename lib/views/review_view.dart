/// ReviewPage — form to leave a store review after an order.
///
/// Layout:
///   • AppBar: back + "Leave a review".
///   • Heading: "How was your experience?" (headlineSmall).
///   • Brief instruction subtitle.
///   • StarRatingPicker (interactive 5-star picker).
///   • Multiline TextFormField for review body (max 150 chars).
///   • Full-width 52px "Submit review" button.
///
/// Existing logic (Firestore write, rating recalculation) is preserved
/// unchanged; only the visual layer is redesigned.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/star_rating_picker.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.orderId,
    required this.storeId,
    required this.orderDocId,
  });

  final String orderId;
  final String storeId;
  final String orderDocId;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged from original) ──────────────────────────────────────

  Future<double> _getStoreRating() async {
    final snap = await FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('reviews')
        .get();

    if (snap.docs.isEmpty) return 0.0;

    int total = 0;
    for (final doc in snap.docs) {
      total += (doc['rating'] as num).toInt();
    }
    return double.parse(
        (total / snap.docs.length).toStringAsFixed(2));
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final reviewData = {
        'orderId': widget.orderId,
        'buyerId': FirebaseAuth.instance.currentUser!.uid,
        'storeId': widget.storeId,
        'rating': _rating,
        'description': _descriptionController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderDocId)
          .update({'isReviewed': true});

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('reviews')
          .doc(widget.orderDocId)
          .set(reviewData);

      final newRating = await _getStoreRating();
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .update({'rating': newRating});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted — thank you!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Leave a review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Heading
                Text(
                  'How was your experience?',
                  style: tt.headlineSmall?.copyWith(color: cs.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Tap the stars and share a few words to help other buyers.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Star picker
                StarRatingPicker(
                  value: _rating,
                  onChanged: (r) => setState(() => _rating = r),
                  starSize: 48,
                ),
                const SizedBox(height: 8),

                // Star label
                Text(
                  _ratingLabel(_rating),
                  style: tt.labelMedium?.copyWith(
                    color: _rating > 0
                        ? cs.tertiary
                        : cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 32),

                // Text area
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Write a short review (optional)',
                    alignLabelWithHint: true,
                  ),
                  validator: (_) => null, // optional field
                ),
                const SizedBox(height: 32),

                // Submit CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(
                            'Submit review',
                            style: tt.labelLarge
                                ?.copyWith(color: cs.onPrimary),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }
}
