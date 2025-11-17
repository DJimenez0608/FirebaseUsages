import 'package:flutter/material.dart';
import 'package:mini_flutter_proyect/navigation/routes.dart';
import 'package:mini_flutter_proyect/screen/available_users_screen.dart';
import 'package:mini_flutter_proyect/screen/forgot_password_screen.dart';
import 'package:mini_flutter_proyect/screen/home_screen.dart';
import 'package:mini_flutter_proyect/screen/login_screen.dart';
import 'package:mini_flutter_proyect/screen/profile_screen.dart';
import 'package:mini_flutter_proyect/screen/register_screen.dart';

Map<String, Widget Function(BuildContext)> get appRoutes {
  return {
    Routes.home: (context) => const HomeScreen(),
    Routes.profile: (context) => const ProfileScreen(),
    Routes.login: (context) => const LoginScreen(),
    Routes.register: (context) => const RegisterScreen(),
    Routes.forgotPassword: (context) => const ForgotPasswordScreen(),
    Routes.availableUsers: (context) => const AvailableUsersScreen(),
  };
}
