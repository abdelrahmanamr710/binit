const admin = require('firebase-admin');
const faqs = require('./RCfaqs.json');

// Path to your service account key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadRCFaqs() {
  const batch = db.batch();
  faqs.forEach((faq) => {
    const docRef = db.collection('RCfaqs').doc(); // Collection name for Recycling Company FAQs
    batch.set(docRef, faq);
  });
  await batch.commit();
  console.log('Recycling Company FAQs uploaded to RCfaqs collection!');
}

uploadRCFaqs(); 