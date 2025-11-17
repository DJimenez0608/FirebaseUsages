import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mini_flutter_proyect/firebase_options.dart';
import 'package:mini_flutter_proyect/navigation/app_routes.dart';
import 'package:mini_flutter_proyect/provider/location_provider.dart';
import 'package:mini_flutter_proyect/provider/shared_location_provider.dart';
import 'package:mini_flutter_proyect/provider/user_provider.dart';
import 'package:mini_flutter_proyect/screen/splash_screen.dart';
import 'package:mini_flutter_proyect/services/notification_service.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar servicio de notificaciones con el navigatorKey
  await NotificationService.initialize(navigatorKey: navigatorKey);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SharedLocationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        routes: appRoutes,
      ),
    );
  }
}
