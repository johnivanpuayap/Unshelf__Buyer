/// ReportFormView — form to submit a report (product or general).
///
/// Layout:
///   • AppBar: back + "Report".
///   • Scrollable body:
///       - SectionCard header showing what's being reported (optional subject).
///       - Chip-based reason selector (Spam / Misleading / Inappropriate / Other).
///       - Multi-line "Tell us more" TextField (optional).
///   • Bottom: pinned 52-px pill "Submit report" CTA with loading state.
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/components/section_card.dart';
import 'package:unshelf_buyer/models/report_model.dart';

class ReportFormView extends StatefulWidget {
  /// Optional context for what is being reported (e.g. product/store name).
  final String? subjectLabel;
  final String? subjectImageUrl;

  const ReportFormView({
    super.key,
    this.subjectLabel,
    this.subjectImageUrl,
  });

  @override
  _ReportFormViewState createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<ReportFormView> {
  static const List<String> _reasons = [
    'Spam',
    'Misleading',
    'Inappropriate',
    'Other',
  ];

  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final report = ReportModel(
        userId: user.uid,
        title: _selectedReason!,
        message: _detailsController.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('reports')
          .add(report.toJson());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report',
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: cs.secondary, height: 4),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subject card (optional) ────────────────────────────
                  if (widget.subjectLabel != null) ...[
                    SectionCard(
                      child: Row(
                        children: [
                          if (widget.subjectImageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.subjectImageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (widget.subjectImageUrl != null)
                            const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reporting',
                                  style: tt.labelSmall?.copyWith(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subjectLabel!,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Reason ─────────────────────────────────────────────
                  Text('Reason for report', style: tt.titleSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasons.map((reason) {
                      final selected = _selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedReason = reason),
                        selectedColor: cs.primary,
                        backgroundColor: cs.surfaceContainerHighest,
                        labelStyle: tt.labelLarge?.copyWith(
                          color: selected ? cs.onPrimary : cs.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected
                                ? cs.primary
                                : cs.outlineVariant,
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Details ────────────────────────────────────────────
                  Text('Tell us more', style: tt.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Optional — give us a bit more context.',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detailsController,
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    style: tt.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue…',
                      hintStyle: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),

                  // Bottom padding so content isn't obscured by the pinned CTA.
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Pinned Submit CTA ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border:
                  Border(top: BorderSide(color: cs.outlineVariant, width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  disabledBackgroundColor:
                      cs.primary.withValues(alpha: 0.5),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.onPrimary,
                        ),
                      )
                    : Text('Submit report', style: tt.labelLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
