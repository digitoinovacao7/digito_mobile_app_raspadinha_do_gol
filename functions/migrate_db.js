const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

async function migrate() {
  const oldSnap = await db.collection('system_config').doc('general').get();
  if (oldSnap.exists) {
    await db.collection('settings').doc('general').set(oldSnap.data());
    console.log("Migration complete!");
  } else {
    console.log("No old data found.");
  }
}

migrate();
