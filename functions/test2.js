const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

async function run() {
  console.log("Fetching users...");
  const users = await db.collection("users").limit(1).get();
  console.log("Users empty?", users.empty);
  
  console.log("Fetching settings/general...");
  const doc = await db.collection("settings").doc("general").get();
  console.log("Doc exists?", doc.exists);
  console.log("Data:", JSON.stringify(doc.data(), null, 2));
}

run().catch(console.error);
