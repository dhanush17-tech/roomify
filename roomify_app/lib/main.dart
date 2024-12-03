import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/roommateMatch_provider.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/repository/chat_repo.dart';
import 'package:roomify_app/repository/marketplace_repo.dart';
import 'package:roomify_app/repository/profile_repo.dart';
import 'package:roomify_app/repository/properties_repo.dart';
import 'package:roomify_app/repository/rommate_match_repo.dart';
import 'package:roomify_app/repository/search_repo.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/views/auth/forgot_passoword.dart';
import 'views/onboarding/splash_screen.dart';

void main() async {
  runApp(MyApp());
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
          Provider<ProfileUpdateRepo>(
            create: (_) => ProfileUpdateRepo(),
          ),

          // Then, provide UserProvider since others depend on it
          ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
            create: (context) =>
                AuthProvider(context.read<AuthRepository>(), context),
            update: (context, authRepository, previous) =>
                previous ?? AuthProvider(authRepository, context),
          ),

          // Now EditProfileProvider can access UserProvider
          ChangeNotifierProxyProvider<ProfileUpdateRepo, ProfileProvider>(
            create: (context) =>
                ProfileProvider(context.read<ProfileUpdateRepo>(), context),
            update: (context, repo, previous) => ProfileProvider(repo, context),
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
            create: (context) =>
                SearchProvider(context.read<SearchRepository>(), context),
            update: (context, repository, previous) =>
                previous ?? SearchProvider(repository, context),
          ),
          Provider<PropertyRepository>(
            create: (_) => PropertyRepository(),
          ),
          ChangeNotifierProxyProvider<PropertyRepository, PropertyProvider>(
            create: (context) => PropertyProvider(
              context.read<PropertyRepository>(),
              context,
            ),
            update: (context, repository, previous) =>
                PropertyProvider(repository, context),
          ),
          Provider<ChatRepository>(
            create: (_) => ChatRepository(),
          ),
          ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
            create: (context) => ChatProvider(
              context.read<ChatRepository>(),
            ),
            update: (context, repository, previous) =>
                previous ?? ChatProvider(repository),
          ),

          Provider<MarketplaceRepository>(
            create: (_) => MarketplaceRepository(),
          ),
          ChangeNotifierProxyProvider<MarketplaceRepository,
              MarketplaceProvider>(
            create: (context) => MarketplaceProvider(
              context.read<MarketplaceRepository>(),
              context,
            ),
            update: (context, repository, previous) =>
                MarketplaceProvider(repository, context),
          ),
        ],
        child: MaterialApp(
          // onGenerateRoute: (settings) {
          //   if (settings.name?.startsWith('/reset-password') ?? false) {
          //     // Extract token from URL
          //     final uri = Uri.parse(settings.name!);
          //     final token = uri.queryParameters['token'];

          //     if (token != null) {
          //       return MaterialPageRoute(
          //         builder: (context) => ResetPasswordScreen(token: token),
          //       );
          //     }
          //   }
          // },
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: orangeColor,
            ).copyWith(
              secondary: Colors.orange,
              primary: Colors.orange.withOpacity(0.5),
            ),
            textTheme: GoogleFonts.rubikTextTheme(),
          ),
          debugShowCheckedModeBanner: false,
          home: Material(color: Color(4294375672), child: SplashScreen()),
        ));
  }
}
