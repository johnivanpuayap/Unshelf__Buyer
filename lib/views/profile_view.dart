import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';
import 'package:unshelf_buyer/components/section_card.dart';
import 'package:unshelf_buyer/components/settings_tile.dart';
import 'package:unshelf_buyer/viewmodels/user_profile_viewmodel.dart';
import 'package:unshelf_buyer/views/edit_profile_view.dart';
import 'package:unshelf_buyer/views/notifications_view.dart';
import 'package:unshelf_buyer/views/order_history_view.dart';
import 'package:unshelf_buyer/views/profile_favorites_view.dart';
import 'package:unshelf_buyer/views/profile_following_view.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileViewModelProvider.notifier).loadUserProfile();
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final profileState = ref.watch(userProfileViewModelProvider);
    final profile = profileState.userProfile;

    // Use Firebase current user for avatar (not in viewmodel yet)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final avatarUrl = firebaseUser?.photoURL;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('My profile', style: tt.titleLarge),
        centerTitle: false,
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // ── Header card ──────────────────────────────────────────
                SectionCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: cs.outline.withValues(alpha: 0.15),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Icon(Icons.person_outline,
                                size: 36, color: cs.onSurface.withValues(alpha: 0.4))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Name + email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name ?? firebaseUser?.displayName ?? 'Your name',
                              style: tt.headlineSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email ?? firebaseUser?.email ?? '',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const EditProfileView()),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Edit profile',
                                  style: tt.labelMedium?.copyWith(color: cs.primary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Activity section ──────────────────────────────────────
                const _SectionHeading('Activity'),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Orders',
                        subtitle: 'View your order history',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OrderHistoryView()),
                        ),
                      ),
                      _divider(cs),
                      SettingsTile(
                        icon: Icons.favorite_outline,
                        title: 'Favorites',
                        subtitle: 'Products you have saved',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesView()),
                        ),
                      ),
                      _divider(cs),
                      SettingsTile(
                        icon: Icons.storefront_outlined,
                        title: 'Following',
                        subtitle: 'Stores you follow',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FollowingView()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Preferences section ───────────────────────────────────
                const _SectionHeading('Preferences'),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'Saved addresses',
                        onTap: () {
                          // TODO: navigate to address list when implemented
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Saved addresses — coming soon')),
                          );
                        },
                      ),
                      _divider(cs),
                      SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsView()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Support section ───────────────────────────────────────
                const _SectionHeading('Support'),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & support',
                        onTap: () {
                          // TODO: route to help centre
                        },
                      ),
                      _divider(cs),
                      SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About Unshelf',
                        onTap: () {
                          // TODO: about page
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sign out ──────────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: _signOut,
                    icon: Icon(Icons.logout, size: 18, color: cs.error),
                    label: Text(
                      'Sign out',
                      style: tt.labelLarge?.copyWith(color: cs.error),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4),
    );
  }

  Widget _divider(ColorScheme cs) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 56,
        color: cs.outline.withValues(alpha: 0.25),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: tt.labelMedium?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.55),
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
