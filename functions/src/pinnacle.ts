import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import { generateGeminiContent } from "./gemini";

// Helper to get Basic Auth header
async function getPinnacleAuth() {
    const db = admin.firestore();
    const settings = await db.collection("settings").doc("general").get();
    const pinnacleData = settings.data()?.pinnacle || {};

    const username = (pinnacleData.username || "").trim();
    const password = (pinnacleData.password || "").trim();

    if (!username || !password) {
        throw new Error("Credenciais da Pinnacle não configuradas.");
    }
    return Buffer.from(`${username}:${password}`).toString('base64');
}

async function getPinnacleBaseUrl() {
    const db = admin.firestore();
    const settings = await db.collection("settings").doc("general").get();
    const pinnacleData = settings.data()?.pinnacle || {};
    
    // Default to the official API, but allow overriding for local development server
    return pinnacleData.apiUrl || "https://api.pinnacle.com";
}

export const pinnacleGetBalance = onCall({ region: "southamerica-east1" }, async (request: any) => {
    try {
        const auth = await getPinnacleAuth();
        const baseUrl = await getPinnacleBaseUrl();
        const headers = {
            "Authorization": `Basic ${auth}`,
            "Accept": "application/json"
        };
        const response = await axios.get(`${baseUrl}/v1/client/balance`, {
            headers
        });

        let earnings30Days = 0;
        let netProfit30Days = 0;
        let settledBets30Days = 0;
        let historyError: string | null = null;

        try {
            const toDate = new Date();
            const fromDate = new Date(toDate.getTime() - (30 * 24 * 60 * 60 * 1000));
            let fromRecord = 0;
            let moreAvailable = true;
            let pageCount = 0;

            while (moreAvailable && pageCount < 20) {
                pageCount++;
                const betsResponse = await axios.get(`${baseUrl}/v4/bets`, {
                    headers,
                    params: {
                        betlist: "SETTLED",
                        fromDate: fromDate.toISOString(),
                        toDate: toDate.toISOString(),
                        sortDir: "DESC",
                        pageSize: 1000,
                        fromRecord
                    }
                });

                const betGroups = [
                    betsResponse.data.straightBets,
                    betsResponse.data.parlayBets,
                    betsResponse.data.teaserBets,
                    betsResponse.data.specialBets,
                    betsResponse.data.manualBets
                ];

                for (const bets of betGroups) {
                    if (!Array.isArray(bets)) continue;
                    for (const bet of bets) {
                        const winLoss = Number(bet.winLoss);
                        if (!Number.isFinite(winLoss)) continue;
                        netProfit30Days += winLoss;
                        if (winLoss > 0) earnings30Days += winLoss;
                        settledBets30Days++;
                    }
                }

                moreAvailable = betsResponse.data.moreAvailable === true;
                const toRecord = Number(betsResponse.data.toRecord);
                if (!moreAvailable || !Number.isFinite(toRecord)) break;
                fromRecord = toRecord + 1;
            }
        } catch (historyException: any) {
            historyError = String(
                historyException.response?.data?.message ||
                historyException.response?.data?.code ||
                historyException.message
            );
        }

        const toMoneyString = (value: unknown) => {
            const numberValue = Number(value);
            return Number.isFinite(numberValue) ? numberValue.toFixed(2) : "0.00";
        };

        return {
            success: true,
            // Keep callable payload web-safe: dart2js cannot decode Int64 values.
            balance: toMoneyString(response.data.availableBalance),
            outstandingTransactions: toMoneyString(response.data.outstandingTransactions),
            givenCredit: toMoneyString(response.data.givenCredit),
            currency: String(response.data.currency),
            earnings30Days: earnings30Days.toFixed(2),
            netProfit30Days: netProfit30Days.toFixed(2),
            settledBets30Days: String(settledBets30Days),
            historyError
        };
    } catch (e: any) {
        console.error("Pinnacle Balance Error:", e.response?.data || e.message);
        return {
            success: false,
            error: String(e.response?.data?.message || e.message)
        };
    }
});

export const analyzeMatchAndBetPinnacle = onCall({ region: "southamerica-east1" }, async (request: any) => {
    const matchContext = request.matchContext || request.data?.matchContext;
    const db = admin.firestore();
    
    await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: "⚽ Iniciando análise com Gemini para a Pinnacle...",
        type: "info"
    });

    try {
        const settings = await db.collection("settings").doc("general").get();
        const settingsData = settings.data() || {};
        const botData = settingsData.pinnacle || {};
        const geminiApiKey =
            settingsData.api_keys?.gemini ||
            settingsData.gemini_api_key ||
            settingsData.gemini_key ||
            settingsData.gemini;

        if (!geminiApiKey) {
            throw new Error("Chave de API do Gemini não configurada.");
        }

        const prompt = `Você é um Analista de Apostas Esportivas focado na Pinnacle. Analise este jogo e retorne um JSON com a decisão. Se as chances forem baixas, pule (SKIP). Contexto: ${matchContext}.
O JSON DEVE CONTER OBRIGATORIAMENTE OS SEGUINTES CAMPOS:
- "decision": "BET" ou "SKIP"
- "confidence": um número de 0 a 100
- "reasoning": uma string explicando o motivo
- "suggestedMarket": (opcional) "MONEYLINE", "SPREAD", ou "TOTAL"
- "suggestedSelection": (opcional) a seleção
NAO USE BLOCOS DE CODIGO MARKDOWN NO RETORNO.`;
        
        const result = await generateGeminiContent(String(geminiApiKey), prompt);

        const analysis = JSON.parse(result.text || "{}");

        await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `🧠 Decisão do Gemini: ${analysis.decision} (Confiança: ${analysis.confidence}%) - ${analysis.reasoning}`,
            type: analysis.decision === "BET" ? "success" : "warning"
        });

        const confidence = Number(analysis.confidence);
        const minConfidence = Number(botData.minConfidence) || 80;
        const shouldBet =
            analysis.decision === "BET" &&
            Number.isFinite(confidence) &&
            confidence >= minConfidence;

        const decision = {
            apostar: shouldBet,
            tipo: String(analysis.suggestedMarket || "NÃO INFORMADO"),
            selecao: String(analysis.suggestedSelection || "NÃO INFORMADA"),
            confianca: Number.isFinite(confidence) ? confidence.toFixed(0) : "0",
            justificativa: String(analysis.reasoning || "Sem justificativa.")
        };

        const payloadStr = JSON.stringify(decision);

        if (!shouldBet) {
            return {
                success: true,
                payload: payloadStr,
                message: "Aposta ignorada pelo critério de confiança."
            };
        }

        // 2. Place Bet on Pinnacle (Simulated structure for demonstration, requires exact eventId and lineId in real scenario)
        // Note: Pinnacle API requires knowing the exact Event ID, Line ID, and Team type to place a real bet.
        // For an automatic bot, we would typically fetch the fixtures first, match the string, get the IDs, and then place.
        await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `⚠️ Ordem enviada para a Pinnacle (Modo Demonstração) - Mercado: ${analysis.suggestedMarket}`,
            type: "info"
        });

        return {
            success: true,
            payload: payloadStr,
            message: "Análise concluída em modo demonstração."
        };

    } catch (e: any) {
        await db.collection("pinnacle_logs").add({
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `❌ Erro Crítico: ${e.message}`,
            type: "error"
        });
        return { success: false, error: String(e.message) };
    }
});
