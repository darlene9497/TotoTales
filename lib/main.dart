import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:toto_tales/screens/affirmation_screen.dart';
import 'package:toto_tales/screens/home_screen.dart';
import 'package:toto_tales/screens/login_screen.dart';
import 'package:toto_tales/screens/story_library_screen.dart';
import 'providers/age_provider.dart';
import 'services/firebase_service.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AgeProvider()),
        ],
        child: const TotoTalesApp(),
      ),
    ),
  );
}

class TotoTalesApp extends StatelessWidget {
  const TotoTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TotoTales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// SplashScreen with 5-second delay
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthWrapperDelayed()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/splash.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // Foreground content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading TotoTales...',
                  style: TextStyle(
                    fontFamily: 'ComicSans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Handles auth state AFTER splash delay
class AuthWrapperDelayed extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapperDelayed({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return Consumer<AgeProvider>(
            builder: (context, ageProvider, child) {
              if (ageProvider.isLoading) {
                ageProvider.initializeAgeRange();
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return HomeScreen(
                registeredAgeRange: ageProvider.childAgeRange,
              );
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// Navigation helper
class NavigationHelper {
  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Consumer<AgeProvider>(
          builder: (context, ageProvider, child) {
            return HomeScreen(
              registeredAgeRange: ageProvider.childAgeRange,
            );
          },
        ),
      ),
    );
  }

  static void navigateToStoryLibrary(BuildContext context) {
    final ageProvider = Provider.of<AgeProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryLibraryScreen(
          selectedAgeRange: ageProvider.childAgeRange ?? '3-5',
        ),
      ),
    );
  }

  static void navigateToAffirmations(BuildContext context) {
    final ageProvider = Provider.of<AgeProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AffirmationScreen(
          selectedAgeRange: ageProvider.getAgeRangeDisplay(),
        ),
      ),
    );
  }
}
