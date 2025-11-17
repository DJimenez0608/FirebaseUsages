# 📍 Location Tracker App

Aplicación móvil desarrollada en Flutter para el seguimiento y compartimiento de ubicación en tiempo real entre usuarios. Permite a los usuarios compartir su ubicación, ver la ubicación de otros usuarios disponibles y recibir notificaciones cuando alguien se pone disponible.

## 🚀 Características Principales

### 🔐 Autenticación
- **Registro de usuarios** con email y contraseña
- **Inicio de sesión** seguro con Firebase Authentication
- **Recuperación de contraseña** mediante email
- **Persistencia de sesión** - los usuarios permanecen autenticados

### 📍 Seguimiento de Ubicación
- **Tracking en tiempo real** de la ubicación del usuario
- **Compartir ubicación** con otros usuarios mediante un toggle
- **Visualización en mapa interactivo** usando OpenStreetMap
- **Marcadores dinámicos** para usuarios compartiendo ubicación
- **Cálculo de distancia** en tiempo real entre usuarios
- **Marcadores estáticos** para ubicaciones de interés

### 👥 Gestión de Usuarios
- **Lista de usuarios disponibles** que están compartiendo su ubicación
- **Selección de usuario** para hacer seguimiento en el mapa
- **Información de perfil** con foto y nombre
- **Actualización de perfil** con foto de perfil

### 🔔 Notificaciones Push
- **Notificaciones en tiempo real** cuando un usuario se pone disponible
- **Navegación directa** al mapa al hacer clic en la notificación
- **Seguimiento automático** del usuario notificado
- **Notificaciones locales** en primer plano

### 🗺️ Funcionalidades del Mapa
- **Mapa interactivo** con OpenStreetMap
- **Tracking automático** de la ubicación del usuario
- **Marcadores personalizados** para usuarios
- **Ajuste automático de cámara** para mostrar todos los marcadores
- **Cálculo y visualización de distancia** entre usuarios

## 🛠️ Tecnologías Utilizadas

### Frontend (Flutter)
- **Flutter** 3.7.2+ - Framework multiplataforma
- **Provider** - Gestión de estado reactiva
- **flutter_osm_plugin** - Integración de mapas OpenStreetMap
- **location** - Servicios de geolocalización
- **permission_handler** - Manejo de permisos

### Backend (Firebase)
- **Firebase Authentication** - Autenticación de usuarios
- **Cloud Firestore** - Base de datos NoSQL para datos de usuario
- **Realtime Database** - Base de datos en tiempo real para ubicaciones
- **Firebase Storage** - Almacenamiento de imágenes de perfil
- **Firebase Cloud Messaging (FCM)** - Notificaciones push
- **Cloud Functions** - Funciones serverless para notificaciones

### Otras Dependencias
- **image_picker** - Selección de imágenes desde galería/cámara
- **flutter_image_compress** - Compresión de imágenes
- **flutter_local_notifications** - Notificaciones locales
- **flutter_dotenv** - Variables de entorno para configuración segura

## 📋 Requisitos Previos

- Flutter SDK 3.7.2 o superior
- Dart SDK compatible
- Cuenta de Firebase con proyecto configurado
- Android Studio / Xcode (para desarrollo móvil)
- Node.js (para Cloud Functions)

## 🔧 Configuración

### 1. Clonar el Repositorio

```bash
git clone https://github.com/DJimenez0608/FirebaseUsages.git
cd FirebaseUsages/mini_flutter_proyect
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Configurar Variables de Entorno

1. Copia el archivo `.env.example` a `.env`:
```bash
cp .env.example .env
```

2. Edita `.env` y agrega tus credenciales de Firebase:
```env
FIREBASE_API_KEY=tu_api_key_aqui
FIREBASE_APP_ID=tu_app_id_aqui
FIREBASE_MESSAGING_SENDER_ID=tu_sender_id_aqui
FIREBASE_PROJECT_ID=tu_project_id_aqui
FIREBASE_STORAGE_BUCKET=tu_storage_bucket_aqui
```

### 4. Configurar Firebase

#### Android
1. Descarga `google-services.json` desde la consola de Firebase
2. Colócalo en `android/app/google-services.json`
3. **IMPORTANTE**: Este archivo está en `.gitignore` y no debe subirse al repositorio

#### iOS (si aplica)
1. Descarga `GoogleService-Info.plist` desde la consola de Firebase
2. Colócalo en `ios/Runner/GoogleService-Info.plist`

### 5. Configurar Cloud Functions

```bash
cd functions
npm install
```

Asegúrate de tener configurado Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

## 🏗️ Estructura del Proyecto

```
mini_flutter_proyect/
├── lib/
│   ├── config/
│   │   └── firebase_config.dart      # Configuración de Firebase desde variables de entorno
│   ├── model/
│   │   └── shared_location.dart      # Modelo de datos para ubicaciones compartidas
│   ├── navigation/
│   │   ├── app_routes.dart           # Definición de rutas
│   │   └── routes.dart               # Constantes de rutas
│   ├── provider/
│   │   ├── location_provider.dart    # Provider para ubicación del usuario
│   │   ├── shared_location_provider.dart  # Provider para ubicaciones compartidas
│   │   └── user_provider.dart        # Provider para datos de usuario
│   ├── screen/
│   │   ├── available_users_screen.dart    # Lista de usuarios disponibles
│   │   ├── forgot_password_screen.dart    # Recuperación de contraseña
│   │   ├── home_screen.dart          # Pantalla principal con mapa
│   │   ├── login_screen.dart         # Inicio de sesión
│   │   ├── register_screen.dart      # Registro de usuarios
│   │   └── splash_screen.dart        # Pantalla de carga inicial
│   ├── services/
│   │   ├── available_users_service.dart   # Servicio para obtener usuarios disponibles
│   │   ├── notification_service.dart      # Servicio de notificaciones
│   │   ├── realtime_database_service.dart # Servicio de Realtime Database
│   │   └── storage_service.dart      # Servicio de Firebase Storage
│   ├── utils/
│   │   ├── app_colors.dart           # Colores de la aplicación
│   │   ├── distance_utils.dart       # Utilidades para cálculo de distancias
│   │   └── image_utils.dart          # Utilidades para manejo de imágenes
│   └── main.dart                     # Punto de entrada de la aplicación
├── functions/
│   └── index.js                      # Cloud Functions para notificaciones
├── assets/
│   └── locations - Copy (5).json     # Marcadores estáticos del mapa
├── .env.example                      # Plantilla de variables de entorno
├── .gitignore                        # Archivos ignorados por Git
└── pubspec.yaml                      # Dependencias del proyecto
```

## 🚀 Ejecutar la Aplicación

### Desarrollo

```bash
flutter run
```

### Build para Android

```bash
flutter build apk --release
```


## 🔐 Seguridad

- ✅ **Variables de entorno** para API keys (no hardcodeadas)
- ✅ **`.gitignore`** configurado para excluir archivos sensibles
- ✅ **Firebase Security Rules** recomendadas para producción
- ✅ **Autenticación segura** con Firebase Auth

**IMPORTANTE**: Nunca subas archivos con credenciales reales al repositorio. Usa siempre variables de entorno.

## 📱 Funcionalidades Detalladas

### Compartir Ubicación
Los usuarios pueden activar/desactivar el compartimiento de su ubicación mediante un toggle en el menú. Cuando se activa:
- La ubicación se actualiza en tiempo real en Realtime Database
- Se envía una notificación push a todos los demás usuarios
- El usuario aparece en la lista de usuarios disponibles

### Seguimiento de Usuarios
- Desde la pantalla de usuarios disponibles, puedes seleccionar un usuario
- El mapa navega automáticamente y muestra la ubicación del usuario seleccionado
- Se calcula y muestra la distancia en tiempo real
- Los marcadores se actualizan automáticamente cuando cambia la ubicación

### Notificaciones
- Cuando un usuario se pone disponible, todos los demás usuarios reciben una notificación
- Al hacer clic en la notificación, la app navega al mapa y comienza a seguir al usuario
- Las notificaciones funcionan tanto en primer plano como en segundo plano



## 📝 Licencia

Este proyecto es privado y está destinado únicamente para uso educativo.

## 👤 Autor

**Djimenez06**
- Email: dicajino06@gmail.com
- GitHub: [@DJimenez0608](https://github.com/DJimenez0608)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si tienes preguntas o encuentras algún problema, por favor abre un issue en el repositorio.
ecto, ¡dale una estrella!
