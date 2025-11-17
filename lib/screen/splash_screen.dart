import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_flutter_proyect/navigation/routes.dart';
import 'package:mini_flutter_proyect/provider/location_provider.dart';
import 'package:mini_flutter_proyect/provider/user_provider.dart';
import 'package:mini_flutter_proyect/utils/app_colors.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _checkAuthStatus);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (user == null) {
      context.read<UserProvider>().clear();
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    try {
      await locationProvider.startLocationUpdates();
    } catch (_) {
      // Ignore location errors at this stage; HomeScreen will handle permissions.
    }

    try {
      await context.read<UserProvider>().loadUser(user.uid);
    } catch (_) {
      context.read<UserProvider>().clear();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlutterLogo(size: 96),
            const SizedBox(height: 24),
            const Text(
              'Taller 3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
            ),
          ],
        ),
      ),
    );
  }
}
