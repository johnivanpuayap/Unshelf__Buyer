import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_buyer/theme/unshelf_theme.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Stripe is only used for payments — leaving the publishable key empty
  // on web is fine for login + browsing flows.
  if (!kIsWeb) {
    Stripe.publishableKey = dotenv.env['stripePublishableKey'] ?? '';
  }

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: kIsWeb
          ? dotenv.env['FIREBASE_WEB_API_KEY']!
          : dotenv.env['FIREBASE_API_KEY']!,
      appId: kIsWeb
          ? dotenv.env['FIREBASE_WEB_APP_ID']!
          : dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    ),
  );

  UnshelfTheme.preloadFonts();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unshelf',
      theme: UnshelfTheme.light(),
      darkTheme: UnshelfTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser != null
          ? HomeView()
          : const LoginView(),
    );
  }
}
