import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/home_page.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = DefaultFirebaseOptions.currentPlatform;
  // Missing when `flutterfire configure` ran before the Realtime Database
  // existed; the database SDK would otherwise crash with a cryptic error.
  if ((options.databaseURL ?? '').isEmpty) {
    runApp(const _SetupErrorApp());
    return;
  }
  await Firebase.initializeApp(options: options);
  runApp(const IrrigoApp());
}

class _SetupErrorApp extends StatelessWidget {
  const _SetupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Realtime Database URL missing.\n\n'
              '1. Firebase console → Build → Realtime Database → Create database.\n'
              '2. Run `flutterfire configure` again in the app/ folder.\n'
              '3. Restart the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class IrrigoApp extends StatelessWidget {
  const IrrigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRRIGO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}

/// Shows the login page or the home page depending on the auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authState = AuthService().authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        // Keyed by uid so switching accounts rebuilds everything.
        return user == null
            ? const LoginPage()
            : HomePage(key: ValueKey(user.uid), user: user);
      },
    );
  }
}
