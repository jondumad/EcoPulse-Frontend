import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/mission_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const EcoPulseApp());
}

class EcoPulseApp extends StatelessWidget {
  const EcoPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const EcoPulseAppView(),
    );
  }
}

class EcoPulseAppView extends StatefulWidget {
  const EcoPulseAppView({super.key});

  @override
  State<EcoPulseAppView> createState() => _EcoPulseAppViewState();
}

class _EcoPulseAppViewState extends State<EcoPulseAppView> {
  @override
  void initState() {
    super.initState();
    // Initialize auth and attendance check after binding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initAuth();
      Provider.of<AttendanceProvider>(context, listen: false).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoPulse',
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (auth.isAuthenticated) {
            return const MainShell();
          } else {
            return const LoginScreen();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
