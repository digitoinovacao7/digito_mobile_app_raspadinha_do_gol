import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleGenAI } from "@google/genai";

admin.initializeApp();

const db = admin.firestore();

// Constantes
const TOKENS_PER_CORRECT_ANSWER = 100;
const COST_PER_SCRATCH = 50;

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

    const { quizId, answerId } = request.data;
    if (!quizId || answerId === undefined) {
        throw new HttpsError("invalid-argument", "Faltam parâmetros (quizId, answerId).");
    }

    const uid = request.auth.uid;
    const userQuizAttemptRef = db.collection("users").doc(uid).collection("quiz_attempts").doc(quizId);
    
    try {
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
                answerId: answerId
            });

            if (isCorrect) {
                const userRef = db.collection("users").doc(uid);
                t.update(userRef, {
                    tokens: admin.firestore.FieldValue.increment(TOKENS_PER_CORRECT_ANSWER)
                });
            }

            return { isCorrect };
        });

        return { 
            success: true, 
            isCorrect: result.isCorrect, 
            earnedTokens: result.isCorrect ? TOKENS_PER_CORRECT_ANSWER : 0 
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
        const result = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "Usuário não encontrado.");
            }

            const currentTokens = userDoc.data()?.tokens || 0;
            if (currentTokens < COST_PER_SCRATCH) {
                throw new HttpsError("failed-precondition", "Tokens insuficientes.");
            }

            // Deduz os tokens
            transaction.update(userRef, {
                tokens: admin.firestore.FieldValue.increment(-COST_PER_SCRATCH)
            });

            // Motor de Probabilidade (RNG) simplificado:
            const rand = Math.random();
            let winCount = 0;
            let resultMessage = "Quase! Tente novamente.";
            let prizeType = "none";
            let wonTokens = 0;

            if (rand < 0.05) {
                winCount = 3;
                wonTokens = 1000;
                resultMessage = `GOLAÇO! Você ganhou ${wonTokens} Tokens!`;
                prizeType = "tokens";
                transaction.update(userRef, {
                    tokens: admin.firestore.FieldValue.increment(wonTokens)
                });
            } else if (rand < 0.20) {
                winCount = 2;
                wonTokens = 100;
                resultMessage = `Na Trave! Você ganhou ${wonTokens} Tokens extras.`;
                prizeType = "tokens";
                transaction.update(userRef, {
                    tokens: admin.firestore.FieldValue.increment(wonTokens)
                });
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

            const historyRef = db.collection("scratch_history").doc();
            transaction.set(historyRef, {
                uid: uid,
                date: admin.firestore.FieldValue.serverTimestamp(),
                winCount: winCount,
                prizeType: prizeType,
                cost: COST_PER_SCRATCH
            });

            return { 
                success: true, 
                gridBalls, 
                winCount, 
                message: resultMessage,
                prizeType,
                wonTokens
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
    const userDoc = await db.collection("users").doc(uid).get();
    if (userDoc.data()?.role !== "admin") {
        throw new HttpsError("permission-denied", "Apenas administradores podem gerar quizzes.");
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
