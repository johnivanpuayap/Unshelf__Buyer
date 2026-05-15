import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unshelf_buyer/components/field_label.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  User? _user;
  String? _profileImageUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _saving = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? data['phone_number'] ?? '';
        _profileImageUrl = data['profileImageUrl'];
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String> _uploadImage(File image) async {
    final ref = _storage.ref().child('user_avatars/${_user!.uid}.png');
    final task = await ref.putFile(image);
    return task.ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    try {
      // Upload avatar if changed
      String? imageUrl = _profileImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      // Update password if provided
      final newPassword = _passwordController.text.trim();
      if (newPassword.isNotEmpty) {
        await _user!.updatePassword(newPassword);
      }

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        if (imageUrl != null) 'profileImageUrl': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save changes: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Edit profile', style: tt.titleLarge),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
                  // ── Avatar editor ───────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: cs.outline.withValues(alpha: 0.15),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : (_profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(_profileImageUrl!)
                                    : null,
                            child: (_imageFile == null &&
                                    (_profileImageUrl == null ||
                                        _profileImageUrl!.isEmpty))
                                ? Icon(Icons.person_outline,
                                    size: 44,
                                    color: cs.onSurface.withValues(alpha: 0.4))
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cs.surface, width: 2),
                              ),
                              child: Icon(Icons.edit,
                                  size: 16, color: cs.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Name ─────────────────────────────────────────────
                  FieldLabel('Name', color: cs.onSurface),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'Your name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Email (read-only) ────────────────────────────────
                  FieldLabel('Email', color: cs.onSurface),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Phone ────────────────────────────────────────────
                  FieldLabel('Phone number', color: cs.onSurface),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: '09XX XXX XXXX'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // optional
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 11) return 'Must be at least 11 digits';
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // ── Change password (optional) ───────────────────────
                  Text(
                    'Change password',
                    style: tt.titleSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leave blank to keep your current password.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FieldLabel('New password', color: cs.onSurface),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                        onPressed: () =>
                            setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  FieldLabel('Confirm new password', color: cs.onSurface),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_confirmVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: 'Type it again',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                        onPressed: () =>
                            setState(() => _confirmVisible = !_confirmVisible),
                      ),
                    ),
                    validator: (v) {
                      final pw = _passwordController.text;
                      if (pw.isEmpty) return null;
                      if (v != pw) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),

      // ── Save CTA ─────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: cs.onPrimary))
                  : Text('Save changes',
                      style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
