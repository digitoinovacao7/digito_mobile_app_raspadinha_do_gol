import axios from 'axios';

const GEMINI_MODELS = ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-pro"];

export interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{
        text?: string;
      }>;
    };
  }>;
}

export async function generateGeminiContent(
    apiKey: string,
    prompt: string
): Promise<{ text: string }> {
    let lastError: unknown;

    for (const model of GEMINI_MODELS) {
        try {
            const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
            const response = await axios.post<GeminiResponse>(url, {
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                    responseMimeType: "application/json",
                }
            }, {
                timeout: 45000,
                headers: { "Content-Type": "application/json" }
            });

            const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
                return { text };
            }
            throw new Error(`Modelo ${model} retornou resposta vazia.`);
        } catch (error: any) {
            lastError = error;
            const message = String(error?.message || error?.response?.data || error);
            const canTryFallback =
                message.includes("403") ||
                message.includes("404") ||
                message.includes("429") ||
                message.includes("503") ||
                message.includes("NOT_FOUND") ||
                message.includes("RESOURCE_EXHAUSTED") ||
                message.includes("UNAVAILABLE");

            if (!canTryFallback) {
                throw error;
            }

            console.warn(`Gemini ${model} indisponível; tentando o próximo modelo. (${message})`);
        }
    }

    throw lastError;
}
