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

/// Top-level function for handling background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp();

  await NotificationService().initNotification();

  // Subscribe to a topic
  // await FirebaseMessaging.instance.subscribeToTopic('kejadian');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        'Message received in foreground: ${message.notification?.title} ${message.notification?.body}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
        'Notification clicked: ${message.notification?.title} ${message.notification?.body}');
  });

  await LocationService().initialize();
  await initializeDateFormatting('id_ID', null);

  // Create a single instance of LoginViewModel
  final loginViewModel = LoginViewModel();
  await loginViewModel.initialize();
  await loginViewModel.loadSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
            value: loginViewModel), // Use the existing instance
        ChangeNotifierProvider(create: (_) => PatroliViewModel(loginViewModel)),
        ChangeNotifierProvider(create: (_) => KejadianViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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
      // Remove initialRoute and use home instead
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

          // If session is valid, go to home page, otherwise login page
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
