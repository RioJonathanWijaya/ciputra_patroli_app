import 'package:ciputra_patroli/services/location_service.dart';
import 'package:ciputra_patroli/services/navigation_service.dart';
import 'package:ciputra_patroli/services/notification_service.dart';
import 'package:ciputra_patroli/viewModel/kejadian_viewModel.dart';
import 'package:ciputra_patroli/viewModel/login_viewModel.dart';
import 'package:ciputra_patroli/viewModel/patroli_viewModel.dart';
import 'package:ciputra_patroli/views/home_page.dart';
import 'package:ciputra_patroli/views/kejadian/kejadian_input_page.dart';
import 'package:ciputra_patroli/views/login/login_page.dart';
import 'package:ciputra_patroli/views/patroli/checkpoint_page.dart';
import 'package:ciputra_patroli/views/patroli/patroli_jadwal_page.dart';
import 'package:ciputra_patroli/views/patroli/patroli_mulai_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Top-level function for handling background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase first
    await Firebase.initializeApp();
    developer.log('Firebase initialized successfully');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize notification service with proper error handling
    final notificationService = NotificationService();
    try {
      await notificationService.initNotification();
      developer.log('Notification service initialized successfully');
    } catch (e) {
      developer.log('Error initializing notification service: $e');
      // Continue app initialization even if notifications fail
    }

    // Set up message handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
          'Message received in foreground: ${message.notification?.title} ${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
          'Notification clicked: ${message.notification?.title} ${message.notification?.body}');
    });

    // Initialize other services
    await LocationService().initialize();
    await initializeDateFormatting('id_ID', null);

    // Create and initialize LoginViewModel
    final loginViewModel = LoginViewModel();
    await loginViewModel.initialize();
    await loginViewModel.loadSession();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: loginViewModel),
          ChangeNotifierProvider(
              create: (_) => PatroliViewModel(loginViewModel)),
          ChangeNotifierProvider(create: (_) => KejadianViewModel()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    developer.log('Error during app initialization: $e');
    developer.log('Stack trace: $stackTrace');
    // Show error UI or handle the error appropriately
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loginViewModel = Provider.of<LoginViewModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      title: 'Ciputra Patroli',
      theme: ThemeData(
        primaryColor: const Color(0xFF1C3A6B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C3A6B),
          primary: const Color(0xFF1C3A6B),
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: loginViewModel.isSessionValid(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return snapshot.data == true ? const HomePage() : const LoginPage();
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomePage(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginPage(),
            );
          case '/jadwalPatroli':
            return MaterialPageRoute(
              builder: (_) => const JadwalPatrolPage(),
            );
          case '/checkpoint':
            return MaterialPageRoute(
              builder: (_) => const CheckpointPage(),
              settings: settings,
            );
          case '/patroliJadwal':
            return MaterialPageRoute(
              builder: (_) => const JadwalPatrolPage(),
            );
          case '/patroliMulai':
            return MaterialPageRoute(
              builder: (_) => const StartPatroli(),
              settings: settings,
            );
          case '/kejadianInput':
            return MaterialPageRoute(
              builder: (_) => const KejadianInputPage(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
            );
        }
      },
    );
  }
}
