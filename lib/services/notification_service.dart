import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mini_flutter_proyect/model/shared_location.dart';
import 'package:mini_flutter_proyect/navigation/routes.dart';
import 'package:mini_flutter_proyect/provider/shared_location_provider.dart';
import 'package:provider/provider.dart';

/// Maneja el token de notificaciones push del dispositivo
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Inicializa el servicio de notificaciones
  /// Solicita permisos y obtiene el token FCM
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;
    // Inicializar notificaciones locales para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notificación local tocada: ${details.id}');
        // El payload se pasa a través de details.payload
        if (details.payload != null && details.payload!.isNotEmpty) {
          _handleNotificationTap(details.payload!);
        }
      },
    );

    // Solicitar permisos de notificaciones
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Usuario otorgó permisos de notificaciones');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Usuario otorgó permisos provisionales de notificaciones');
    } else {
      debugPrint('Usuario denegó o no otorgó permisos de notificaciones');
      return;
    }

    // Configurar el handler para mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Obtener el token FCM
    final String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      debugPrint('Token FCM obtenido: ${token.substring(0, 20)}...');
    } else {
      debugPrint('No se pudo obtener el token FCM');
    }

    // Escuchar cambios en el token
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    // Manejar mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Mensaje recibido en primer plano: ${message.notification?.title}',
      );
      // Mostrar notificación local cuando la app está en primer plano
      _showLocalNotification(message);
    });

    // Manejar cuando se toca una notificación (app en segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificación tocada: ${message.notification?.title}');
      _handleRemoteMessage(message);
    });

    // Manejar cuando la app se abre desde estado terminado
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App abierta desde notificación (estado terminado)');
      // Esperar un poco para que la app se inicialice completamente
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleRemoteMessage(initialMessage);
      });
    }
  }

  /// Muestra una notificación local cuando la app está en primer plano
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Extraer userId del payload para pasarlo como payload de la notificación local
    final userId = message.data['userId'] ?? '';
    final payload = userId.isNotEmpty ? userId : null;

    const androidDetails = AndroidNotificationDetails(
      'availability_channel',
      'Usuario Disponible',
      channelDescription: 'Notificaciones cuando un usuario está disponible',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Notificación',
      notification.body ?? '',
      details,
      payload: payload,
    );
  }

  /// Maneja el tap en una notificación remota
  static void _handleRemoteMessage(RemoteMessage message) {
    final userId = message.data['userId'];
    if (userId != null && userId.isNotEmpty) {
      _navigateToMapAndTrackUser(userId);
    } else {
      debugPrint('No se encontró userId en el payload de la notificación');
    }
  }

  /// Maneja el tap en una notificación local
  static void _handleNotificationTap(String payload) {
    // El payload es el userId
    if (payload.isNotEmpty) {
      _navigateToMapAndTrackUser(payload);
    }
  }

  /// Obtiene la ubicación inicial del usuario desde Realtime Database
  static Future<SharedLocation?> _getUserLocation(String userId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        debugPrint('Usuario $userId no existe en Realtime Database');
        return null;
      }

      final data = snapshot.value;
      if (data is! Map) {
        debugPrint('Datos inválidos para usuario $userId');
        return null;
      }

      final shareWith = data['shareWith'] == true;
      if (!shareWith) {
        debugPrint('Usuario $userId no está compartiendo su ubicación');
        return null;
      }

      final latitude = (data['location'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();

      if (latitude == null || longitude == null) {
        debugPrint('Ubicación no disponible para usuario $userId');
        return null;
      }

      return SharedLocation(
        latitude: latitude,
        longitude: longitude,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error al obtener ubicación del usuario $userId: $e');
      return null;
    }
  }

  /// Navega al mapa y comienza a rastrear al usuario
  static Future<void> _navigateToMapAndTrackUser(String userId) async {
    if (_navigatorKey?.currentContext == null) {
      debugPrint('NavigatorKey no disponible, esperando...');
      // Esperar un poco y reintentar
      await Future.delayed(const Duration(milliseconds: 500));
      if (_navigatorKey?.currentContext == null) {
        debugPrint('No se pudo navegar: NavigatorKey aún no disponible');
        return;
      }
    }

    final context = _navigatorKey!.currentContext!;
    final sharedProvider = Provider.of<SharedLocationProvider>(
      context,
      listen: false,
    );

    // Obtener la ubicación inicial del usuario
    final initialLocation = await _getUserLocation(userId);
    if (initialLocation == null) {
      debugPrint('No se pudo obtener la ubicación inicial del usuario $userId');
      // Aún así navegar al mapa, el usuario puede ver que no hay ubicación disponible
    }

    // Navegar al HomeScreen si no estamos ya ahí
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != Routes.home) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.home,
        (route) => false,
      );
    }

    // Esperar un poco para que el mapa se inicialice
    await Future.delayed(const Duration(milliseconds: 300));

    // Iniciar el tracking del usuario
    if (initialLocation != null) {
      await sharedProvider.trackUser(initialLocation);
      debugPrint('Iniciado tracking del usuario $userId');
    } else {
      debugPrint('No se pudo iniciar tracking: ubicación no disponible');
    }
  }

  /// Guarda el token FCM del usuario en Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      );
      debugPrint('Token FCM guardado para usuario: ${user.uid}');
    } catch (e) {
      debugPrint('Error al guardar token FCM: $e');
    }
  }
}

