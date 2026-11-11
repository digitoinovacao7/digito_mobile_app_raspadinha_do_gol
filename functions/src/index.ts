import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import axios from "axios";
import { generateGeminiContent } from "./gemini";

admin.initializeApp();

const db = admin.firestore();



/**
 * Registra o usuário no Firestore na primeira vez
 */
export const initializeUser = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);
    const doc = await userRef.get();
    
    if (!doc.exists) {
        await userRef.set({
            tokens: 100, // Bônus de boas-vindas
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            email: request.auth.token.email || null,
        });
        return { success: true, message: "Usuário inicializado com bônus.", tokens: 100 };
    }
    
    return { success: true, message: "Usuário já existe.", tokens: doc.data()?.tokens };
});

/**
 * Responde a um quiz ao vivo
 */
export const answerQuiz = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { quizId, answerId, fixtureId, matchName } = request.data;
    if (!quizId || answerId === undefined || !fixtureId || !matchName) {
        throw new HttpsError("invalid-argument", "Faltam parâmetros (quizId, answerId, fixtureId, matchName).");
    }

    const uid = request.auth.uid;
    const userQuizAttemptRef = db.collection("users").doc(uid).collection("quiz_attempts").doc(quizId);
    
    try {
        const settingsDoc = await db.collection("settings").doc("general").get();
        const economy = settingsDoc.data()?.economy || {};
        const quizReward = Number(economy.quiz_reward) || 250;

        const result = await db.runTransaction(async (t) => {
            const attemptDoc = await t.get(userQuizAttemptRef);
            if (attemptDoc.exists) {
                throw new HttpsError("already-exists", "Você já respondeu a este quiz.");
            }

            const quizRef = db.collection("quizzes").doc(quizId);
            const quizDoc = await t.get(quizRef);
            if (!quizDoc.exists) {
                throw new HttpsError("not-found", "Quiz não encontrado.");
            }

            const userRef = db.collection("users").doc(uid);
            const userDoc = await t.get(userRef);

            const quizData = quizDoc.data()!;
            if (!quizData.active) {
                throw new HttpsError("failed-precondition", "Este quiz já expirou.");
            }

            const isCorrect = quizData.correctIndex === answerId;
            const userData = userDoc.data() || {};
            const todayStr = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"
            const lastQuizDate = userData.last_quiz_date;
            const currentDailyAnswered = lastQuizDate === todayStr ? (userData.daily_quizzes_answered || 0) : 0;

            // Salva a tentativa para evitar que responda de novo
            t.set(userQuizAttemptRef, {
                answeredAt: admin.firestore.FieldValue.serverTimestamp(),
                isCorrect: isCorrect,
                answerId: answerId,
                fixtureId: fixtureId,
                matchName: matchName
            });

            t.set(userRef, {
                last_quiz_date: todayStr,
                daily_quizzes_answered: currentDailyAnswered + 1,
                tokens: isCorrect ? admin.firestore.FieldValue.increment(quizReward) : admin.firestore.FieldValue.increment(0),
                answered_quizzes_count: {
                    [fixtureId]: admin.firestore.FieldValue.increment(1)
                }
            }, { merge: true });

            if (isCorrect) {
                const transactionRef = db.collection("token_transactions").doc();
                t.set(transactionRef, {
                    uid: uid,
                    amount: quizReward,
                    type: "quiz_reward",
                    description: `Acerto no Quiz: ${matchName}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                const transactionRef = db.collection("token_transactions").doc();
                t.set(transactionRef, {
                    uid: uid,
                    amount: 0,
                    type: "quiz_failure",
                    description: `Erro no Quiz: ${matchName}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            return { isCorrect, quizReward, correctIndex: quizData.correctIndex };
        });

        return { 
            success: true, 
            isCorrect: result.isCorrect, 
            correctIndex: result.correctIndex,
            earnedTokens: result.isCorrect ? result.quizReward : 0 
        };
    } catch (e: any) {
        throw new HttpsError("internal", e.message || "Erro interno ao responder quiz.");
    }
});

/**
 * Joga a raspadinha
 */
export const playScratchcard = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const { useTokens } = request.data || {};

    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);

    try {
        const settingsDoc = await db.collection("settings").doc("general").get();
        const settingsData = settingsDoc.data() || {};
        const economy = settingsData.economy || {};
        const prizeRules = settingsData.prize_rules || {};

        const costPerScratch = Number(economy.scratchcard_token_cost) || 1000;
        const globalWinChancePercent = Number(prizeRules.global_win_chance) || 10;
        const globalWinChance = globalWinChancePercent / 100.0;

        const result = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "Usuário não encontrado.");
            }

            const userData = userDoc.data() || {};
            const userTokens = userData.tokens || 0;

            if (useTokens && userTokens < costPerScratch) {
                throw new HttpsError("failed-precondition", "Tokens insuficientes para jogar.");
            }

            // [CLEAN CODE] Regra do Firestore: TODAS as leituras devem ocorrer antes das escritas.
            const prizesSnapshot = await transaction.get(db.collection("prizes").where("active", "==", true));
            const activePrizes = prizesSnapshot.docs.filter((doc) => {
                const qty = doc.data().quantity;
                return qty === undefined || qty === null || Number(qty) < 0 || Number(qty) > 0;
            });

            // Motor de Probabilidade (RNG) simplificado:
            const rand = Math.random();
            let winCount = 0;
            let resultMessage = "Quase! Tente novamente.";
            let prizeType = "none";
            let wonTokens = 0;
            let prizeLink: string | null = null;
            let prizeName: string | null = null;
            let wonPixAmount = 0;
            let selectedPrizeDoc: admin.firestore.QueryDocumentSnapshot | null = null;

            if (rand < globalWinChance) {
                winCount = 3;
                
                if (activePrizes.length > 0) {
                    selectedPrizeDoc = activePrizes[Math.floor(Math.random() * activePrizes.length)];
                    const prizeData = selectedPrizeDoc.data();
                    
                    prizeType = prizeData.type || "produto";
                    prizeName = prizeData.name || "Prêmio Surpresa";
                    prizeLink = prizeData.prize_link || null;
                    
                    if (prizeType === "tokens") {
                        wonTokens = Number(prizeData.value) || Number(prizeData.amount) || 1000;
                        resultMessage = `GOLAÇO! Você ganhou ${wonTokens} Tokens!`;
                    } else {
                        // Todos os outros prêmios são físicos / oficiais
                        prizeType = "produto";
                        resultMessage = `GOLAÇO! Você ganhou: ${prizeName}!`;
                    }
                } else {
                    // Fallback se não tiver prêmio ativo
                    wonTokens = 1000;
                    prizeType = "tokens";
                    prizeName = "1000 Tokens";
                    resultMessage = `GOLAÇO! Você ganhou 1000 Tokens!`;
                }
            } else if (rand < globalWinChance + 0.15) {
                // Na trave logic: +15% chance of getting 2 balls
                winCount = 2;
                wonTokens = 100;
                resultMessage = `Na Trave! Você quase conseguiu e ganhou 100 Tokens de consolação!`;
                prizeType = "tokens";
                prizeName = "100 Tokens (Na Trave)";
            } else {
                winCount = Math.floor(Math.random() * 2);
            }

            // Gerar o grid
            const gridBalls: boolean[] = Array(9).fill(false);
            let placed = 0;
            while(placed < winCount) {
                const idx = Math.floor(Math.random() * 9);
                if (!gridBalls[idx]) {
                    gridBalls[idx] = true;
                    placed++;
                }
            }

            // Decrementar estoque do prêmio se aplicável e fechar o prêmio se zerar
            if (selectedPrizeDoc) {
                const currentQty = Number(selectedPrizeDoc.data().quantity ?? -1);
                if (currentQty > 0) {
                    const newQty = currentQty - 1;
                    const prizeUpdates: any = { quantity: newQty };
                    if (newQty === 0) {
                        prizeUpdates.active = false;
                        prizeUpdates.closedAt = admin.firestore.FieldValue.serverTimestamp();
                    }
                    transaction.update(selectedPrizeDoc.ref, prizeUpdates);
                }
            }

            if (useTokens || wonTokens > 0) {
                const deduction = useTokens ? costPerScratch : 0;
                const updates: any = {
                    tokens: userTokens - deduction + wonTokens
                };
                transaction.update(userRef, updates);
            }

            // Registrar transações no extrato de tokens
            if (useTokens) {
                const debitTxRef = db.collection("token_transactions").doc();
                transaction.set(debitTxRef, {
                    uid: uid,
                    amount: -costPerScratch,
                    type: "scratch_purchase",
                    description: "Compra de Raspadinha com Tokens",
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            if (wonTokens > 0) {
                const creditTxRef = db.collection("token_transactions").doc();
                transaction.set(creditTxRef, {
                    uid: uid,
                    amount: wonTokens,
                    type: "scratch_reward",
                    description: winCount === 3 ? `Prêmio na Raspadinha (+${wonTokens} Tokens)` : `Bônus Na Trave (+${wonTokens} Tokens)`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            if (winCount === 3 && selectedPrizeDoc && prizeType !== "tokens") {
                const redemptionRef = db.collection("redemptions").doc();
                transaction.set(redemptionRef, {
                    uid: uid,
                    userId: uid,
                    userName: userData.name || "Torcedor",
                    userEmail: userData.email || "",
                    userPhone: userData.phone || "",
                    userCpf: userData.cpf || "",
                    prizeId: selectedPrizeDoc.id,
                    prizeName: prizeName,
                    type: prizeType,
                    cost: 0,
                    source: "scratchcard",
                    prizeLink: prizeLink,
                    status: "pendente",
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            const historyRef = db.collection("scratch_history").doc();
            transaction.set(historyRef, {
                uid: uid,
                date: admin.firestore.FieldValue.serverTimestamp(),
                winCount: winCount,
                prizeType: prizeType,
                prizeName: prizeName,
                prizeLink: prizeLink,
                wonTokens: wonTokens,
                wonPixAmount: wonPixAmount,
                cost: useTokens ? costPerScratch : 0
            });

            return { 
                success: true, 
                gridBalls, 
                winCount, 
                message: resultMessage,
                prizeType,
                prizeName,
                wonTokens,
                wonPixAmount,
                prizeLink
            };
        });

        return result;
    } catch (error: any) {
        throw new HttpsError("internal", error.message || "Erro interno.");
    }
});

/**
 * Gera um novo quiz usando a API do Gemini
 */
const FALLBACK_FOOTBALL_QUIZZES = [
    {
        question: "Qual país venceu a Copa do Mundo de 2022 no Catar?",
        options: ["França", "Argentina", "Brasil", "Croácia"],
        correctIndex: 1
    },
    {
        question: "Quem é o maior artilheiro da história da Seleção Brasileira em jogos oficiais?",
        options: ["Ronaldo Fenômeno", "Pelé", "Neymar Jr", "Romário"],
        correctIndex: 2
    },
    {
        question: "Qual clube conquistou a Copa Libertadores da América em 2023?",
        options: ["Palmeiras", "Boca Juniors", "Fluminense", "Flamengo"],
        correctIndex: 2
    },
    {
        question: "Em que ano o Brasil conquistou o seu primeiro título mundial de futebol?",
        options: ["1950", "1958", "1962", "1970"],
        correctIndex: 1
    },
    {
        question: "Qual jogador é conhecido mundialmente como o 'Rei do Futebol'?",
        options: ["Garrincha", "Pelé", "Zico", "Maradona"],
        correctIndex: 1
    },
    {
        question: "Qual clube tem mais títulos da UEFA Champions League?",
        options: ["Milan", "Bayern de Munique", "Liverpool", "Real Madrid"],
        correctIndex: 3
    },
    {
        question: "Quantas Copas do Mundo a Seleção Brasileira possui até hoje?",
        options: ["4", "5", "6", "3"],
        correctIndex: 1
    },
    {
        question: "Qual estádio é considerado o 'Templo do Futebol' brasileiro?",
        options: ["Morumbi", "Maracanã", "Mineirão", "Neo Química Arena"],
        correctIndex: 1
    },
    {
        question: "Qual seleção foi campeã da Eurocopa 2024?",
        options: ["Inglaterra", "Espanha", "França", "Alemanha"],
        correctIndex: 1
    },
    {
        question: "Quem marcou os 2 gols do título do Brasil na final da Copa do Mundo de 2002 contra a Alemanha?",
        options: ["Rivaldo", "Ronaldinho Gaúcho", "Ronaldo Fenômeno", "Cafu"],
        correctIndex: 2
    },
    {
        question: "Qual clube brasileiro venceu o primeiro Mundial de Clubes da FIFA em 2000 no Brasil?",
        options: ["Vasco da Gama", "Corinthians", "São Paulo", "Internacional"],
        correctIndex: 1
    },
    {
        question: "Quem é o jogador com mais Bolas de Ouro (Ballon d'Or) na história?",
        options: ["Cristiano Ronaldo", "Lionel Messi", "Johan Cruyff", "Michel Platini"],
        correctIndex: 1
    },
    {
        question: "Qual time conquistou a Copa do Brasil de 2024?",
        options: ["Atlético Mineiro", "Flamengo", "Corinthians", "Grêmio"],
        correctIndex: 1
    },
    {
        question: "Em qual clube brasileiro o atacante Vinícius Júnior foi revelado?",
        options: ["Santos", "Flamengo", "São Paulo", "Fluminense"],
        correctIndex: 1
    },
    {
        question: "Quantas Copas do Mundo Pelé conquistou como jogador da Seleção Brasileira?",
        options: ["2", "3", "4", "1"],
        correctIndex: 1
    }
];

export const generateQuiz = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }

    const uid = request.auth.uid;

    const { context } = request.data;
    if (!context) {
        throw new HttpsError("invalid-argument", "Contexto não fornecido.");
    }

    // Busca a API key do painel (salva no Firestore em settings)
    const settingsDoc = await db.collection("settings").doc("general").get();
    const data = settingsDoc.data() || {};
    const geminiKey = data?.api_keys?.gemini || data?.gemini_api_key || data?.gemini_key || data?.gemini;
    const dailyQuizLimit = Number(data?.economy?.daily_quiz_limit) || 3;

    // Verifica limite diário do usuário
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    const userData = userDoc.data() || {};
    const todayStr = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"
    const lastQuizDate = userData.last_quiz_date;
    const dailyQuizzesAnswered = lastQuizDate === todayStr ? (userData.daily_quizzes_answered || 0) : 0;
    const isAdmin = userData.role === "admin";
    const isUnlimited = dailyQuizLimit <= 0;

    if (!isAdmin && !isUnlimited && dailyQuizzesAnswered >= dailyQuizLimit) {
        throw new HttpsError("resource-exhausted", `Você atingiu o limite de ${dailyQuizLimit} quizzes diários. Volte amanhã!`);
    }

    let quizData: { question: string; options: string[]; correctIndex: number } | null = null;

    if (geminiKey) {
        const prompt = `Você é o Narrador Esportivo Oficial e Especialista em História do Futebol do aplicativo Raspadinha do Gol.
Gere uma pergunta de múltipla escolha instigante, precisa e divertida sobre futebol.
O contexto de inspiração para esta rodada é: "${context}".

A pergunta deve testar o conhecimento do torcedor de forma inteligente e ter exatamente 4 alternativas curtas (A, B, C e D).
Retorne APENAS um objeto JSON válido (sem marcações Markdown como \`\`\`json), contendo exatamente as chaves:
"question" (string), "options" (array com 4 strings), e "correctIndex" (número inteiro de 0 a 3 indicando a alternativa correta).`;

        try {
            const response = await generateGeminiContent(geminiKey, prompt);

            let jsonText = response.text || "{}";
            const jsonMatch = jsonText.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                jsonText = jsonMatch[0];
            }
            const parsed = JSON.parse(jsonText);

            if (parsed.question && Array.isArray(parsed.options) && parsed.options.length === 4 && parsed.correctIndex !== undefined) {
                quizData = {
                    question: parsed.question,
                    options: parsed.options,
                    correctIndex: Number(parsed.correctIndex)
                };
            }
        } catch (error: any) {
            console.warn("Gemini falhou ou cota excedida (usando fallback de quiz futebol):", error?.message);
        }
    }

    // Se a IA não estiver configurada ou falhar (ex: 402 quota), usa o banco oficial de perguntas
    if (!quizData) {
        const randomIndex = Math.floor(Math.random() * FALLBACK_FOOTBALL_QUIZZES.length);
        quizData = FALLBACK_FOOTBALL_QUIZZES[randomIndex];
    }

    // Salvar no Firestore para validar na resposta
    const quizRef = db.collection("quizzes").doc();
    await quizRef.set({
        question: quizData.question,
        options: quizData.options,
        correctIndex: quizData.correctIndex,
        context: context,
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Retorna pro cliente
    return { 
        success: true, 
        quizId: quizRef.id, 
        question: quizData.question, 
        options: quizData.options 
    };
});

/**
 * Solicita o OTP para saque via PIX (Descontinuado)
 */
export const requestPixOtp = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    throw new HttpsError(
        "failed-precondition", 
        "Os saques em dinheiro/PIX foram substituídos exclusivamente por prêmios físicos oficiais (camisas, bolas e produtos parceiros) entregues no seu endereço."
    );
});

/**
 * Rotina Diária: Enviar alerta via WhatsApp para usuários inativos com saldo
 * Roda todo dia às 10:00 da manhã.
 */
export const retentionAlertDaily = onSchedule("0 10 * * *", async (event) => {
    const settingsDoc = await db.collection("settings").doc("general").get();
    const zApiUrl = settingsDoc.data()?.api_keys?.z_api;
    if (!zApiUrl) {
        console.warn("Z-API não configurada. Abortando alerta de retenção.");
        return;
    }
    
    const today = new Date().toISOString().split("T")[0];
    
    // Busca usuários que aceitaram alertas no zap e tem tokens guardados
    const snapshot = await db.collection("users")
        .where("wants_whatsapp_notifications", "==", true)
        .where("tokens", ">=", 1000)
        .get();

    let count = 0;
    const targetUrl = zApiUrl.endsWith("/") ? `${zApiUrl}send-text` : `${zApiUrl}/send-text`;
    
    for (const doc of snapshot.docs) {
        const userData = doc.data();
        if (!userData.phone || userData.phone.trim() === "") continue;
        
        // Se o usuário já jogou o quiz hoje, ele já está ativo, então pulamos
        if ((userData.last_quiz_date || userData.lastQuizDate) === today) {
            continue;
        }

        const cleanPhone = userData.phone.replace(/\D/g, "");
        const msg = `Fala campeão! ⚽\n\nVocê tem *${userData.tokens} Tokens* acumulados dando sopa no *Raspadinha do Gol*!\n\nEntre no aplicativo agora, jogue a raspadinha e concorra a camisas oficiais e prêmios na hora. A sorte está do seu lado? 🍀`;
        
        try {
            await fetch(targetUrl, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    phone: `55${cleanPhone}`,
                    message: msg
                })
            });
            count++;
            
            // Pausa de 2 segundos entre mensagens para evitar bloqueios de SPAM no Z-API/WhatsApp
            await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (err) {
            console.error(`Erro ao enviar Z-API para ${userData.phone}:`, err);
        }
    }
    
    console.log(`Rotina diária concluída. ${count} alertas de retenção enviados via Z-API.`);
});

/**
 * Valida o OTP e debita os tokens para o Saque PIX (Descontinuado)
 */
export const validatePixOtpAndWithdraw = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    throw new HttpsError(
        "failed-precondition", 
        "Os saques em dinheiro/PIX foram substituídos exclusivamente por prêmios físicos oficiais (camisas, bolas e produtos parceiros) entregues no seu endereço."
    );
});

/**
 * Proxy para chamadas do Football-Data.org contornando CORS em ambientes Web
 */
export const proxyFootballData = onCall(async (_request) => {
    return { success: false, message: "Football-Data.org foi descontinuado. O sistema utiliza agora exclusivamente a API-Football." };
});

/**
 * Retorna os jogos ao vivo e do dia da API-Football / Football-Data para exibição pública na Landing Page
 */
export const getPublicMatches = onRequest({
    cors: true,
    region: "southamerica-east1",
}, async (_req, res) => {
    try {
        const settingsDoc = await db.collection("settings").doc("general").get();
        const data = settingsDoc.data() || {};
        const keys = data.api_keys || {};
        const apiFootballKey = keys.api_football || data.api_football_key || data.api_football;

        const now = new Date();
        const today = new Intl.DateTimeFormat("en-CA", {
            timeZone: "America/Sao_Paulo",
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
        }).format(now);

        let formattedMatches: any[] = [];
        let usedSource = "API-Football";

        const tryApiFootball = async (): Promise<any[]> => {
            if (!apiFootballKey) return [];
            const apiUrl = `https://v3.football.api-sports.io/fixtures?date=${today}&timezone=America/Sao_Paulo`;
            const apiResponse = await fetch(apiUrl, {
                headers: { "x-apisports-key": apiFootballKey },
            });
            if (!apiResponse.ok) return [];
            const apiData: any = await apiResponse.json();
            if (apiData.errors && Object.keys(apiData.errors).length > 0) return [];

            const matchesList = Array.isArray(apiData.response) ? apiData.response : [];
            const liveStatuses = ["1H", "2H", "HT", "ET", "BT", "P", "SUSP", "INT", "LIVE"];
            const finishedStatuses = ["FT", "AET", "PEN"];

            matchesList.sort((a: any, b: any) => {
                const aStatus = a.fixture?.status?.short || "";
                const bStatus = b.fixture?.status?.short || "";
                const rank = (status: string) => liveStatuses.includes(status) ? 0 :
                    finishedStatuses.includes(status) ? 2 : 1;
                const rankDifference = rank(aStatus) - rank(bStatus);
                return rankDifference ||
                    new Date(a.fixture?.date || 0).getTime() - new Date(b.fixture?.date || 0).getTime();
            });

            return matchesList.slice(0, 6).map((item: any) => {
                const fix = item.fixture || {};
                const league = item.league || {};
                const teams = item.teams || {};
                const goals = item.goals || {};
                const score = item.score || {};
                const statusShort = fix.status?.short || "";
                const elapsed = fix.status?.elapsed;
                const isLive = liveStatuses.includes(statusShort);
                const isFinished = finishedStatuses.includes(statusShort);

                let statusText = "AGENDADO";
                if (isLive) {
                    statusText = statusShort === "HT" ? "INTERVALO" :
                        `${fix.status?.long || "AO VIVO"}${elapsed ? ` (${elapsed}')` : ""}`;
                } else if (isFinished) {
                    statusText = "ENCERRADO";
                } else if (fix.date) {
                    const matchDate = new Date(fix.date);
                    statusText = matchDate.toLocaleTimeString("pt-BR", {
                        timeZone: "America/Sao_Paulo",
                        hour: "2-digit",
                        minute: "2-digit",
                    });
                }

                return {
                    id: fix.id,
                    league: league.name || "Futebol",
                    leagueLogo: league.logo || "",
                    country: league.country || "",
                    round: league.round || "",
                    homeTeam: teams.home?.name || "Casa",
                    homeLogo: teams.home?.logo || "",
                    awayTeam: teams.away?.name || "Visitante",
                    awayLogo: teams.away?.logo || "",
                    score: goals.home == null || goals.away == null ?
                        "—" : `${goals.home} - ${goals.away}`,
                    halfTimeScore: score.halftime?.home == null || score.halftime?.away == null ?
                        null : `${score.halftime.home} - ${score.halftime.away}`,
                    status: statusText,
                    statusLong: fix.status?.long || "",
                    isLive,
                    isFinished,
                    kickoff: fix.date || null,
                    venue: fix.venue?.name || "",
                    city: fix.venue?.city || "",
                    referee: fix.referee || "",
                };
            });
        };

        formattedMatches = await tryApiFootball();

        // Vitrine de jogos em destaque caso a agenda do dia esteja em janela de atualização
        if (formattedMatches.length === 0) {
            usedSource = "Showcase";
            formattedMatches = [
                {
                    id: "featured-1",
                    league: "Brasileirão Série A",
                    leagueLogo: "https://crests.football-data.org/bsa.png",
                    country: "Brasil",
                    round: "Rodada Principal",
                    homeTeam: "Flamengo",
                    homeLogo: "https://crests.football-data.org/1783.png",
                    awayTeam: "Palmeiras",
                    awayLogo: "https://crests.football-data.org/1769.png",
                    score: "2 - 1",
                    halfTimeScore: "1 - 1",
                    status: "AO VIVO • RASPADINHA ATIVA",
                    statusLong: "Acompanhe no App",
                    isLive: true,
                    isFinished: false,
                    venue: "Maracanã",
                    city: "Rio de Janeiro",
                },
                {
                    id: "featured-2",
                    league: "Brasileirão Série A",
                    leagueLogo: "https://crests.football-data.org/bsa.png",
                    country: "Brasil",
                    round: "Rodada Principal",
                    homeTeam: "Corinthians",
                    homeLogo: "https://crests.football-data.org/1779.png",
                    awayTeam: "São Paulo",
                    awayLogo: "https://crests.football-data.org/1776.png",
                    score: "1 - 1",
                    halfTimeScore: "1 - 0",
                    status: "INTERVALO • QUIZ ATIVO",
                    statusLong: "Acompanhe no App",
                    isLive: true,
                    isFinished: false,
                    venue: "Neo Química Arena",
                    city: "São Paulo",
                },
                {
                    id: "featured-3",
                    league: "Champions League",
                    leagueLogo: "https://crests.football-data.org/CL.png",
                    country: "Europa",
                    round: "Fase Principal",
                    homeTeam: "Real Madrid",
                    homeLogo: "https://crests.football-data.org/86.png",
                    awayTeam: "Manchester City",
                    awayLogo: "https://crests.football-data.org/65.png",
                    score: "—",
                    halfTimeScore: null,
                    status: "HOJE • 16:00",
                    statusLong: "Agendado",
                    isLive: false,
                    isFinished: false,
                    venue: "Santiago Bernabéu",
                    city: "Madrid",
                },
            ];
        }

        res.set("Cache-Control", "public, max-age=60, s-maxage=60");
        res.json({
            success: true,
            source: usedSource,
            date: today,
            matches: formattedMatches,
        });
    } catch (e: any) {
        console.error("Erro ao buscar jogos públicos:", e);
        res.status(200).json({
            success: true,
            source: "Showcase",
            matches: [],
        });
    }
});

export const pollLiveMatches = onSchedule("* * * * *", async (event) => {
    // 1. Get distinct watching_fixture_ids from users
    const usersSnap = await db.collection("users").where("watching_fixture_id", ">", 0).get();
    const activeFixtures = new Set<number>();
    usersSnap.forEach(doc => {
        const fixId = doc.data().watching_fixture_id;
        if (fixId) activeFixtures.add(fixId);
    });

    // 2. Adiciona jogos de Bolões em aberto para garantir que serão encerrados mesmo se ninguém estiver assistindo
    const openBoloesSnap = await db.collection("boloes").where("status", "==", "open").get();
    openBoloesSnap.forEach(doc => {
        const fixId = doc.data().fixtureId;
        if (fixId) activeFixtures.add(Number(fixId));
    });

    if (activeFixtures.size === 0) {
        return;
    }

    const settingsDoc = await db.collection("settings").doc("general").get();
    const data = settingsDoc.data() || {};
    const keys = data.api_keys || {};
    const apiFootballKey = keys.api_football || data.api_football_key || data.api_football;

    if (!apiFootballKey) {
        return;
    }

    for (const fixtureId of activeFixtures) {
        try {
            let homeScore = 0;
            let awayScore = 0;
            let status = '';
            let homeTeamName = '';
            let awayTeamName = '';

            const url = `https://v3.football.api-sports.io/fixtures?id=${fixtureId}`;
            const fetchResponse = await fetch(url, {
                headers: { "x-apisports-key": apiFootballKey }
            });
            if (!fetchResponse.ok) continue;

            const matchData = await fetchResponse.json();
            if (!matchData.response || matchData.response.length === 0) continue;

            const fix = matchData.response[0];
            homeScore = fix.goals?.home ?? 0;
            awayScore = fix.goals?.away ?? 0;
            status = fix.fixture?.status?.short ?? '';
            homeTeamName = fix.teams?.home?.name ?? '';
            awayTeamName = fix.teams?.away?.name ?? '';

            const stateRef = db.collection("matches_state").doc(fixtureId.toString());
            const stateDoc = await stateRef.get();
            const prevState = stateDoc.data();

            let shouldNotifyGoal = false;
            let shouldNotifyWhistle = false;

            if (prevState) {
                const prevHome = prevState.homeScore ?? 0;
                const prevAway = prevState.awayScore ?? 0;
                if (homeScore > prevHome || awayScore > prevAway) {
                    shouldNotifyGoal = true;
                }
                
                // HT logic
                if (prevState.status !== 'HT' && status === 'HT') {
                    shouldNotifyWhistle = true;
                }
            }

            if (shouldNotifyGoal || shouldNotifyWhistle) {
                const soundFile = shouldNotifyGoal ? "goal.wav" : "whistle.wav";
                const channelId = shouldNotifyGoal ? "match_goal" : "match_whistle";
                const title = shouldNotifyGoal ? "GOL!" : "Fim do Primeiro Tempo";
                const body = `${homeTeamName} ${homeScore} x ${awayScore} ${awayTeamName}`;

                try {
                    await admin.messaging().send({
                        topic: `match_${fixtureId}`,
                        notification: {
                            title: title,
                            body: body,
                        },
                        android: {
                            notification: {
                                sound: soundFile,
                                channelId: channelId
                            }
                        },
                        apns: {
                            payload: {
                                aps: {
                                    sound: soundFile
                                }
                            }
                        }
                    });
                } catch (pushErr) {
                    console.error("Erro ao enviar push:", pushErr);
                }

                if (shouldNotifyGoal) {
                    const isHomeGoal = homeScore > (prevState?.homeScore ?? 0);
                    const scoringTeam = isHomeGoal ? homeTeamName : awayTeamName;

                    // 1. Gravar na collection 'recent_goals' para o app mobile tocar o som goal.wav ao vivo
                    await db.collection("recent_goals").add({
                        fixtureId: fixtureId,
                        scoringTeam: scoringTeam,
                        homeTeamName: homeTeamName,
                        awayTeamName: awayTeamName,
                        homeScore: homeScore,
                        awayScore: awayScore,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    }).catch(e => console.error("Erro ao gravar recent_goals:", e));

                    // 2. Disparar WhatsApp para os torcedores que têm este time como favorito
                    try {
                        const settingsDoc = await db.collection("settings").doc("general").get();
                        const zApiUrl = settingsDoc.data()?.api_keys?.z_api;
                        if (zApiUrl && scoringTeam) {
                            const targetUrl = zApiUrl.endsWith("/") ? `${zApiUrl}send-text` : `${zApiUrl}/send-text`;
                            const usersSnap = await db.collection("users").get();
                            const scoringNorm = scoringTeam.toLowerCase().trim();

                            for (const uDoc of usersSnap.docs) {
                                const uData = uDoc.data();
                                const favTeam = (uData.favorite_team_name || uData.favoriteTeamName || "").toLowerCase().trim();
                                if (!favTeam || !uData.phone) continue;

                                const isFan = scoringNorm.includes(favTeam) || favTeam.includes(scoringNorm) ||
                                    (favTeam.includes("galo") && (scoringNorm.includes("atlético") || scoringNorm.includes("atletico"))) ||
                                    (favTeam.includes("mengão") && scoringNorm.includes("flamengo")) ||
                                    (favTeam.includes("timão") && scoringNorm.includes("corinthians")) ||
                                    (favTeam.includes("palestra") && scoringNorm.includes("palmeiras")) ||
                                    (favTeam.includes("peixe") && scoringNorm.includes("santos")) ||
                                    (favTeam.includes("raposa") && scoringNorm.includes("cruzeiro")) ||
                                    (favTeam.includes("tricolor") && (scoringNorm.includes("são paulo") || scoringNorm.includes("sao paulo") || scoringNorm.includes("grêmio") || scoringNorm.includes("gremio") || scoringNorm.includes("fluminense") || scoringNorm.includes("bahia")));

                                if (isFan) {
                                    const cleanPhone = uData.phone.replace(/\D/g, "");
                                    const goalMsg = `⚽ *GOOOOOOOL DO ${scoringTeam.toUpperCase()}!* 💥🔥\n\nFala ${uData.name || 'Torcedor'}! O seu time do coração acabou de marcar!\n\nPlacar ao vivo: *${homeTeamName} ${homeScore} x ${awayScore} ${awayTeamName}*\n\nAbra o *Raspadinha do Gol* agora para raspar sua cartela e concorrer a prêmios na hora! 🍀`;

                                    await fetch(targetUrl, {
                                        method: "POST",
                                        headers: { "Content-Type": "application/json" },
                                        body: JSON.stringify({
                                            phone: `55${cleanPhone}`,
                                            message: goalMsg
                                        })
                                    }).catch(err => console.error(`Erro ao enviar Z-API para ${cleanPhone}:`, err));

                                    await new Promise(r => setTimeout(r, 1000));
                                }
                            }
                        }
                    } catch (zErr) {
                        console.error("Erro na notificação de gol via WhatsApp:", zErr);
                    }
                }
            }

            await stateRef.set({
                homeScore,
                awayScore,
                status,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            // Lógica de Encerramento Automático do Bolão
            const validFinishedStatuses = ["FT", "AET", "PEN", "FINISHED"];
            if (validFinishedStatuses.includes(status)) {
                const boloesDaPartida = openBoloesSnap.docs.filter(doc => Number(doc.data().fixtureId) === fixtureId);
                
                for (const bolaoDoc of boloesDaPartida) {
                    const bData = bolaoDoc.data();
                    if (bData.isProcessing) continue;
                    await bolaoDoc.ref.update({ isProcessing: true });
                    
                    try {
                        await db.runTransaction(async (t) => {
                            // [REGRA FIRESTORE] Todas as leituras (t.get) DEVEM vir antes de qualquer escrita (t.update)
                            const bolaoT = await t.get(bolaoDoc.ref);
                            const bDataT = bolaoT.data()!;
                            if (bDataT.status === "completed") return;

                            const participantsSnap = await t.get(bolaoDoc.ref.collection("participants"));
                            const entryFeeStr = (bDataT.entryFee || "0").toString().replace(",", ".");
                            const entryFeeNum = parseFloat(entryFeeStr) || 0;
                            const isFreeBolao = entryFeeNum <= 0;

                            const winners: string[] = [];
                            let confirmedCount = 0;

                            participantsSnap.forEach((p: any) => {
                                const pData = p.data();
                                const isPaymentOk = isFreeBolao || pData.paymentStatus === "approved";
                                if (isPaymentOk) {
                                    confirmedCount++;
                                    if (pData.homeScore === homeScore && pData.awayScore === awayScore) {
                                        winners.push(p.id);
                                    }
                                }
                            });
        
                            const totalPot = confirmedCount * entryFeeNum;
        
                            const pFeePerc = bDataT.platformFee || 10;
                            const cFeePerc = bDataT.creatorFee || 15;
        
                            const platformFeeAmount = totalPot * (pFeePerc / 100);
                            const creatorFeeAmount = totalPot * (cFeePerc / 100);
                            const winnerPot = totalPot - platformFeeAmount - creatorFeeAmount;
        
                            // Agora executamos as escritas do encerramento do bolão
                            // O app não custodia dinheiro: os participantes pagam direto ao organizador via Pix,
                            // e o organizador repassa o prêmio diretamente aos vencedores.
                            t.update(bolaoDoc.ref, {
                                status: "completed",
                                finalHomeScore: homeScore,
                                finalAwayScore: awayScore,
                                winners: winners,
                                winnerCount: winners.length,
                                winnerPot: winnerPot,
                                creatorCommissionAmount: creatorFeeAmount,
                                platformFeeAmount: platformFeeAmount,
                                isProcessing: false,
                                completedAt: admin.firestore.FieldValue.serverTimestamp()
                            });
                        });
                        console.log(`Bolão ${bolaoDoc.id} encerrado com sucesso.`);

                        // 3. Notificar o Anfitrião/Organizador via WhatsApp sobre os Vencedores
                        try {
                            const updatedBolaoSnap = await bolaoDoc.ref.get();
                            const bDataCompleted = updatedBolaoSnap.data();
                            const creatorId = bDataCompleted?.creatorId;

                            if (creatorId && creatorId !== "anonymous") {
                                const creatorDoc = await db.collection("users").doc(creatorId).get();
                                const creatorData = creatorDoc.data();
                                const creatorPhone = creatorData?.phone;

                                if (creatorPhone) {
                                    const settingsDoc = await db.collection("settings").doc("general").get();
                                    const zApiUrl = settingsDoc.data()?.api_keys?.z_api;

                                    if (zApiUrl) {
                                        const targetUrl = zApiUrl.endsWith("/") ? `${zApiUrl}send-text` : `${zApiUrl}/send-text`;
                                        const cleanPhone = creatorPhone.replace(/\D/g, "");

                                        // Busca nomes dos vencedores
                                        const winnersList: string[] = [];
                                        const winnersIds: string[] = bDataCompleted?.winners || [];
                                        const winnerPotAmount = Number(bDataCompleted?.winnerPot) || 0;
                                        const eachPrize = winnersIds.length > 0 ? (winnerPotAmount / winnersIds.length).toFixed(2).replace(".", ",") : "0,00";

                                        if (winnersIds.length > 0) {
                                            for (const wId of winnersIds) {
                                                const pDoc = await bolaoDoc.ref.collection("participants").doc(wId).get();
                                                const pName = pDoc.data()?.userName || "Participante";
                                                winnersList.push(`• *${pName}* (Leva R$ ${eachPrize})`);
                                            }
                                        }

                                        const bolaoTitle = bDataCompleted?.name || "Bolão do Gol";
                                        const matchName = bDataCompleted?.matchTeams || `${homeTeamName} x ${awayTeamName}`;
                                        const commissionStr = (Number(bDataCompleted?.creatorCommissionAmount) || 0).toFixed(2).replace(".", ",");
                                        const winnerPotStr = winnerPotAmount.toFixed(2).replace(".", ",");

                                        let winnersText = "";
                                        if (winnersIds.length === 0) {
                                            winnersText = "⚠️ *Ninguém cravou o placar exato!* O pote acumulou ou fica para o próximo bolão.";
                                        } else {
                                            winnersText = `🎯 *Quem Cravou o Placar (${winnersIds.length}):*\n${winnersList.join("\n")}`;
                                        }

                                        const message = `🏆 *SEU BOLÃO FOI FINALIZADO!* ⚽\n\n` +
                                            `Olá, *${creatorData?.name || 'Organizador'}*! A partida acabou e o resultado do seu bolão está pronto!\n\n` +
                                            `📋 *Bolão:* ${bolaoTitle}\n` +
                                            `⚔️ *Partida:* ${matchName}\n` +
                                            `🔢 *Placar Final Oficial:* ${homeScore} x ${awayScore}\n` +
                                            `💰 *Pote dos Vencedores:* R$ ${winnerPotStr}\n` +
                                            `🤝 *Sua Comissão:* R$ ${commissionStr}\n\n` +
                                            `${winnersText}\n\n` +
                                            `📲 Abra o aplicativo *Raspadinha do Gol* para conferir o ranking detalhado e fazer o repasse via Pix aos ganhadores! Parabéns pelo bolão! 👏🔥`;

                                        await fetch(targetUrl, {
                                            method: "POST",
                                            headers: { "Content-Type": "application/json" },
                                            body: JSON.stringify({
                                                phone: `55${cleanPhone}`,
                                                message: message
                                            })
                                        });
                                        console.log(`WhatsApp de encerramento do bolão enviado com sucesso para ${cleanPhone}`);
                                    }
                                }
                            }
                        } catch (notifyErr) {
                            console.error(`Erro ao notificar anfitrião do bolão ${bolaoDoc.id} no WhatsApp:`, notifyErr);
                        }
                    } catch (e) {
                        console.error(`Erro no bolão ${bolaoDoc.id}:`, e);
                        await bolaoDoc.ref.update({ isProcessing: false });
                    }
                }
            }

        } catch (e) {
            console.error(`Erro ao atualizar partida ${fixtureId}:`, e);
        }
    }
});


export * from "./football_image_proxy";

const SHOPISA_API_URL = "https://getprizeproducts-qvpkvterkq-rj.a.run.app";
const SHOPISA_REWARD_URL = "https://generatereward-qvpkvterkq-rj.a.run.app";
const SHOPISA_SECRET = "SHOPISA_GAME_SECRET_2026";

/**
 * Sincroniza prêmios da Shopisa marcados como `isPrize == true` para o Firestore do Raspadinha do Gol
 */
export const syncShopisaPrizes = onCall({
    region: "southamerica-east1",
    cors: true,
    memory: "512MiB"
}, async (request) => {
    // Permite chamada autenticada (idealmente admin)
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    try {
        console.log("Buscando produtos premiados na Shopisa...");
        const response = await fetch(SHOPISA_API_URL, {
            method: "GET",
            headers: {
                "x-api-key": SHOPISA_SECRET,
                "Authorization": `Bearer ${SHOPISA_SECRET}`,
            },
        });

        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`Erro ao consultar API Shopisa (${response.status}): ${errText}`);
        }

        const data: any = await response.json();
        const products = data.products || [];
        console.log(`Recebidos ${products.length} produtos premiados da Shopisa.`);

        const synced: any[] = [];
        for (const prod of products) {
            // Verifica se o prêmio já existe pelo shopisaProductId
            const existingQuery = await db.collection("prizes")
                .where("shopisaProductId", "==", prod.id)
                .limit(1)
                .get();

            const isStockAvailable = (prod.stock ?? 0) > 0;
            // Token cost sugerido: 10 tokens por Real de preço (mínimo 100 tokens)
            const calculatedCost = Math.max(100, Math.round((Number(prod.price) || 10) * 10));
            const productLink = prod.productUrl || (prod.slug ? `https://shopisa.com.br/produto/${prod.slug}` : `https://shopisa.com.br/produto/${prod.id}`);

            if (!existingQuery.empty) {
                const docRef = existingQuery.docs[0].ref;
                const existingData = existingQuery.docs[0].data();
                await docRef.update({
                    name: prod.name,
                    price_brl: prod.price || 0,
                    original_price_brl: prod.originalPrice || 0,
                    discount_percent: prod.prizeDiscount || 100,
                    image_url: prod.image || existingData.image_url,
                    prize_link: existingData.prize_link && existingData.prize_link.toString().isNotEmpty ? existingData.prize_link : productLink,
                    quantity: prod.stock ?? 0,
                    active: isStockAvailable,
                    slug: prod.slug || "",
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                synced.push({ id: docRef.id, name: prod.name, action: "updated" });
            } else {
                const newDocRef = await db.collection("prizes").add({
                    name: prod.name,
                    type: "produto",
                    scope: "global",
                    provider: "shopisa",
                    shopisaProductId: prod.id,
                    slug: prod.slug || "",
                    prize_link: productLink,
                    token_cost: calculatedCost,
                    price_brl: prod.price || 0,
                    original_price_brl: prod.originalPrice || 0,
                    discount_percent: prod.prizeDiscount || 100,
                    image_url: prod.image || "",
                    quantity: prod.stock ?? 0,
                    active: isStockAvailable,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                synced.push({ id: newDocRef.id, name: prod.name, action: "created" });
            }
        }

        const returnedShopisaIds = new Set(products.map((p: any) => p.id));

        // Remove do catálogo do app prêmios que foram desmarcados na Shopisa
        const existingShopisaPrizesSnap = await db.collection("prizes")
            .where("provider", "==", "shopisa")
            .get();

        let removedCount = 0;
        for (const doc of existingShopisaPrizesSnap.docs) {
            const pId = doc.data().shopisaProductId;
            if (pId && !returnedShopisaIds.has(pId)) {
                console.log(`Removendo prêmio desmarcado na Shopisa: ${doc.data().name}`);
                await doc.ref.delete();
                removedCount++;
            }
        }

        return {
            success: true,
            message: `${synced.length} prêmios sincronizados com a Shopisa com sucesso. (${removedCount} removidos por terem sido desmarcados).`,
            count: synced.length,
            removedCount,
            synced,
        };
    } catch (error: any) {
        console.error("Erro na sincronização Shopisa:", error);
        throw new HttpsError("internal", error.message || "Erro desconhecido ao sincronizar prêmios.");
    }
});

/**
 * Resgata um prêmio da Shopisa: deduz tokens e gera o link único na Shopisa
 */
export const redeemShopisaPrize = onCall({
    region: "southamerica-east1",
    cors: true,
    memory: "512MiB"
}, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const { prizeId } = request.data;
    if (!prizeId) {
        throw new HttpsError("invalid-argument", "Parâmetro prizeId obrigatório.");
    }

    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);
    const prizeRef = db.collection("prizes").doc(prizeId);

    // 1. Transação para verificar saldo de tokens e estoque
    const prizeData: any = await db.runTransaction(async (t) => {
        const userSnap = await t.get(userRef);
        if (!userSnap.exists) {
            throw new HttpsError("not-found", "Usuário não encontrado.");
        }
        const prizeSnap = await t.get(prizeRef);
        if (!prizeSnap.exists) {
            throw new HttpsError("not-found", "Prêmio não encontrado.");
        }

        const userData = userSnap.data()!;
        const pData = prizeSnap.data()!;
        const userTokens = Number(userData.tokens) || 0;
        const cost = Number(pData.token_cost) || 0;
        const qty = Number(pData.quantity) ?? -1;

        if (userTokens < cost) {
            throw new HttpsError("failed-precondition", `Saldo insuficiente (${userTokens} tokens). Necessário: ${cost} tokens.`);
        }

        if (qty === 0) {
            throw new HttpsError("failed-precondition", "Este prêmio está esgotado.");
        }

        // Deduz tokens
        t.update(userRef, {
            tokens: admin.firestore.FieldValue.increment(-cost),
        });

        // Decrementa estoque se controlado e fecha o prêmio se zerar
        if (qty > 0) {
            const newQty = qty - 1;
            const prizeUpdates: any = { quantity: newQty };
            if (newQty === 0) {
                prizeUpdates.active = false;
                prizeUpdates.closedAt = admin.firestore.FieldValue.serverTimestamp();
            }
            t.update(prizeRef, prizeUpdates);
        }

        return {
            ...pData,
            cost,
            userName: userData.name || userData.displayName || "Torcedor",
            userEmail: userData.email || "",
            userPhone: userData.phone || "",
        };
    });

    // 2. Se for produto da Shopisa, gera o link único no backend da Shopisa
    let claimUrl: string | null = null;
    let rewardCode: string | null = null;

    if (prizeData.shopisaProductId) {
        try {
            console.log(`Gerando recompensa na Shopisa para o produto ${prizeData.shopisaProductId}...`);
            const shopisaResp = await fetch(SHOPISA_REWARD_URL, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "x-api-key": SHOPISA_SECRET,
                    "Authorization": `Bearer ${SHOPISA_SECRET}`,
                },
                body: JSON.stringify({
                    productId: prizeData.shopisaProductId,
                }),
            });

            if (shopisaResp.ok) {
                const shopisaJson: any = await shopisaResp.json();
                if (shopisaJson.success) {
                    claimUrl = shopisaJson.claimUrl;
                    rewardCode = shopisaJson.rewardCode;
                }
            } else {
                console.error("Falha ao gerar recompensa na Shopisa:", await shopisaResp.text());
            }
        } catch (apiErr) {
            console.error("Erro na chamada generateReward da Shopisa:", apiErr);
        }
    }

    // 3. Registra o resgate na coleção redemptions
    const redemptionRef = await db.collection("redemptions").add({
        uid,
        userName: prizeData.userName,
        userEmail: prizeData.userEmail,
        userPhone: prizeData.userPhone,
        prizeId,
        prizeName: prizeData.name,
        shopisaProductId: prizeData.shopisaProductId || null,
        type: prizeData.type || "produto",
        provider: prizeData.provider || "shopisa",
        cost: prizeData.cost,
        rewardCode,
        claimUrl,
        status: claimUrl ? "disponivel" : "pendente",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Registra na movimentação de tokens
    await db.collection("token_transactions").add({
        uid,
        amount: -prizeData.cost,
        type: "prize_redemption",
        description: `Resgate de Prêmio: ${prizeData.name}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
        success: true,
        redemptionId: redemptionRef.id,
        rewardCode,
        claimUrl,
        message: "Prêmio resgatado com sucesso!",
    };
});

/**
 * Dispara manualmente um evento de gol para testes de áudio e WhatsApp
 */
export const triggerGoalNotification = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }
    const { teamName, homeScore, awayScore, opponentName } = request.data || {};
    const scoringTeam = teamName || "Atlético Mineiro (Galo)";
    const opponent = opponentName || "Cruzeiro";
    const hScore = homeScore ?? 1;
    const aScore = awayScore ?? 0;

    // 1. Grava no recent_goals para acionar o som goal.wav no app
    await db.collection("recent_goals").add({
        fixtureId: 999999,
        scoringTeam: scoringTeam,
        homeTeamName: scoringTeam,
        awayTeamName: opponent,
        homeScore: hScore,
        awayScore: aScore,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // 2. Dispara WhatsApp para torcedores
    const settingsDoc = await db.collection("settings").doc("general").get();
    const zApiUrl = settingsDoc.data()?.api_keys?.z_api;
    let sentCount = 0;

    if (zApiUrl) {
        const targetUrl = zApiUrl.endsWith("/") ? `${zApiUrl}send-text` : `${zApiUrl}/send-text`;
        const usersSnap = await db.collection("users").get();
        const scoringNorm = scoringTeam.toLowerCase().trim();

        for (const uDoc of usersSnap.docs) {
            const uData = uDoc.data();
            const favTeam = (uData.favorite_team_name || uData.favoriteTeamName || "").toLowerCase().trim();
            if (!favTeam || !uData.phone) continue;

            const isFan = scoringNorm.includes(favTeam) || favTeam.includes(scoringNorm) ||
                (favTeam.includes("galo") && (scoringNorm.includes("atlético") || scoringNorm.includes("atletico"))) ||
                (favTeam.includes("mengão") && scoringNorm.includes("flamengo")) ||
                (favTeam.includes("timão") && scoringNorm.includes("corinthians")) ||
                (favTeam.includes("palestra") && scoringNorm.includes("palmeiras")) ||
                (favTeam.includes("peixe") && scoringNorm.includes("santos")) ||
                (favTeam.includes("raposa") && scoringNorm.includes("cruzeiro"));

            if (isFan) {
                const cleanPhone = uData.phone.replace(/\D/g, "");
                const goalMsg = `⚽ *GOOOOOOOL DO ${scoringTeam.toUpperCase()}!* 💥🔥\n\nFala ${uData.name || 'Torcedor'}! O seu time do coração acabou de marcar!\n\nPlacar ao vivo: *${scoringTeam} ${hScore} x ${aScore} ${opponent}*\n\nAbra o *Raspadinha do Gol* agora para raspar sua cartela e concorrer a prêmios na hora! 🍀`;

                try {
                    await fetch(targetUrl, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                            phone: `55${cleanPhone}`,
                            message: goalMsg
                        })
                    });
                    sentCount++;
                } catch (e) {
                    console.error("Erro ao enviar Z-API teste:", e);
                }
            }
        }
    }

    return { 
        success: true, 
        message: `Gol disparado! ${sentCount} torcedor(es) notificado(s) no WhatsApp e áudio acionado no app.` 
    };
});

/**
 * Cria cobrança PIX no Mercado Pago para Taxa de Ativação do Bolão (R$ 4,90)
 */
export const createBolaoActivationPix = onCall({ region: "southamerica-east1" }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }
    const { bolaoName = "Sala Personalizada", amount = 4.90 } = request.data || {};

    const settingsDoc = await db.collection("settings").doc("general").get();
    const data = settingsDoc.data() || {};
    const mpAccessToken = data?.api_keys?.mercado_pago || data?.mercado_pago || process.env.MERCADO_PAGO_TOKEN;

    if (!mpAccessToken) {
        throw new HttpsError("failed-precondition", "Mercado Pago não configurado no painel de administração.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data() || {};
    const userEmail = userData.email || request.auth?.token?.email || "torcedor@raspadinhadogol.com.br";
    const userName = userData.name || "Torcedor do Gol";

    const nameParts = userName.trim().split(" ");
    const firstName = nameParts[0] || "Torcedor";
    const lastName = nameParts.length > 1 ? nameParts.slice(1).join(" ") : "do Gol";

    const idempotencyKey = `bolao_act_${uid}_${Date.now()}`;
    const mpResponse = await axios.post(
        "https://api.mercadopago.com/v1/payments",
        {
            transaction_amount: Number(amount) || 4.90,
            description: `Ativação Bolão do Gol: ${bolaoName}`,
            payment_method_id: "pix",
            payer: {
                email: userEmail,
                first_name: firstName,
                last_name: lastName
            }
        },
        {
            headers: {
                "Authorization": `Bearer ${mpAccessToken.trim()}`,
                "X-Idempotency-Key": idempotencyKey,
                "Content-Type": "application/json"
            }
        }
    );

    const paymentData = mpResponse.data;
    const paymentId = paymentData.id;
    const qrCode = paymentData.point_of_interaction?.transaction_data?.qr_code;
    const qrCodeBase64 = paymentData.point_of_interaction?.transaction_data?.qr_code_base64;

    const actRef = await db.collection("bolao_activations").add({
        uid,
        paymentId,
        bolaoName,
        amount: Number(amount) || 4.90,
        status: paymentData.status || "pending",
        qrCode,
        qrCodeBase64,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
        activationId: actRef.id,
        paymentId,
        qrCode,
        qrCodeBase64,
        amount: Number(amount) || 4.90,
        status: paymentData.status || "pending"
    };
});

/**
 * Consulta status do PIX de Ativação do Bolão no Mercado Pago
 */
export const checkBolaoActivationPixStatus = onCall({ region: "southamerica-east1" }, async (request) => {
    const { paymentId, activationId } = request.data || {};
    if (!paymentId) {
        throw new HttpsError("invalid-argument", "Payment ID é obrigatório.");
    }
    const settingsDoc = await db.collection("settings").doc("general").get();
    const data = settingsDoc.data() || {};
    const mpAccessToken = data?.api_keys?.mercado_pago || data?.mercado_pago || process.env.MERCADO_PAGO_TOKEN;

    if (!mpAccessToken) {
        throw new HttpsError("failed-precondition", "Mercado Pago não configurado.");
    }

    const mpResponse = await axios.get(
        `https://api.mercadopago.com/v1/payments/${paymentId}`,
        {
            headers: {
                "Authorization": `Bearer ${mpAccessToken.trim()}`
            }
        }
    );

    const status = mpResponse.data.status;
    const isApproved = status === "approved";

    if (activationId && isApproved) {
        await db.collection("bolao_activations").doc(activationId).update({
            status: "approved",
            approvedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    return {
        status,
        isApproved
    };
});

/**
 * Ativa a sala do Bolão debitando 2.500 Tokens do Gol do saldo do usuário
 */
export const activateBolaoWithTokens = onCall({ region: "southamerica-east1" }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }
    const TOKENS_COST = 2500;
    const userRef = db.collection("users").doc(uid);

    await db.runTransaction(async (t) => {
        const uDoc = await t.get(userRef);
        if (!uDoc.exists) throw new HttpsError("not-found", "Usuário não encontrado.");
        const currentTokens = uDoc.data()?.tokens || 0;
        if (currentTokens < TOKENS_COST) {
            throw new HttpsError("failed-precondition", `Saldo insuficiente de tokens. Você precisa de ${TOKENS_COST} tokens (possui ${currentTokens}).`);
        }
        t.update(userRef, {
            tokens: admin.firestore.FieldValue.increment(-TOKENS_COST)
        });
        const txRef = db.collection("token_transactions").doc();
        t.set(txRef, {
            uid,
            amount: -TOKENS_COST,
            type: "bolao_activation_fee",
            description: "Taxa de Ativação de Sala do Bolão",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });

    return { success: true, tokensDeducted: TOKENS_COST };
});
