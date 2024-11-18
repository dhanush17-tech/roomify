import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roomify_app/providers/roommateMatch_provider.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/repository/rommate_match_repo.dart';
import 'package:roomify_app/repository/search_repo.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/views/auth/forgot_passoword.dart';
import 'views/onboarding/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          Provider<AuthRepository>(
            create: (_) => AuthRepository(),
          ),
          ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
            create: (context) => AuthViewModel(
              context.read<AuthRepository>(),
            ),
            update: (context, authRepository, previous) =>
                previous ?? AuthViewModel(authRepository),
          ),

          // Roommate Match Provider
          Provider<RoommateMatchRepository>(
            create: (_) => RoommateMatchRepository(),
          ),
          ChangeNotifierProxyProvider<RoommateMatchRepository,
              RoommateMatchProvider>(
            create: (context) => RoommateMatchProvider(
              context.read<RoommateMatchRepository>(),
            ),
            update: (context, repository, previous) =>
                previous ?? RoommateMatchProvider(repository),
          ),

          // Search Provider
          Provider<SearchRepository>(
            create: (_) => SearchRepository(),
          ),
          ChangeNotifierProxyProvider<SearchRepository, SearchProvider>(
            create: (context) => SearchProvider(
              context.read<SearchRepository>(),
            ),
            update: (context, repository, previous) =>
                previous ?? SearchProvider(repository),
          ),
        ],
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/reset-password') ?? false) {
              // Extract token from URL
              final uri = Uri.parse(settings.name!);
              final token = uri.queryParameters['token'];

              if (token != null) {
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(token: token),
                );
              }
            }
          },
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: orangeColor),
            textTheme: GoogleFonts.rubikTextTheme(),
          ),
          debugShowCheckedModeBanner: false,
          home: Material(color: Color(4294375672), child: SplashScreen()),
        ));
  }
}
