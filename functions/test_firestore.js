const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

async function run() {
  const doc = await db.collection("settings").doc("general").get();
  console.log("Data:", JSON.stringify(doc.data(), null, 2));
}

run().catch(console.error);
