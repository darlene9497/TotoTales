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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AgeProvider()),
      ],
      child: TotoTalesApp(),
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
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Auth wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        } else if (snapshot.hasData) {
          // User is logged in, initialize age provider
          return Consumer<AgeProvider>(
            builder: (context, ageProvider, child) {
              if (ageProvider.isLoading) {
                // Initialize age range on first load
                ageProvider.initializeAgeRange();
                return SplashScreen();
              }
              
              return HomeScreen(
                registeredAgeRange: ageProvider.childAgeRange,
              );
            },
          );
        } else {
          // User is not logged in, show login screen
          return LoginScreen();
        }
      },
    );
  }
}

// Updated splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo here
            Icon(
              Icons.book,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading TotoTales...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example of how to use the age provider in other screens
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