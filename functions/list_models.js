const admin = require('firebase-admin');
const { GoogleGenAI } = require('@google/genai');

admin.initializeApp();

async function run() {
    const db = admin.firestore();
    const settings = await db.collection("settings").doc("general").get();
    const data = settings.data() || {};
    const key = data.api_keys?.gemini || data.gemini_api_key || data.gemini_key || data.gemini;
    if (!key) {
        console.log("No Gemini key found");
        return;
    }
    
    const ai = new GoogleGenAI({ apiKey: key });
    try {
        const models = await ai.models.list();
        console.log("Available models:");
        for (const m of models) {
             console.log(m.name);
        }
    } catch (e) {
        console.error("Error:", e.message);
    }
}
run();
