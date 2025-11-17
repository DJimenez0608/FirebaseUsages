# Instrucciones para Desplegar Cloud Functions

## Prerrequisitos

1. **Node.js instalado** (versión 18 o superior)
   - Descarga desde: https://nodejs.org/
   - Verifica instalación: `node --version`

2. **Firebase CLI instalado**
   ```bash
   npm install -g firebase-tools
   ```

3. **Autenticado en Firebase**
   ```bash
   firebase login
   ```

## Pasos para Desplegar

### 1. Navegar a la carpeta del proyecto
```bash
cd mini_flutter_proyect
```

### 2. Instalar dependencias de Functions
```bash
cd functions
npm install
cd ..
```

### 3. Verificar que estás en el proyecto correcto
```bash
firebase projects:list
```

Si no estás en el proyecto correcto, selecciónalo:
```bash
firebase use taller3-7a8a7
```

### 4. Desplegar la función
```bash
firebase deploy --only functions
```

## Verificar el Despliegue

1. Ve a Firebase Console: https://console.firebase.google.com/
2. Selecciona tu proyecto: `taller3-7a8a7`
3. Ve a la sección **Functions**
4. Deberías ver la función `onUserAvailabilityChange`

## Probar la Función

1. En tu app Flutter, cambia un usuario de "no disponible" a "disponible"
2. Verifica en Firebase Console > Functions > Logs que la función se ejecutó
3. Los otros usuarios deberían recibir la notificación push

## Ver Logs

```bash
firebase functions:log
```

O en Firebase Console:
- Functions > onUserAvailabilityChange > Logs

## Solución de Problemas

### Error: "Functions directory does not exist"
- Asegúrate de estar en la carpeta raíz del proyecto
- Verifica que existe la carpeta `functions/`

### Error: "Permission denied"
- Ejecuta `firebase login` nuevamente
- Verifica que tienes permisos en el proyecto Firebase

### Error: "Node version mismatch"
- Instala Node.js 18 o superior
- Verifica con `node --version`

