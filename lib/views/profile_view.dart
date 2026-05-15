import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/views/edit_profile_view.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';
import 'package:unshelf_buyer/views/order_tracking_view.dart';
import 'package:unshelf_buyer/views/profile_favorites_view.dart';
import 'package:unshelf_buyer/views/profile_following_view.dart';
import 'package:unshelf_buyer/views/report_view.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Page',
      home: ProfileView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfileView extends StatelessWidget {
  Future<Map<String, dynamic>> getUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    String name = userDoc['name'];

    return {'name': name, 'profileImageUrl': userDoc['profileImageUrl'], 'points': userDoc['points'].toString()};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<Map<String, dynamic>>(
          future: getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Error loading profile data"));
            }

            final userData = snapshot.data!;
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: CachedNetworkImageProvider(userData['profileImageUrl']),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'],
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 211, 255, 244),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 20,
                                      color: Colors.yellow,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "POINTS: ${userData['points']}",
                                      style: const TextStyle(color: Color(0xFF0AB68B), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          const Divider(),
                          const Text(
                            "General",
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          _buildProfileOption(context, Icons.list_alt, "Edit Profile", 1),
                          const Divider(),
                          _buildProfileOption(context, Icons.track_changes, "Orders", 2),
                          const Divider(),
                          _buildProfileOption(context, Icons.favorite, "Favorites", 3),
                          const Divider(),
                          _buildProfileOption(context, Icons.store, "Following", 4),
                          const Divider(),

                          const Text(
                            "Account & Security",
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          _buildProfileOption(context, Icons.report_problem, "Report", 5),
                          const Divider(),
                          // const Divider(),
                          // _buildProfileOption(context, Icons.history, "Order History", 5),
                          // _buildProfileOption(context, Icons.subscriptions, "Subscriptions", 6),
                          // _buildProfileOption(context, Icons.share, "Referrals", 7),
                          // _buildProfileOption(context, Icons.card_giftcard, "Vouchers", 8),
                          // const Divider(),
                          // _buildProfileOption(context, Icons.help, "Help Center", 9),
                          // _buildProfileOption(context, Icons.settings, "Settings", 10),
                          // _buildProfileOption(context, Icons.support, "Customer Support", 11),
                          _buildProfileOption(context, Icons.logout, "Log Out", 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4));
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, num index) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0AB68B)),
      title: Text(title),
      onTap: () {
        switch (index) {
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileView(),
                fullscreenDialog: true,
              ),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderTrackingView(),
                fullscreenDialog: true,
              ),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritesView(),
                fullscreenDialog: true,
              ),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FollowingView(),
                fullscreenDialog: true,
              ),
            );
            break;
          case 5:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportFormView(),
                fullscreenDialog: true,
              ),
            );
            break;
          case 6:
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginView(),
                fullscreenDialog: true,
              ),
            );
            break;
          default:
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeView()));
            break;
        }
      },
    );
  }
}
