import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

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
    
    // No mundo real, validaríamos contra o Firestore se o quiz está ativo
    // Para MVP, se answerId for 0 (alternativa A), consideramos correto.
    const isCorrect = answerId === 0;

    if (isCorrect) {
        const userRef = db.collection("users").doc(uid);
        await userRef.update({
            tokens: admin.firestore.FieldValue.increment(TOKENS_PER_CORRECT_ANSWER)
        });
        return { success: true, isCorrect: true, earnedTokens: TOKENS_PER_CORRECT_ANSWER };
    }

    return { success: true, isCorrect: false, earnedTokens: 0 };
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
            // 5% chance de ganhar o prêmio principal (3 bolas de futebol = winCount 3 -> 5000 Tokens)
            // 15% chance de ganhar algo secundário (winCount 2 -> 100 Tokens)
            // 80% chance de perder (winCount 0 ou 1)
            const rand = Math.random();
            let winCount = 0;
            let resultMessage = "Quase! Tente novamente.";
            let prizeType = "none";
            let wonTokens = 0;

            if (rand < 0.05) {
                winCount = 3;
                wonTokens = 1000; // Prêmio principal em tokens
                resultMessage = `GOLAÇO! Você ganhou ${wonTokens} Tokens!`;
                prizeType = "tokens";
                transaction.update(userRef, {
                    tokens: admin.firestore.FieldValue.increment(wonTokens)
                });
            } else if (rand < 0.20) {
                winCount = 2;
                wonTokens = 100; // Prêmio de consolação
                resultMessage = `Na Trave! Você ganhou ${wonTokens} Tokens extras.`;
                prizeType = "tokens";
                transaction.update(userRef, {
                    tokens: admin.firestore.FieldValue.increment(wonTokens)
                });
            } else {
                winCount = Math.floor(Math.random() * 2); // 0 ou 1
            }

            // Gerar o grid baseado no winCount
            const gridBalls: boolean[] = Array(9).fill(false);
            let placed = 0;
            while(placed < winCount) {
                const idx = Math.floor(Math.random() * 9);
                if (!gridBalls[idx]) {
                    gridBalls[idx] = true;
                    placed++;
                }
            }

            // Registrar a tentativa no histórico
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
