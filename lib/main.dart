import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_colors.dart';
import 'core/routing/app_router.dart';
import 'core/di/injection.dart';
import 'core/services/user_profile_service.dart';
import 'core/services/firebase_auth_service.dart';

final appRouter = AppRouter();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Enable edge-to-edge to remove status bar shadow
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // Set default transparent status bar - each page will set its own color
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  setupDependencies();
  runApp(const LearningApp());
}

class LearningApp extends StatefulWidget {
  const LearningApp({super.key});

  @override
  State<LearningApp> createState() => _LearningAppState();
}

class _LearningAppState extends State<LearningApp> {
  final UserProfileService _profileService = getIt<UserProfileService>();
  final FirebaseAuthService _firebaseAuth = getIt<FirebaseAuthService>();
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _firebaseAuth.isLoggedIn(),
      builder: (context, snapshot) {
        // Show loading while checking auth status
        if (!snapshot.hasData) {
          return MaterialApp(
            title: 'Readify',
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        
        // Navigate to appropriate screen based on login status (only once)
        if (!_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isLoggedIn) {
              // User is logged in, navigate to main page
              appRouter.replaceAll([const MainRoute()]);
            } else {
              // User is not logged in, navigate to onboarding
              appRouter.replaceAll([const OnboardingRoute()]);
            }
          });
        }

        return MaterialApp.router(
          title: 'Readify',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            primarySwatch: Colors.blue,
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            fontFamily: GoogleFonts.poppins().fontFamily,
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              elevation: 0,
            ),
          ),
          routerDelegate: appRouter.delegate(),
          routeInformationParser: appRouter.defaultRouteParser(),
        );
      },
    );
  }
}
