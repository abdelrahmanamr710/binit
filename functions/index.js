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

    // Look up the owner’s FCM token in their user profile
    const ownerDoc = await admin.firestore().doc(`users/${after.ownerId}`).get();
    const ownerData = ownerDoc.data();
    const token = ownerData ? ownerData.fcmToken : null;
    if (!token) return null;

    // Send the push
    return admin.messaging().sendToDevice(token, payload);
  });
