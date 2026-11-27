import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/new_complaint_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/complaint_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // استخدام الإعدادات الخاصة بكل منصة (ضروري للويب وويندوز وماك).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Error: Failed to initialize Firebase. Check setup files.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // كل الخدمات تُنشأ مرة واحدة هنا، والشاشات تأخذها عبر context.read<...>()
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ComplaintService>(create: (_) => ComplaintService()),
        Provider<UserService>(create: (_) => UserService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FixItFast',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/new_complaint': (context) => const NewComplaintScreen(),
        },
      ),
    );
  }
}
