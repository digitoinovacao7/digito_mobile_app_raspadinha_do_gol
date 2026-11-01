const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function findAndDelete() {
  const snapshot = await db.collection('boloes').get();
  for (const doc of snapshot.docs) {
    if (doc.id.toLowerCase().startsWith('ydpsgh')) {
      console.log('Found bolao:', doc.id, doc.data().name);
      await doc.ref.delete();
      console.log('Deleted successfully.');
    }
  }
}
findAndDelete().catch(console.error);
