import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zineapp2023/background/notification_handle.dart';
import './screens/onboarding/splash/splash.dart';
import './app_providers.dart';
import './common/data_store.dart';
import './providers/dictionary.dart';
import './providers/user_info.dart';
import './common/navigator.dart';

import 'background/firebase_options.dart';
import 'database/database.dart';
//////////
import 'dart:io';
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

//////////
final Language _language = Language();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
//manages background stuffs
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _language.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // REPLACED: Old flutter_notification_channel code with flutter_local_notifications
  await initializeNotifications();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  AppDb db = AppDb();
  await db.initializeIsSyncedColumn();
  setupForegroundMessageListener();

  DataStore store = DefaultStore();
  UserProv userProv = UserProv(dataStore: store, Db: db);
  FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  HttpOverrides.global = MyHttpOverrides();

  runApp(MyApp(store: store, userProv: userProv, secureStorage: secureStorage, db: db));
}

Future<void> initializeNotifications() async {
  // Android initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/launcher_icon');

  // iOS initialization settings
  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create the 'chats' notification channel (equivalent to your old setup)
  const AndroidNotificationChannel chatsChannel = AndroidNotificationChannel(
    'chats', // id
    'Chats', // name
    description: 'For Showing Message Notification',
    importance: Importance.high, // equivalent to IMPORTANCE_HIGH
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(chatsChannel);
}

class MyApp extends StatelessWidget {
  final DataStore store;
  final UserProv userProv;
  final FlutterSecureStorage secureStorage;
  final AppDb db;

  const MyApp(
      {super.key,
        required this.store,
        required this.userProv,
        required this.secureStorage,
        required this.db});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      language: _language,
      userProv: userProv,
      store: store,
      db: db,
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'Zine',
        theme: ThemeData(
            fontFamily: 'Poppins',
            primarySwatch: Colors.blue,
            useMaterial3: false),
        home: const SplashScreen(),
      ),
    );
  }

}