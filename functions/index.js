/* eslint-disable */
const functions = require('firebase-functions');
const admin     = require('firebase-admin');

// If you placed your JSON in functions/, use this line instead of admin.initializeApp():
// admin.initializeApp({ credential: admin.credential.cert(require('./service-account.json')) });

admin.initializeApp();  // Uses the default service account in Cloud Functions

exports.notifyOwnerOnAccept = functions.firestore
  .document('sell_offers/{offerId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();

    // Only proceed when status flips to 'accepted'
    if (before.status === 'accepted' || after.status !== 'accepted') {
      return null;
    }

    // Build notification payload
    const payload = {
      notification: {
        title: 'Offer Accepted',
        body: `${after.companyName} accepted your ${after.kilograms}kg offer.`,
      }
    };

    // Look up the owner's FCM token in their user profile
    const ownerDoc = await admin.firestore().doc(`users/${after.ownerId}`).get();
    const ownerData = ownerDoc.data();
    const token = ownerData ? ownerData.fcmToken : null;
    if (!token) return null;

    // Send the push
    return admin.messaging().sendToDevice(token, payload);
  });

// Function to monitor bin level changes and send notifications
exports.monitorBinLevels = functions.database.ref('/BIN/{binId}/{materialType}/level')
  .onUpdate(async (change, context) => {
    const binId = context.params.binId;
    const materialType = context.params.materialType;
    const newLevel = change.after.val();
    const previousLevel = change.before.val();
    
    console.log(`Bin ${binId} ${materialType} level changed from ${previousLevel} to ${newLevel}`);
    
    // Only send notifications for significant changes (optional)
    if (newLevel === previousLevel) {
      console.log('Level unchanged, skipping notification');
      return null;
    }
    
    try {
      // Get bin owners from registered_bins collection in Firestore
      const binDoc = await admin.firestore().collection('registered_bins').doc(binId).get();
      
      if (!binDoc.exists) {
        console.log(`No registered bin found with ID: ${binId}`);
        return null;
      }
      
      const binData = binDoc.data();
      const ownerIds = binData.owners || [];
      
      if (ownerIds.length === 0) {
        console.log('No owners registered for this bin');
        return null;
      }
      
      console.log(`Found ${ownerIds.length} owners for bin ${binId}`);
      
      // Get FCM tokens for each owner
      const notificationPromises = ownerIds.map(async (ownerId) => {
        const userDoc = await admin.firestore().collection('users').doc(ownerId).get();
        
        if (!userDoc.exists) {
          console.log(`User ${ownerId} not found`);
          return null;
        }
        
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        if (!fcmToken) {
          console.log(`No FCM token found for user ${ownerId}`);
          return null;
        }
        
        // Prepare notification message
        const message = {
          token: fcmToken,
          notification: {
            title: 'Bin Level Update',
            body: `Your ${materialType} bin (Bin ${binId}) is now ${newLevel} full.`
          },
          data: {
            type: 'bin_level_update',
            binId: binId,
            binName: `Bin ${binId}`,
            material: materialType,
            level: newLevel
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'binit_level_channel'
            }
          },
          apns: {
            payload: {
              aps: {
                category: 'bin_updates'
              }
            }
          }
        };
        
        // Send the notification
        return admin.messaging().send(message)
          .then((response) => {
            console.log(`Successfully sent notification to ${ownerId}:`, response);
            return response;
          })
          .catch((error) => {
            console.error(`Error sending notification to ${ownerId}:`, error);
            return null;
          });
      });
      
      // Wait for all notifications to be sent
      return Promise.all(notificationPromises);
    } catch (error) {
      console.error('Error processing bin level update:', error);
      return null;
    }
  });

// Function to send test notification
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const userId = context.auth.uid;
  
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }
    
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    
    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'No FCM token found for user');
    }
    
    // Send test notification
    const message = {
      token: fcmToken,
      notification: {
        title: 'Test Notification',
        body: 'This is a test notification from Firebase Cloud Functions'
      },
      data: {
        type: 'test',
        timestamp: Date.now().toString()
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel'
        }
      }
    };
    
    const response = await admin.messaging().send(message);
    console.log('Test notification sent successfully:', response);
    
    return { success: true, message: 'Test notification sent' };
  } catch (error) {
    console.error('Error sending test notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
