import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
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
            
            const quizData = quizDoc.data()!;
            if (!quizData.active) {
                throw new HttpsError("failed-precondition", "Este quiz já expirou.");
            }

            const isCorrect = quizData.correctIndex === answerId;

            // Salva a tentativa para evitar que responda de novo
            t.set(userQuizAttemptRef, {
                answeredAt: admin.firestore.FieldValue.serverTimestamp(),
                isCorrect: isCorrect,
                answerId: answerId,
                fixtureId: fixtureId,
                matchName: matchName
            });

            const userRef = db.collection("users").doc(uid);

            if (isCorrect) {
                t.set(userRef, {
                    tokens: admin.firestore.FieldValue.increment(quizReward),
                    answered_quizzes_count: {
                        [fixtureId]: admin.firestore.FieldValue.increment(1)
                    }
                }, { merge: true });

                const transactionRef = db.collection("token_transactions").doc();
                t.set(transactionRef, {
                    uid: uid,
                    amount: quizReward,
                    type: "quiz_reward",
                    description: `Acerto no Quiz: ${matchName}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                t.set(userRef, {
                    answered_quizzes_count: {
                        [fixtureId]: admin.firestore.FieldValue.increment(1)
                    }
                }, { merge: true });
                
                const transactionRef = db.collection("token_transactions").doc();
                t.set(transactionRef, {
                    uid: uid,
                    amount: 0,
                    type: "quiz_failure",
                    description: `Erro no Quiz: ${matchName}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            return { isCorrect, quizReward };
        });

        return { 
            success: true, 
            isCorrect: result.isCorrect, 
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
            // Movemos a query de prêmios para o topo da transação.
            const prizesSnapshot = await transaction.get(db.collection("prizes").where("active", "==", true));
            const activePrizes = prizesSnapshot.docs;


            // Motor de Probabilidade (RNG) simplificado:
            const rand = Math.random();
            let winCount = 0;
            let resultMessage = "Quase! Tente novamente.";
            let prizeType = "none";
            let wonTokens = 0;
            let prizeLink = null;
            let prizeName = null;

            if (rand < globalWinChance) {
                winCount = 3;
                
                if (activePrizes.length > 0) {
                    const randomPrizeDoc = activePrizes[Math.floor(Math.random() * activePrizes.length)];
                    const prizeData = randomPrizeDoc.data();
                    
                    prizeType = prizeData.type || "produto";
                    prizeName = prizeData.name || "Prêmio Surpresa";
                    prizeLink = prizeData.prize_link || null;
                    
                    if (prizeType === "pix") {
                        resultMessage = `GOLAÇO! Você ganhou um PIX: ${prizeName}!`;
                    } else {
                        resultMessage = `GOLAÇO! Você ganhou: ${prizeName}!`;
                    }
                } else {
                    // Fallback se não tiver prêmio ativo
                    wonTokens = 1000;
                    prizeType = "tokens";
                    resultMessage = `GOLAÇO! Você ganhou a chance de jogar o Quiz extra!`;
                }
            } else if (rand < globalWinChance + 0.15) {
                // Na trave logic: +15% chance of getting 2 balls
                winCount = 2;
                wonTokens = 100;
                resultMessage = `Na Trave! Você quase conseguiu.`;
                prizeType = "none";
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


            if (useTokens || wonTokens > 0) {
                const deduction = useTokens ? costPerScratch : 0;
                transaction.update(userRef, {
                    tokens: userTokens - deduction + wonTokens
                });
            }

            const historyRef = db.collection("scratch_history").doc();
            transaction.set(historyRef, {
                uid: uid,
                date: admin.firestore.FieldValue.serverTimestamp(),
                winCount: winCount,
                prizeType: prizeType,
                cost: costPerScratch
            });

            return { 
                success: true, 
                gridBalls, 
                winCount, 
                message: resultMessage,
                prizeType,
                wonTokens,
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
    
    if (!geminiKey) {
        throw new HttpsError("failed-precondition", "Chave de API do Gemini não configurada no banco de dados.");
    }

    // Verifica limite diário do usuário
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    const userData = userDoc.data() || {};
    const todayStr = new Date().toISOString().split('T')[0]; // "YYYY-MM-DD"
    const lastQuizDate = userData.last_quiz_date;
    const dailyQuizzesGenerated = userData.daily_quizzes_generated || 0;

    if (lastQuizDate === todayStr && dailyQuizzesGenerated >= dailyQuizLimit) {
        throw new HttpsError("resource-exhausted", `Você atingiu o limite de ${dailyQuizLimit} quizzes diários. Volte amanhã!`);
    }

    const prompt = `Você é o narrador do aplicativo Raspadinha do Gol. 
Gere uma pergunta de múltipla escolha sobre futebol.
O contexto atual para inspiração é: "${context}".
A pergunta deve ter 4 alternativas curtas (A, B, C e D). 
Retorne APENAS um objeto JSON válido (sem blocos de código Markdown como \`\`\`json), com as chaves: 
"question" (string), "options" (array de 4 strings), e "correctIndex" (número inteiro de 0 a 3 indicando a opção certa).`;

    try {
        const response = await generateGeminiContent(geminiKey, prompt);

        let jsonText = response.text || "{}";
        const jsonMatch = jsonText.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            jsonText = jsonMatch[0];
        }
        const quizData = JSON.parse(jsonText);

        if (!quizData.question || !Array.isArray(quizData.options) || quizData.options.length !== 4 || quizData.correctIndex === undefined) {
             throw new Error("Formato de quiz gerado inválido.");
        }

        // Salvar no Firestore
        const quizRef = db.collection("quizzes").doc();
        await quizRef.set({
            question: quizData.question,
            options: quizData.options,
            correctIndex: quizData.correctIndex,
            context: context,
            active: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Atualiza contagem do usuário
        await userRef.set({
            last_quiz_date: todayStr,
            daily_quizzes_generated: lastQuizDate === todayStr ? dailyQuizzesGenerated + 1 : 1
        }, { merge: true });

        // Retorna pro cliente o que foi gerado
        return { 
            success: true, 
            quizId: quizRef.id, 
            question: quizData.question, 
            options: quizData.options 
        };
    } catch (error: any) {
        console.error("ERRO COMPLETO EM GENERATE_QUIZ:", error);
        throw new HttpsError("internal", `Erro ao gerar quiz: ${error.message}`);
    }
});

/**
 * Solicita o OTP para saque via PIX (Envia WhatsApp via Z-API)
 */
export const requestPixOtp = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    const uid = request.auth.uid;
    const { pixKey, amount, phone } = request.data;

    if (!pixKey || !amount || !phone) {
        throw new HttpsError("invalid-argument", "Chave PIX, valor e telefone são obrigatórios.");
    }

    // Gerar OTP de 6 dígitos
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10); // OTP válido por 10 min

    // Salvar no Firestore
    await db.collection("users").doc(uid).collection("otp").doc("pix").set({
        otp: otp,
        pixKey: pixKey,
        amount: amount,
        expiresAt: expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Enviar WhatsApp via Z-API
    const settingsDoc = await db.collection("settings").doc("general").get();
    const zApiUrl = settingsDoc.data()?.api_keys?.z_api;
    if (!zApiUrl) {
        // Fallback: se não tiver Z-API configurada, apenas gera o OTP. 
        console.warn("Z-API não configurada! O OTP gerado é:", otp);
        return { success: true, message: "OTP gerado (mock)." };
    }

    try {
        const cleanPhone = phone.replace(/\D/g, ""); // Remove não numéricos
        const targetUrl = zApiUrl.endsWith("/") ? `${zApiUrl}send-text` : `${zApiUrl}/send-text`;
        
        const response = await fetch(targetUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                phone: `55${cleanPhone}`, // Assumindo Brasil (55)
                message: `⚽ *Raspadinha do Gol* ⚽\n\nSeu código de segurança para confirmar o saque via PIX é: *${otp}*\n\nEste código expira em 10 minutos.`
            })
        });

        if (!response.ok) {
            console.error("Z-API error:", await response.text());
            throw new Error("Falha ao enviar mensagem pela Z-API.");
        }

        return { success: true, message: "OTP enviado para o WhatsApp." };
    } catch (e: any) {
        console.error(e);
        throw new HttpsError("internal", "Erro ao tentar enviar WhatsApp: " + e.message);
    }
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
        if (userData.lastQuizDate === today) {
            continue;
        }

        const cleanPhone = userData.phone.replace(/\D/g, "");
        const msg = `Fala campeão! ⚽\n\nVocê tem *${userData.tokens} Tokens* acumulados dando sopa no *Raspadinha do Gol*!\n\nEntre no aplicativo agora, jogue a raspadinha e concorra a Pix e prêmios na hora. A sorte está do seu lado? 🍀`;
        
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
 * Valida o OTP e debita os tokens para o Saque PIX
 */
export const validatePixOtpAndWithdraw = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
    }
    const uid = request.auth.uid;
    const { otp } = request.data;

    if (!otp) {
        throw new HttpsError("invalid-argument", "O código OTP é obrigatório.");
    }

    const otpRef = db.collection("users").doc(uid).collection("otp").doc("pix");
    const userRef = db.collection("users").doc(uid);
    const settingsDoc = await db.collection("settings").doc("general").get();
    const tokensPerReal = Number(settingsDoc.data()?.economy?.tokens_per_real) || 100;

    try {
        const result = await db.runTransaction(async (t) => {
            const otpDoc = await t.get(otpRef);
            if (!otpDoc.exists) {
                throw new HttpsError("not-found", "Nenhuma solicitação de PIX pendente.");
            }

            const otpData = otpDoc.data()!;
            const now = new Date();
            const expiresAt = otpData.expiresAt?.toDate();

            if (!expiresAt || now > expiresAt) {
                throw new HttpsError("failed-precondition", "O código OTP expirou.");
            }

            if (otpData.otp !== otp) {
                throw new HttpsError("invalid-argument", "O código OTP está incorreto.");
            }

            const userDoc = await t.get(userRef);
            const userTokens = userDoc.data()?.tokens || 0;
            const amountTokens = Number(otpData.amount);

            if (userTokens < amountTokens) {
                throw new HttpsError("failed-precondition", "Saldo insuficiente.");
            }

            // Tudo válido: Deduzir tokens, apagar OTP e criar registro de resgate
            t.update(userRef, {
                tokens: admin.firestore.FieldValue.increment(-amountTokens)
            });

            t.delete(otpRef);

            const redemptionRef = db.collection("redemptions").doc();
            const valueInReais = amountTokens / tokensPerReal;

            t.set(redemptionRef, {
                userId: uid,
                userName: userDoc.data()?.name || "Usuário",
                userEmail: userDoc.data()?.email || "",
                pixKey: otpData.pixKey,
                tokensCost: amountTokens,
                valueInReais: valueInReais,
                type: 'pix',
                status: 'pendente',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return { success: true, valueInReais };
        });

        return result;
    } catch (e: any) {
        throw new HttpsError("internal", e.message || "Erro interno na validação OTP.");
    }
});

/**
 * Proxy para chamadas do Football-Data.org contornando CORS em ambientes Web
 */
export const proxyFootballData = onCall(async (request) => {
    // Busca a API key do painel (salva no Firestore)
    const settingsDoc = await db.collection("settings").doc("general").get();
    const data = settingsDoc.data() || {};
    const footballDataKey = data?.api_keys?.football_data || data?.football_data_key || data?.football_data;
    
    if (!footballDataKey) {
        const debugData = JSON.stringify(settingsDoc.data() || {});
        throw new HttpsError("failed-precondition", "Chave da API Football-Data.org não configurada. Dados lidos: " + debugData);
    }

    const endpoint = request.data.endpoint; 
    const queryParams = request.data.queryParams || {};

    if (!endpoint) {
        throw new HttpsError("invalid-argument", "O endpoint é obrigatório.");
    }

    // Monta a querystring
    const queryString = new URLSearchParams(queryParams).toString();
    const targetUrl = `https://api.football-data.org/v4/${endpoint}${queryString ? `?${queryString}` : ''}`;

    try {
        const fetchResponse = await fetch(targetUrl, {
            method: "GET",
            headers: {
                "X-Auth-Token": footballDataKey,
                "Content-Type": "application/json"
            }
        });

        if (!fetchResponse.ok) {
            const errorText = await fetchResponse.text();
            console.error("Erro na API Football-Data.org:", targetUrl, fetchResponse.status, errorText);
            throw new Error(`API retornou status ${fetchResponse.status}`);
        }

        const data = await fetchResponse.text();
        return { success: true, data: data };
    } catch (e: any) {
        console.error("Falha ao consultar API Football-Data.org:", e);
        throw new HttpsError("internal", `Erro interno no proxy: ${e.message}`);
    }
});

export const pollLiveMatches = onSchedule("* * * * *", async (event) => {
    // 1. Get distinct watching_fixture_ids
    const usersSnap = await db.collection("users").where("watching_fixture_id", ">", 0).get();
    const activeFixtures = new Set<number>();
    usersSnap.forEach(doc => {
        const fixId = doc.data().watching_fixture_id;
        if (fixId) activeFixtures.add(fixId);
    });

    if (activeFixtures.size === 0) {
        return;
    }

    const settingsDoc = await db.collection("settings").doc("general").get();
    const data = settingsDoc.data() || {};
    const activeApi = data.active_football_api || 'api_football';
    const keys = data.api_keys || {};

    for (const fixtureId of activeFixtures) {
        try {
            let homeScore = 0;
            let awayScore = 0;
            let status = '';
            let homeTeamName = '';
            let awayTeamName = '';

            if (activeApi === 'api_football') {
                const apiKey = keys.api_football;
                if (!apiKey) continue;
                const url = `https://v3.football.api-sports.io/fixtures?id=${fixtureId}`;
                const fetchResponse = await fetch(url, {
                    headers: { "x-apisports-key": apiKey }
                });
                if (!fetchResponse.ok) continue;
                const matchData = await fetchResponse.json();
                if (matchData.response && matchData.response.length > 0) {
                    const fix = matchData.response[0];
                    homeScore = fix.goals?.home ?? 0;
                    awayScore = fix.goals?.away ?? 0;
                    status = fix.fixture?.status?.short ?? '';
                    homeTeamName = fix.teams?.home?.name ?? '';
                    awayTeamName = fix.teams?.away?.name ?? '';
                }
            } else {
                const apiKey = keys.football_data || data.football_data_key;
                if (!apiKey) continue;
                const url = `https://api.football-data.org/v4/matches/${fixtureId}`;
                const fetchResponse = await fetch(url, {
                    headers: { "X-Auth-Token": apiKey }
                });
                if (!fetchResponse.ok) continue;
                const matchData = await fetchResponse.json();
                homeScore = matchData.score?.fullTime?.home ?? 0;
                awayScore = matchData.score?.fullTime?.away ?? 0;
                status = matchData.status;
                homeTeamName = matchData.homeTeam?.shortName ?? '';
                awayTeamName = matchData.awayTeam?.shortName ?? '';
            }

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
                if (activeApi === 'api_football') {
                    if (prevState.status !== 'HT' && status === 'HT') shouldNotifyWhistle = true;
                } else {
                    if (prevState.status !== 'PAUSED' && status === 'PAUSED') shouldNotifyWhistle = true;
                }
            }

            if (shouldNotifyGoal || shouldNotifyWhistle) {
                const soundFile = shouldNotifyGoal ? "goal.wav" : "whistle.wav";
                const channelId = shouldNotifyGoal ? "match_goal" : "match_whistle";
                const title = shouldNotifyGoal ? "GOL!" : "Fim do Primeiro Tempo";
                const body = `${homeTeamName} ${homeScore} x ${awayScore} ${awayTeamName}`;

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
            }

            await stateRef.set({
                homeScore,
                awayScore,
                status,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

        } catch (e) {
            console.error(`Erro ao atualizar partida ${fixtureId}:`, e);
        }
    }
});


export * from "./pinnacle";
