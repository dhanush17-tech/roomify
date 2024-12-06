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
  WidgetsFlutterBinding.ensureInitialized();
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
          Provider<PropertyRepository>(
            create: (_) => PropertyRepository(),
          ),
          Provider<MarketplaceRepository>(
            create: (_) => MarketplaceRepository(),
          ),
          Provider<ProfileUpdateRepo>(
            create: (_) => ProfileUpdateRepo(),
          ),
          ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
            create: (context) => AuthProvider(context.read<AuthRepository>()),
            update: (context, authRepo, previous) =>
                previous ?? AuthProvider(authRepo),
          ),
          ChangeNotifierProxyProvider2<AuthRepository, ProfileUpdateRepo,
              ProfileProvider>(
            create: (context) => ProfileProvider(
              context.read<ProfileUpdateRepo>(),
              context,
            ),
            update: (context, authRepo, profileRepo, previous) =>
                previous ?? ProfileProvider(profileRepo, context),
          ),
          ChangeNotifierProxyProvider2<AuthRepository, PropertyRepository,
              PropertyProvider>(
            create: (context) => PropertyProvider(
              context.read<PropertyRepository>(),
              context,
            ),
            update: (context, authRepo, propRepo, previous) =>
                previous ?? PropertyProvider(propRepo, context),
          ),
          ChangeNotifierProxyProvider2<AuthRepository, MarketplaceRepository,
              MarketplaceProvider>(
            create: (context) => MarketplaceProvider(
              context.read<MarketplaceRepository>(),
              context,
            ),
            update: (context, authRepo, marketRepo, previous) =>
                previous ?? MarketplaceProvider(marketRepo, context),
          ),
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
          Provider<SearchRepository>(
            create: (_) => SearchRepository(),
          ),
          ChangeNotifierProxyProvider<SearchRepository, SearchProvider>(
            create: (context) =>
                SearchProvider(context.read<SearchRepository>(), context),
            update: (context, repository, previous) =>
                previous ?? SearchProvider(repository, context),
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
              primary: Colors.orange,
            ),
            textTheme: GoogleFonts.rubikTextTheme(),
          ),
          debugShowCheckedModeBanner: false,
          home: Material(color: Color(4294375672), child: SplashScreen()),
        ));
  }
}
