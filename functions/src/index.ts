import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";

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
        const settingsDoc = await db.collection("system_config").doc("general").get();
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
                t.update(userRef, {
                    tokens: admin.firestore.FieldValue.increment(quizReward),
                    [`answered_quizzes_count.${fixtureId}`]: admin.firestore.FieldValue.increment(1)
                });

                const transactionRef = db.collection("token_transactions").doc();
                t.set(transactionRef, {
                    uid: uid,
                    amount: quizReward,
                    type: "quiz_reward",
                    description: `Acerto no Quiz: ${matchName}`,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                t.update(userRef, {
                    [`answered_quizzes_count.${fixtureId}`]: admin.firestore.FieldValue.increment(1)
                });
                
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

    const uid = request.auth.uid;
    const userRef = db.collection("users").doc(uid);

    try {
        const settingsDoc = await db.collection("system_config").doc("general").get();
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

            const currentTokens = userDoc.data()?.tokens || 0;
            if (currentTokens < costPerScratch) {
                throw new HttpsError("failed-precondition", "Tokens insuficientes.");
            }

            // [CLEAN CODE] Regra do Firestore: TODAS as leituras devem ocorrer antes das escritas.
            // Movemos a query de prêmios para o topo da transação.
            const prizesSnapshot = await transaction.get(db.collection("prizes").where("active", "==", true));
            const activePrizes = prizesSnapshot.docs;

            // Variável para acumular o saldo final da transação em apenas uma operação de escrita
            let tokenDelta = -costPerScratch; 

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
                    } else if (prizeType === "tokens") {
                        wonTokens = prizeData.token_amount || 1000;
                        resultMessage = `GOLAÇO! Você ganhou ${wonTokens} Tokens!`;
                        tokenDelta += wonTokens; // Acumula na varredura, sem realizar duplo update no BD
                    } else {
                        resultMessage = `GOLAÇO! Você ganhou: ${prizeName}!`;
                    }
                } else {
                    // Fallback se não tiver prêmio ativo
                    wonTokens = 1000;
                    prizeType = "tokens";
                    resultMessage = `GOLAÇO! Você ganhou ${wonTokens} Tokens!`;
                    tokenDelta += wonTokens;
                }
            } else if (rand < globalWinChance + 0.15) {
                // Na trave logic: +15% chance of getting 2 balls
                winCount = 2;
                wonTokens = 100;
                resultMessage = `Na Trave! Você ganhou ${wonTokens} Tokens extras.`;
                prizeType = "tokens";
                tokenDelta += wonTokens;
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

            // [CLEAN CODE] Executamos apenas UMA escrita no userRef para evitar crash de 'document written twice in transaction'
            transaction.update(userRef, {
                tokens: admin.firestore.FieldValue.increment(tokenDelta)
            });

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

    const { context } = request.data;
    if (!context) {
        throw new HttpsError("invalid-argument", "Contexto não fornecido.");
    }

    // Busca a API key do painel (salva no Firestore)
    const settingsDoc = await db.collection("settings").doc("api_keys").get();
    const geminiKey = settingsDoc.data()?.gemini_api_key;
    if (!geminiKey) {
        throw new HttpsError("failed-precondition", "Chave de API do Gemini não configurada no painel admin.");
    }

    const ai = new GoogleGenAI({ apiKey: geminiKey });

    const prompt = `Você é o narrador do aplicativo Raspadinha do Gol. 
Gere uma pergunta de múltipla escolha sobre futebol.
O contexto atual para inspiração é: "${context}".
A pergunta deve ter 4 alternativas curtas (A, B, C e D). 
Retorne APENAS um objeto JSON válido (sem blocos de código Markdown como \`\`\`json), com as chaves: 
"question" (string), "options" (array de 4 strings), e "correctIndex" (número inteiro de 0 a 3 indicando a opção certa).`;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: prompt,
            config: {
                responseMimeType: "application/json",
            }
        });

        const jsonText = response.text || "{}";
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

        // Retorna pro cliente o que foi gerado
        return { 
            success: true, 
            quizId: quizRef.id, 
            question: quizData.question, 
            options: quizData.options 
        };
    } catch (error: any) {
        throw new HttpsError("internal", `Erro ao gerar quiz: ${error.message}`);
    }
});
