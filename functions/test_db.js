const admin = require("firebase-admin");
admin.initializeApp({ projectId: "raspadinhadogol" });
const db = admin.firestore();
async function check() {
  const oldDoc = await db.collection("system_config").doc("general").get();
  console.log("OLD DOC:", oldDoc.data());
  const newDoc = await db.collection("settings").doc("general").get();
  console.log("NEW DOC:", newDoc.data());
}
check().catch(console.error);
