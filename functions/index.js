const {onValueUpdated} = require('firebase-functions/v2/database');
const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function que se activa cuando cambia el valor de 'shareWith' en Realtime Database
 * Detecta cuando un usuario cambia de no disponible (false) a disponible (true)
 * y envía notificaciones push a todos los demás usuarios
 */
exports.onUserShareWithChange = onValueUpdated(
  {
    ref: 'users/{userId}/shareWith',
    region: 'us-central1',
  },
  async (event) => {
    const userId = event.params.userId;
    const previousValue = event.data.before.val();
    const newValue = event.data.after.val();

    console.log(`Cambio detectado en shareWith para usuario ${userId}`);
    console.log(`  - Valor anterior: ${previousValue}`);
    console.log(`  - Valor nuevo: ${newValue}`);

    // Solo procesar si cambió de false (o null/undefined) a true
    const wasUnavailable = previousValue !== true;
    const isNowAvailable = newValue === true;

    if (!wasUnavailable || !isNowAvailable) {
      console.log('No es un cambio de no disponible a disponible, ignorando...');
      return null;
    }

    try {
      console.log(`Usuario ${userId} cambió a disponible, obteniendo información...`);

      // Obtener información del usuario desde Firestore
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log(`Usuario ${userId} no existe en Firestore, ignorando...`);
        return null;
      }

      const userData = userDoc.data();
      const userName = `${userData.name || ''} ${userData.lastName || ''}`.trim();
      const finalUserName = userName || (userData.email || 'Usuario').split('@')[0];

      console.log(`Procesando notificación de disponibilidad para: ${finalUserName}`);

      // Obtener todos los usuarios excepto el que cambió
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .get();

      const tokens = [];
      usersSnapshot.forEach((doc) => {
        // Excluir al usuario que cambió
        if (doc.id !== userId) {
          const fcmToken = doc.data().fcmToken;
          if (fcmToken && fcmToken.trim() !== '') {
            tokens.push(fcmToken);
          }
        }
      });

      if (tokens.length === 0) {
        console.log('No hay tokens FCM disponibles para enviar notificaciones');
        return null;
      }

      console.log(`Enviando notificaciones a ${tokens.length} usuarios`);

      // Preparar el mensaje de notificación
      const message = {
        notification: {
          title: 'Usuario Disponible',
          body: `${finalUserName} ahora está disponible`,
        },
        data: {
          userId: userId,
        },
        tokens: tokens,
      };

      // Enviar notificaciones
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`Notificaciones enviadas exitosamente: ${response.successCount}`);
      console.log(`Notificaciones fallidas: ${response.failureCount}`);

      // Si hay fallos, loguearlos
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
            console.error(`Error al enviar a token ${idx}:`, resp.error);
          }
        });
        console.log(`Tokens con error: ${failedTokens.length}`);
      }

      return null;
    } catch (error) {
      console.error('Error al procesar cambio de disponibilidad:', error);
      return null;
    }
  });
