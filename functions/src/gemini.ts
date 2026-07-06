import {
    GenerateContentParameters,
    GenerateContentResponse,
    GoogleGenAI,
} from "@google/genai";

/**
 * Modelos estáveis usados por todas as integrações Gemini do projeto.
 *
 * O 2.5 tem menor incidência de erro por alta demanda atualmente. O 3.5 fica
 * como fallback e assume automaticamente quando o 2.5 for descontinuado.
 */
const GEMINI_MODELS = ["gemini-1.5-pro", "gemini-1.5-flash", "gemini-pro"];

export async function generateGeminiContent(
    ai: GoogleGenAI,
    parameters: Omit<GenerateContentParameters, "model">
): Promise<GenerateContentResponse> {
    let lastError: unknown;

    for (const model of GEMINI_MODELS) {
        try {
            return await ai.models.generateContent({...parameters, model});
        } catch (error: any) {
            lastError = error;
            const message = String(error?.message || error);
            const canTryFallback =
                message.includes("\"code\":404") ||
                message.includes("\"code\":429") ||
                message.includes("\"code\":503") ||
                message.includes("NOT_FOUND") ||
                message.includes("RESOURCE_EXHAUSTED") ||
                message.includes("UNAVAILABLE");

            if (!canTryFallback) {
                throw error;
            }

            console.warn(`Gemini ${model} indisponível; tentando o próximo modelo.`);
        }
    }

    throw lastError;
}
