import 'package:unshelf_buyer/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/viewmodels/order_viewmodel.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load env
  await dotenv.load(fileName: ".env");

  // assign publishable key to flutter_stripe
  Stripe.publishableKey = dotenv.env['stripePublishableKey'] ?? '';

  // initialize firebase app
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: "1:733152787617:android:3c3e7b87d0cb7c59f544e0",
      messagingSenderId: "733152787617",
      projectId: "unshelf-d4567",
      storageBucket: "unshelf-d4567.appspot.com",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreViewModel("2gxma4nHjhcHsOgDDDarlyeEvy12")), //
        ChangeNotifierProvider(create: (_) => OrderViewModel()), // OrderViewModel Provider
        // Add more providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unshelf',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(iconTheme: IconThemeData(color: Colors.white)),
        bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white, shadowColor: Colors.grey, elevation: 20),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: Colors.grey,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        useMaterial3: true,
        textTheme: GoogleFonts.jostTextTheme(Theme.of(context).textTheme)
            .apply(displayColor: AppColors.primaryColor, bodyColor: Colors.black),
      ),
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser != null ? HomeView() : LoginView(),
    );
  }
}
