import 'package:flutter/material.dart';
import 'package:mini_flutter_proyect/navigation/routes.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(Routes.forgotPassword),
      ),
    );
  }
}

