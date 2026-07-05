import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";

const db = admin.firestore();

/**
 * Helper to get Betfair credentials from Firestore
 */
async function getBetfairConfig() {
    const doc = await db.collection("settings").doc("general").get();
    const data = doc.data();
    if (!data || !data.betfair || !data.betfair.app_key || !data.betfair.username || !data.betfair.password) {
        throw new Error("Credenciais da Betfair não configuradas no painel Admin.");
    }
    return data.betfair;
}

/**
 * Autentica na Betfair usando a conta Master e retorna o Session Token
 */
export const betfairLogin = onCall(async (request) => {
    // Apenas admin deveria chamar, ou se o bot for autônomo, não expor para os usuários.
    // Como é um MVP, vamos apenas verificar autenticação básica do Firebase.
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Acesso negado.");
    }

    try {
        const config = await getBetfairConfig();
        
        // Autenticação interativa básica da Betfair (Para contas sem 2FA)
        const params = new URLSearchParams();
        params.append("username", config.username);
        params.append("password", config.password);

        const response = await fetch("https://identitysso.betfair.com/api/login", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "X-Application": config.app_key,
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: params.toString()
        });

        if (!response.ok) {
            throw new Error(`Betfair login failed: ${response.status}`);
        }

        const data = await response.json();
        
        if (data.status !== "SUCCESS") {
            throw new Error(`Betfair erro: ${data.error}`);
        }

        return {
            success: true,
            sessionToken: data.token,
            message: "Conectado à Betfair com sucesso."
        };
    } catch (e: any) {
        console.error("Erro no Login Betfair:", e);
        throw new HttpsError("internal", e.message || "Erro de login na Betfair.");
    }
});

/**
 * Busca Catálogo de Mercados (Ex: Match Odds de um jogo)
 */
export const betfairGetMarkets = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Acesso negado.");

    const { sessionToken, eventId } = request.data;
    if (!sessionToken || !eventId) {
        throw new HttpsError("invalid-argument", "sessionToken e eventId são obrigatórios.");
    }

    try {
        const config = await getBetfairConfig();
        
        const payload = {
            filter: {
                eventIds: [eventId],
                marketTypes: ["MATCH_ODDS"]
            },
            maxResults: "1",
            marketProjection: ["RUNNER_DESCRIPTION", "MARKET_START_TIME"]
        };

        const response = await fetch("https://api.betfair.com/exchange/betting/rest/v1.0/listMarketCatalogue/", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-Application": config.app_key,
                "X-Authentication": sessionToken
            },
            body: JSON.stringify(payload)
        });

        const data = await response.json();
        return { success: true, markets: data };
    } catch (e: any) {
        console.error("Erro Betfair GetMarkets:", e);
        throw new HttpsError("internal", e.message || "Erro ao buscar mercados.");
    }
});

/**
 * Executa uma aposta (Order) na Betfair
 */
export const betfairPlaceOrder = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Acesso negado.");

    const { sessionToken, marketId, selectionId, side, price, size } = request.data;
    if (!sessionToken || !marketId || !selectionId || !side || !price || !size) {
        throw new HttpsError("invalid-argument", "Parâmetros de aposta incompletos.");
    }

    try {
        const config = await getBetfairConfig();

        const payload = {
            marketId: marketId,
            instructions: [
                {
                    selectionId: selectionId,
                    handicap: "0",
                    side: side, // "BACK" ou "LAY"
                    orderType: "LIMIT",
                    limitOrder: {
                        size: size.toString(), // Stake (R$)
                        price: price.toString(), // Odd solicitada
                        persistenceType: "LAPSE" // Cancela se não corresponder ao vivo
                    }
                }
            ]
        };

        const response = await fetch("https://api.betfair.com/exchange/betting/rest/v1.0/placeOrders/", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-Application": config.app_key,
                "X-Authentication": sessionToken
            },
            body: JSON.stringify(payload)
        });

        const data = await response.json();
        return { success: true, result: data };
    } catch (e: any) {
        console.error("Erro Betfair PlaceOrder:", e);
        throw new HttpsError("internal", e.message || "Erro ao colocar aposta.");
    }
});

/**
 * Busca o saldo da conta na Betfair (Account API)
 */
export const betfairGetBalance = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Acesso negado.");

    try {
        const config = await getBetfairConfig();
        
        // 1. Faz Login invisível
        const loginParams = new URLSearchParams();
        loginParams.append("username", config.username);
        loginParams.append("password", config.password);

        const loginResponse = await fetch("https://identitysso.betfair.com/api/login", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "X-Application": config.app_key,
                "Content-Type": "application/x-www-form-urlencoded"
            },
            body: loginParams.toString()
        });

        if (!loginResponse.ok) throw new Error("Falha no login invisível da Betfair");
        const loginData = await loginResponse.json();
        if (loginData.status !== "SUCCESS") throw new Error("Erro de credenciais no login invisível");

        const sessionToken = loginData.token;

        // 2. Busca o Saldo
        const response = await fetch("https://api.betfair.com/exchange/account/rest/v1.0/getAccountFunds/", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-Application": config.app_key,
                "X-Authentication": sessionToken
            },
            body: JSON.stringify({ wallet: "UK" }) // 'UK' é a carteira padrão de apostas
        });

        const data = await response.json();
        return { success: true, balance: data.availableToBetBalance };
    } catch (e: any) {
        console.error("Erro Betfair GetBalance:", e);
        throw new HttpsError("internal", e.message || "Erro ao buscar saldo.");
    }
});

/**
 * Função de IA: Analisa o contexto do jogo e decide se deve fazer uma aposta
 */
export const analyzeMatchAndBet = onCall(async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Acesso negado.");

    const { matchContext, marketId, selectionId, stakePercentage } = request.data;
    if (!matchContext || !marketId || !selectionId || !stakePercentage) {
        throw new HttpsError("invalid-argument", "matchContext, marketId, selectionId e stakePercentage são obrigatórios.");
    }

    try {
        const settingsDoc = await db.collection("settings").doc("general").get();
        const data = settingsDoc.data() || {};
        const geminiKey = data?.api_keys?.gemini || data?.gemini_api_key || data?.gemini_key || data?.gemini;
        
        if (!geminiKey) {
            throw new HttpsError("failed-precondition", "Chave de API do Gemini não configurada no banco de dados.");
        }

        const ai = new GoogleGenAI({ apiKey: geminiKey });

        const prompt = `Você é um Analista e Trader Esportivo Profissional operando na Betfair.
Você receberá o contexto atual de um jogo de futebol ao vivo. 
Sua missão é analisar os dados estatísticos (posse de bola, chutes a gol, cartões, tempo de jogo, placar) e decidir se há valor para uma entrada (Aposta).
Lembre-se que na Betfair você pode apostar a favor (BACK) ou contra (LAY).

Contexto da Partida:
"${matchContext}"

Retorne APENAS um objeto JSON válido (sem blocos de código Markdown como \`\`\`json), com as seguintes chaves exatas:
"apostar" (boolean indicando se encontrou valor na aposta),
"tipo" (string "BACK" ou "LAY" - obrigatório mesmo se apostar for false),
"justificativa" (string curta explicando o raciocínio em português),
"odd_sugerida" (número decimal com a odd ideal aproximada que você espera encontrar).`;

        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: prompt,
            config: {
                responseMimeType: "application/json",
            }
        });

        const jsonText = response.text || "{}";
        const aiDecision = JSON.parse(jsonText);

        if (aiDecision.apostar !== true && aiDecision.apostar !== false) {
             throw new Error("Formato de decisão gerado inválido pela IA.");
        }

        // Salva o Log no Firestore
        const logRef = db.collection("betfair_logs").doc();
        await logRef.set({
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            matchContext,
            marketId,
            selectionId,
            decision: aiDecision,
            status: aiDecision.apostar ? "PROCESSING_ORDER" : "REJECTED_BY_AI"
        });

        // Se a IA decidiu apostar, aciona a execução real
        let orderResult = null;
        if (aiDecision.apostar === true) {
            try {
                // Faz Login para pegar Session Token
                const config = await getBetfairConfig();
                const loginParams = new URLSearchParams();
                loginParams.append("username", config.username);
                loginParams.append("password", config.password);

                const loginResponse = await fetch("https://identitysso.betfair.com/api/login", {
                    method: "POST",
                    headers: {
                        "Accept": "application/json",
                        "X-Application": config.app_key,
                        "Content-Type": "application/x-www-form-urlencoded"
                    },
                    body: loginParams.toString()
                });

                if (!loginResponse.ok) throw new Error("Falha no login invisível da Betfair");
                const loginData = await loginResponse.json();
                if (loginData.status !== "SUCCESS") throw new Error("Erro de credenciais no login invisível");

                const sessionToken = loginData.token;

                // 2. Busca o Saldo Atual na Carteira para calcular o valor da Aposta (Stake)
                const balanceRes = await fetch("https://api.betfair.com/exchange/account/rest/v1.0/getAccountFunds/", {
                    method: "POST",
                    headers: {
                        "Accept": "application/json",
                        "Content-Type": "application/json",
                        "X-Application": config.app_key,
                        "X-Authentication": sessionToken
                    },
                    body: JSON.stringify({ wallet: "UK" })
                });
                const balanceData = await balanceRes.json();
                const availableBalance = Number(balanceData.availableToBetBalance) || 0;
                
                // Calcula a stake baseada na porcentagem da banca
                const percent = Number(stakePercentage);
                let calculatedStake = availableBalance * (percent / 100);
                
                // Garantir mínimo da Betfair que é $2 ou $5 reais dependendo da moeda. Assumindo 5.
                if (calculatedStake < 5) calculatedStake = 5;
                if (calculatedStake > availableBalance) calculatedStake = availableBalance;

                // Prepara Order
                const payload = {
                    marketId: marketId,
                    instructions: [
                        {
                            selectionId: selectionId,
                            handicap: "0",
                            side: aiDecision.tipo, // BACK ou LAY decidido pela IA
                            orderType: "LIMIT",
                            limitOrder: {
                                size: calculatedStake.toFixed(2), // Stake dinâmica baseada no saldo real da API
                                price: aiDecision.odd_sugerida.toString(), 
                                persistenceType: "LAPSE" 
                            }
                        }
                    ]
                };

                const orderRes = await fetch("https://api.betfair.com/exchange/betting/rest/v1.0/placeOrders/", {
                    method: "POST",
                    headers: {
                        "Accept": "application/json",
                        "Content-Type": "application/json",
                        "X-Application": config.app_key,
                        "X-Authentication": sessionToken
                    },
                    body: JSON.stringify(payload)
                });

                orderResult = await orderRes.json();
                
                await logRef.update({
                    status: "ORDER_PLACED",
                    orderResult: orderResult
                });

            } catch (err: any) {
                await logRef.update({
                    status: "ORDER_FAILED",
                    error: err.message
                });
                throw err;
            }
        }

        return { 
            success: true, 
            decision: aiDecision,
            orderResult
        };
    } catch (error: any) {
        console.error("Erro no Analista Gemini:", error);
        throw new HttpsError("internal", `Erro no analista Gemini: ${error.message}`);
    }
});
