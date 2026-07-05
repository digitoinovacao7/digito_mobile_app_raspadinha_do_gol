const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function check() {
  const doc = await db.collection("settings").doc("general").get();
  console.log(JSON.stringify(doc.data()?.betfair || {}, null, 2));
}
check();
