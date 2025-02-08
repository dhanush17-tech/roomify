import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:roomify_app/firebase_options.dart';
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
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'views/onboarding/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_links/app_links.dart';
import 'package:roomify_app/views/auth/reset_password.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      handleNotificationTap(response.payload, navigatorKey);
    },
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    if (message.notification != null) {
      showNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationTap(message.data.toString(), navigatorKey);
  });

  MapboxOptions.setAccessToken(mapboxToken);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final position = await getCurrentLocation();

  // Initialize AppLinks
  final appLinks = AppLinks();

  // Handle app links while the app is in the foreground
  appLinks.uriLinkStream.listen((uri) {
    print('Received URI: $uri');
    handleDeepLink(uri, navigatorKey);
  });

  // Get the initial link if the app was launched from a link
  final appLink = await appLinks.getInitialLink();
  if (appLink != null) {
    handleDeepLink(appLink, navigatorKey);
  }

  runApp(MyApp(
      navigatorKey: navigatorKey,
      latitude: position.lat.toDouble(),
      longitude: position.lng.toDouble()));
}

Future<Position> getCurrentLocation() async {
  bool serviceEnabled;
  geo.LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
    if (permission == geo.LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Position(0, 0);
    }
  }

  if (permission == geo.LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
  final location = await geo.Geolocator.getCurrentPosition();
  return Position(location.longitude, location.latitude);
}

void showNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }
}

Future<void> handleNotificationTap(
    String? payload, GlobalKey<NavigatorState> navigatorKey) async {
  if (payload != null) {
    try {
      final fixedPayload = payload
          .replaceAllMapped(
            RegExp(r'(\w+):'), // Match keys
            (match) => '"${match[1]}":', // Enclose keys in double quotes
          )
          .replaceAllMapped(
            RegExp(r':\s?([^",{}]+)'), // Match values not enclosed in quotes
            (match) => match[1]!.startsWith('"')
                ? ': ${match[1]}' // Value already quoted, keep it as is
                : ': "${match[1]}"', // Enclose unquoted values in double quotes
          )
          .replaceAllMapped(
              RegExp(r'"""'), // Remove excessive triple quotes
              (_) => '"');

      final data = Map<String, dynamic>.from(
        json.decode(fixedPayload),
      );

      if (data['type'] == 'chat' && data['roomId'] != null) {
        final chatProvider = navigatorKey.currentContext?.read<ChatProvider>();
        if (chatProvider != null) {
          final chatRoom = await chatProvider.createOrGetChatRoom(
            data['senderId'],
          );
          if (chatRoom != null) {
            Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => ChatMessageScreen(room: chatRoom),
                settings: RouteSettings(
                  name: 'ChatMessageScreen',
                  arguments: ChatMessageScreen(room: chatRoom),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }
}

// Update handleDeepLink function to handle both https and roomify schemes
void handleDeepLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
  // Extract the path and query parameters regardless of scheme
  final pathSegments = uri.pathSegments;

  // Handle reset password
  if (uri.authority == "reset-password") {
    final token = uri.queryParameters['token'];
    if (token != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              token,
              0.0, // Default latitude
              0.0, // Default longitude
            ),
          ),
          (route) => false);
      return;
    }
  }

  // Handle property details
  if (pathSegments.length >= 2 && pathSegments[0] == 'property') {
    final propertyId = pathSegments[1];
    // Load property details and navigate
    print('Property ID: $propertyId');
    final propertiesProvider =
        navigatorKey.currentContext?.read<PropertyProvider>();
    if (propertiesProvider != null) {
      propertiesProvider.getPropertyById(propertyId).then((listing) {
        if (listing != null) {
          navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => PropertyDetailsScreen(
                  listing,
                  0.0,
                  0.0,
                ),
              ),
              (route) => false);
        }
      });
    }
  }
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final double latitude;
  final double longitude;

  const MyApp(
      {super.key,
      required this.navigatorKey,
      required this.latitude,
      required this.longitude});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          // Base repositories first
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
          Provider<SearchRepository>(
            create: (_) => SearchRepository(),
          ),
          Provider<RoommateMatchRepository>(
            create: (_) => RoommateMatchRepository(),
          ),
          Provider<ChatRepository>(
            create: (_) => ChatRepository(),
          ),

          // Then providers that depend on repositories
          ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
            create: (context) => AuthProvider(
              context.read<AuthRepository>(),
            ),
            update: (context, authRepo, previous) =>
                previous ?? AuthProvider(authRepo),
          ),
          ChangeNotifierProxyProvider2<SearchRepository, AuthRepository,
              SearchProvider>(
            create: (context) => SearchProvider(
              context.read<SearchRepository>(),
              context,
            ),
            update: (context, searchRepo, authRepo, previous) =>
                previous ?? SearchProvider(searchRepo, context),
          ),
          ChangeNotifierProxyProvider2<ProfileUpdateRepo, AuthRepository,
              ProfileProvider>(
            create: (context) => ProfileProvider(
              context.read<ProfileUpdateRepo>(),
              context,
            ),
            update: (context, profileRepo, authRepo, previous) =>
                previous ?? ProfileProvider(profileRepo, context),
          ),
          ChangeNotifierProxyProvider2<PropertyRepository, AuthRepository,
              PropertyProvider>(
            create: (context) => PropertyProvider(
              context.read<PropertyRepository>(),
              context,
            ),
            update: (context, propRepo, authRepo, previous) =>
                previous ?? PropertyProvider(propRepo, context),
          ),
          ChangeNotifierProxyProvider2<MarketplaceRepository, AuthRepository,
              MarketplaceProvider>(
            create: (context) => MarketplaceProvider(
              context.read<MarketplaceRepository>(),
              context,
            ),
            update: (context, marketRepo, authRepo, previous) =>
                previous ?? MarketplaceProvider(marketRepo, context),
          ),
          ChangeNotifierProxyProvider<RoommateMatchRepository,
              RoommateMatchProvider>(
            create: (context) => RoommateMatchProvider(
              context.read<RoommateMatchRepository>(),
            ),
            update: (context, repository, previous) =>
                previous ?? RoommateMatchProvider(repository),
          ),
          ChangeNotifierProxyProvider2<ChatRepository, AuthProvider,
              ChatProvider>(
            create: (context) => ChatProvider(
              context.read<ChatRepository>(),
              context.read<AuthProvider>(),
            ),
            update: (context, chatRepo, authProvider, previous) =>
                previous ??
                ChatProvider(
                  chatRepo,
                  authProvider,
                ),
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            navigatorKey: navigatorKey,
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
            home: Material(
              color: Color(4294375672),
              child: SplashScreen(
                latitude: latitude,
                longitude: longitude,
              ),
            ),
          ),
        ));
  }
}
