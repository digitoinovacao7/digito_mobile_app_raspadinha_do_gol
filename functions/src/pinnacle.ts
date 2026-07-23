import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as crypto from "crypto";
import * as admin from "firebase-admin";
import axios from "axios";
import { generateGeminiContent } from "./gemini";
import {
    acceptedBetStatus,
    mapSelectionToPinnacleTeam,
    validateRiskControls
} from "./pinnacle_logic";

// Helper to get Basic Auth header
type PinnacleConfig = {
    username?: string;
    password?: string;
    apiUrl?: string;
    active?: boolean;
    mode?: "simulation" | "real";
    apiAccessApproved?: boolean;
    stake?: number;
    maxStake?: number;
    minBalance?: number;
    minConfidence?: number;
};

async function getPinnacleConfig(): Promise<PinnacleConfig> {
    const db = admin.firestore();
    const privateSettings = await db.collection("private_settings").doc("pinnacle").get();
    return (privateSettings.data() || {}) as PinnacleConfig;
}

async function getPinnacleAuth(config?: PinnacleConfig) {
    const pinnacleData = config || await getPinnacleConfig();

    const username = (pinnacleData.username || "").trim();
    const password = (pinnacleData.password || "").trim();

    if (!username || !password) {
        throw new Error("Credenciais da Pinnacle não configuradas.");
    }
    return Buffer.from(`${username}:${password}`).toString('base64');
}

async function getPinnacleBaseUrl() {
    const pinnacleData = await getPinnacleConfig();
    return pinnacleData.apiUrl || "https://api.pinnacle.com";
}

async function requireAdmin(request: any) {
    if (!request.auth?.uid) {
        throw new HttpsError("unauthenticated", "Faça login para continuar.");
    }
    const user = await admin.firestore().collection("users").doc(request.auth.uid).get();
    if (String(user.data()?.role || "").trim().toLowerCase() !== "admin") {
        throw new HttpsError("permission-denied", "Acesso restrito ao administrador.");
    }
}

export const pinnacleGetBalance = onCall({ region: "southamerica-east1" }, async (request: any) => {
    try {
        await requireAdmin(request);
        const config = await getPinnacleConfig();
        const auth = await getPinnacleAuth(config);
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
    await requireAdmin(request);
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
        const botData = await getPinnacleConfig();
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

export const runAutomatedPinnacleBot = onSchedule({
    schedule: "0 * * * *", // Runs every hour
    region: "southamerica-east1",
    timeoutSeconds: 300 // Allow up to 5 minutes for API calls and Gemini
}, async (event) => {
    const db = admin.firestore();
    try {
        const pinnacleData = await getPinnacleConfig();
        if (pinnacleData.active !== true) {
            return;
        }

        const mode = pinnacleData.mode === "real" ? "real" : "simulation";
        const stake = Number(pinnacleData.stake);
        const maxStake = Number(pinnacleData.maxStake);
        const minBalance = Number(pinnacleData.minBalance);
        const minConfidence = Number(pinnacleData.minConfidence);

        validateRiskControls({ stake, maxStake, minBalance, minConfidence });
        if (mode === "real" && pinnacleData.apiAccessApproved !== true) {
            throw new Error("Modo real bloqueado: acesso oficial à API não confirmado.");
        }

        await db.collection("pinnacle_logs").add({
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `🤖 Iniciando varredura automática em modo ${mode.toUpperCase()}.`,
            type: "info"
        });

        const settings = await db.collection("settings").doc("general").get();
        const settingsData = settings.data() || {};
        const geminiApiKey = settingsData.api_keys?.gemini || settingsData.gemini_api_key || settingsData.gemini_key || settingsData.gemini;

        if (!geminiApiKey) {
            throw new Error("Chave Gemini não configurada.");
        }

        const auth = await getPinnacleAuth(pinnacleData);
        const baseUrl = await getPinnacleBaseUrl();
        const headers = {
            "Authorization": `Basic ${auth}`,
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "RaspadinhaDoGol/1.0"
        };

        const balanceResponse = await axios.get(`${baseUrl}/v1/client/balance`, { headers });
        const availableBalance = Number(balanceResponse.data?.availableBalance);
        if (!Number.isFinite(availableBalance) || availableBalance - stake < minBalance) {
            throw new Error("Saldo insuficiente para apostar sem violar a reserva mínima.");
        }

        // 1. Fetch upcoming Soccer fixtures (sportId: 29)
        const fixturesResponse = await axios.get(`${baseUrl}/v1/fixtures`, {
            headers,
            params: { sportId: 29, isLive: false }
        });

        // 2. Fetch current Odds
        const oddsResponse = await axios.get(`${baseUrl}/v1/odds`, {
            headers,
            params: { sportId: 29, isLive: false, oddsFormat: "DECIMAL" }
        });

        const leaguesResponse = await axios.get(`${baseUrl}/v2/leagues`, {
            headers,
            params: { sportId: 29 }
        });

        const fixtures = fixturesResponse.data?.league || fixturesResponse.data?.leagues || [];
        const odds = oddsResponse.data?.leagues || [];
        const leagueDefinitions = leaguesResponse.data?.leagues || [];

        // Simple mapping to get max 3 valid match contexts to avoid overload
        let validMatchesFound = 0;
        const matchesToAnalyze = [];

        for (const league of fixtures) {
            if (validMatchesFound >= 2) break; // Analyze max 2 matches per run
            for (const ev of league.events) {
                if (validMatchesFound >= 2) break;
                
                const eventId = ev.id;
                const leagueId = league.id;
                const homeTeam = ev.home;
                const awayTeam = ev.away;
                const startTime = ev.starts;

                // Find corresponding odds
                const leagueOdds = odds.find((lo: any) => lo.id === league.id);
                if (leagueOdds) {
                    const eventOdds = leagueOdds.events?.find((eo: any) => eo.id === eventId);
                    if (eventOdds && eventOdds.periods && eventOdds.periods.length > 0) {
                        const period0 = eventOdds.periods.find((p: any) => p.number === 0); // Full match
                        if (period0 && period0.moneyline) {
                            const lineId = period0.lineId;
                            const homeOdd = period0.moneyline.home;
                            const awayOdd = period0.moneyline.away;
                            const drawOdd = period0.moneyline.draw;

                            matchesToAnalyze.push({
                                leagueId,
                                eventId,
                                lineId,
                                homeTeam,
                                awayTeam,
                                startTime,
                                homeOdd,
                                awayOdd,
                                drawOdd
                            });
                            validMatchesFound++;
                        }
                    }
                }
            }
        }

        if (matchesToAnalyze.length === 0) {
            await db.collection("pinnacle_logs").add({
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                message: "Nenhum jogo com Moneyline encontrado para análise.",
                type: "warning"
            });
            return;
        }

        // 3. Pass to Gemini
        let betProcessed = false;

        for (const match of matchesToAnalyze) {
            if (betProcessed) break;

            const context = `Jogo: ${match.homeTeam} vs ${match.awayTeam}. Horário: ${match.startTime}. Odds Moneyline - Casa: ${match.homeOdd}, Empate: ${match.drawOdd}, Visitante: ${match.awayOdd}.`;
            
            const prompt = `Você é um Analista de Apostas Esportivas focado na Pinnacle. Analise este jogo e retorne um JSON com a decisão.
O JSON DEVE CONTER OBRIGATORIAMENTE OS SEGUINTES CAMPOS:
- "decision": "BET" ou "SKIP"
- "confidence": um número de 0 a 100
- "reasoning": uma string explicando o motivo
- "suggestedMarket": DEVE SER "MONEYLINE"
- "team": DEVE SER "TEAM1" (Casa), "TEAM2" (Visitante) ou "DRAW" (Empate).
Contexto do Jogo: ${context}`;

            const result = await generateGeminiContent(String(geminiApiKey), prompt);
            const analysis = JSON.parse(result.text || "{}");

            await db.collection("pinnacle_logs").add({
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                message: `🧠 [Auto] Análise ${match.homeTeam} vs ${match.awayTeam}: ${analysis.decision} (${analysis.confidence}%) - ${analysis.reasoning}`,
                type: analysis.decision === "BET" ? "success" : "warning"
            });

            const confidence = Number(analysis.confidence);
            const selectedSide = String(analysis.team || "").toUpperCase();
            if (!["TEAM1", "TEAM2", "DRAW"].includes(selectedSide)) {
                await db.collection("pinnacle_logs").add({
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    message: `⚠️ Seleção inválida da IA para ${match.homeTeam} vs ${match.awayTeam}.`,
                    type: "warning"
                });
                continue;
            }

            if (analysis.decision === "BET" && Number.isFinite(confidence) && confidence >= minConfidence) {
                const leagueDefinition = leagueDefinitions.find((item: any) => item.id === match.leagueId);
                const homeTeamType = String(leagueDefinition?.homeTeamType || "").toUpperCase();
                if (homeTeamType !== "TEAM1" && homeTeamType !== "TEAM2") {
                    throw new Error(`Mapeamento homeTeamType ausente para a liga ${match.leagueId}.`);
                }

                const team = mapSelectionToPinnacleTeam(selectedSide, homeTeamType);

                const lineResponse = await axios.get(`${baseUrl}/v1/line`, {
                    headers,
                    params: {
                        sportId: 29,
                        leagueId: match.leagueId,
                        eventId: match.eventId,
                        periodNumber: 0,
                        betType: "MONEYLINE",
                        team,
                        oddsFormat: "DECIMAL"
                    }
                });
                const line = lineResponse.data || {};
                if (line.status !== "SUCCESS" || !line.lineId) {
                    throw new Error("Linha deixou de estar disponível antes da aposta.");
                }
                const minRiskStake = Number(line.minRiskStake);
                const maxRiskStake = Number(line.maxRiskStake);
                if ((Number.isFinite(minRiskStake) && stake < minRiskStake) ||
                    (Number.isFinite(maxRiskStake) && stake > maxRiskStake)) {
                    throw new Error("Stake fora dos limites atuais retornados pela Pinnacle.");
                }

                if (mode === "simulation") {
                    await db.collection("pinnacle_logs").add({
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        message: `🧪 Simulação aprovada: ${stake} em ${match.homeTeam} vs ${match.awayTeam}, seleção ${team}, linha ${line.lineId}. Nenhuma ordem enviada.`,
                        type: "success"
                    });
                    betProcessed = true;
                    continue;
                }

                const hourKey = new Date().toISOString().slice(0, 13).replace(/[^0-9]/g, "");
                const attemptRef = db.collection("pinnacle_bet_attempts").doc(hourKey);
                const uniqueRequestId = crypto.randomUUID();
                await db.runTransaction(async transaction => {
                    const existing = await transaction.get(attemptRef);
                    if (existing.exists) {
                        throw new Error("Já existe uma tentativa de aposta nesta hora.");
                    }
                    transaction.create(attemptRef, {
                        uniqueRequestId,
                        eventId: match.eventId,
                        leagueId: match.leagueId,
                        stake,
                        status: "CREATED",
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                });

                const placeBetPayload = {
                    uniqueRequestId,
                    acceptBetterLine: false,
                    stake: stake,
                    winRiskStake: "WIN",
                    lineId: line.lineId,
                    sportId: 29,
                    eventId: match.eventId,
                    periodNumber: 0,
                    betType: "MONEYLINE",
                    team
                };

                try {
                    const betResponse = await axios.post(`${baseUrl}/v4/bets/straight`, placeBetPayload, { headers });
                    const status = String(betResponse.data?.status || "UNKNOWN");
                    await attemptRef.update({
                        status,
                        betId: betResponse.data?.betId || null,
                        errorCode: betResponse.data?.errorCode || null,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    if (!acceptedBetStatus(status)) {
                        throw new Error(`Aposta não aceita: ${status} ${betResponse.data?.errorCode || ""}`.trim());
                    }
                    await db.collection("pinnacle_logs").add({
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        message: `${status === "ACCEPTED" ? "✅" : "⏳"} Ordem ${status}: ${stake} em ${match.homeTeam} vs ${match.awayTeam}, seleção ${team}.`,
                        type: status === "ACCEPTED" ? "success" : "warning"
                    });
                    betProcessed = true;
                } catch (betError: any) {
                    let reconciledStatus = "UNKNOWN";
                    try {
                        const check = await axios.get(`${baseUrl}/v4/bets`, {
                            headers,
                            params: { uniqueRequestIds: uniqueRequestId }
                        });
                        const found = check.data?.straightBets?.[0];
                        reconciledStatus = String(found?.betStatus || found?.status || "NOT_FOUND");
                        await attemptRef.update({
                            status: reconciledStatus,
                            betId: found?.betId || null,
                            reconciledAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                    } catch (reconcileError: any) {
                        await attemptRef.update({
                            status: "RECONCILIATION_FAILED",
                            reconciliationError: String(reconcileError.message),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }
                    await db.collection("pinnacle_logs").add({
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        message: `❌ Ordem não confirmada (${reconciledStatus}): ${betError.response?.data?.message || betError.message}`,
                        type: "error"
                    });
                    betProcessed = true;
                }
            }
        }

    } catch (e: any) {
        await db.collection("pinnacle_logs").add({
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `❌ Erro Crítico no Robô Automático: ${e.message}`,
            type: "error"
        });
    }
});
