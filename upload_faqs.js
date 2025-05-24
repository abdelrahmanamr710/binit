const admin = require('firebase-admin');
const faqs = require('./faqs.json');

// Path to your service account key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadFaqs() {
  const batch = db.batch();
  faqs.forEach((faq) => {
    const docRef = db.collection('BOfaqs').doc(); // Changed collection name to BOfaqs
    batch.set(docRef, faq);
  });
  await batch.commit();
  console.log('FAQs uploaded to BOfaqs collection!');
}

uploadFaqs(); 