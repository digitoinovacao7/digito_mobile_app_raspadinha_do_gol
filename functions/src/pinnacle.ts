import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import { GoogleGenAI, Type } from "@google/genai";

const geminiApiKey = process.env.GEMINI_API_KEY || "YOUR_GEMINI_KEY_HERE"; // In production, use Firebase Secret Manager
const ai = new GoogleGenAI({ apiKey: geminiApiKey });

// Helper to get Basic Auth header
async function getPinnacleAuth() {
    const db = admin.firestore();
    const settings = await db.collection("settings").doc("general").get();
    const pinnacleData = settings.data()?.pinnacle || {};

    if (!pinnacleData.username || !pinnacleData.password) {
        throw new Error("Credenciais da Pinnacle não configuradas.");
    }
    return Buffer.from(`${pinnacleData.username}:${pinnacleData.password}`).toString('base64');
}

export const pinnacleGetBalance = functions.https.onCall(async (request: any) => {
    try {
        const auth = await getPinnacleAuth();
        const response = await axios.get("https://api.pinnacle.com/v1/client/balance", {
            headers: {
                "Authorization": `Basic ${auth}`,
                "Accept": "application/json"
            }
        });

        return { 
            success: true, 
            balance: response.data.availableBalance,
            currency: response.data.currency
        };
    } catch (e: any) {
        console.error("Pinnacle Balance Error:", e.response?.data || e.message);
        return { success: false, error: e.response?.data?.message || e.message };
    }
});

export const analyzeMatchAndBetPinnacle = functions.https.onCall(async (request: any) => {
    const matchContext = request.matchContext || request.data?.matchContext;
    const db = admin.firestore();
    
    await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: "⚽ Iniciando análise com Gemini para a Pinnacle...",
        type: "info"
    });

    try {
        const settings = await db.collection("settings").doc("general").get();
        const botData = settings.data()?.pinnacle || {};
        
        // 1. Analyze with Gemini
        const prompt = `Você é um Analista de Apostas Esportivas focado na Pinnacle. Analise este jogo e retorne um JSON com a decisão. Se as chances forem baixas, pule (SKIP). Contexto: ${matchContext}`;
        
        const result = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: prompt,
            config: {
                responseMimeType: "application/json",
                responseSchema: {
                    type: Type.OBJECT,
                    properties: {
                        decision: { type: Type.STRING, enum: ["BET", "SKIP"] },
                        confidence: { type: Type.NUMBER, description: "0 to 100" },
                        reasoning: { type: Type.STRING },
                        suggestedMarket: { type: Type.STRING, description: "Ex: MONEYLINE, SPREAD, TOTAL" },
                        suggestedSelection: { type: Type.STRING }
                    },
                    required: ["decision", "confidence", "reasoning"]
                }
            }
        });

        const analysis = JSON.parse(result.text || "{}");

        await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `🧠 Decisão do Gemini: ${analysis.decision} (Confiança: ${analysis.confidence}%) - ${analysis.reasoning}`,
            type: analysis.decision === "BET" ? "success" : "warning"
        });

        if (analysis.decision === "SKIP" || analysis.confidence < (botData.minConfidence || 80)) {
            return { success: true, message: "Aposta ignorada pelo critério de confiança." };
        }

        // 2. Place Bet on Pinnacle (Simulated structure for demonstration, requires exact eventId and lineId in real scenario)
        // Note: Pinnacle API requires knowing the exact Event ID, Line ID, and Team type to place a real bet.
        // For an automatic bot, we would typically fetch the fixtures first, match the string, get the IDs, and then place.
        await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `⚠️ Ordem enviada para a Pinnacle (Modo Demonstração) - Mercado: ${analysis.suggestedMarket}`,
            type: "info"
        });

        return { success: true, message: "Análise concluída e ordem processada." };

    } catch (e: any) {
        await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `❌ Erro Crítico: ${e.message}`,
            type: "error"
        });
        return { success: false, error: e.message };
    }
});
