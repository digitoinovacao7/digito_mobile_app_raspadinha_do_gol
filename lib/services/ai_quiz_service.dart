import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'db_service.dart';

final aiQuizServiceProvider = Provider<AiQuizService>((ref) {
  return AiQuizService();
});

class AiQuizService {
  final DbService _dbService = DbService();

  Future<Map<String, dynamic>?> generateQuiz(String homeTeam, String awayTeam) async {
    try {
      final keys = await _dbService.getApiKeys();
      final apiKey = keys['gemini'];
      
      if (apiKey == null || apiKey.toString().isEmpty) {
        throw Exception('Chave do Gemini não configurada no Painel Admin.');
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey.toString(),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
        ),
      );

      final prompt = '''
Você é um especialista em futebol. Gere UMA pergunta de múltipla escolha interessante sobre a história ou curiosidades do confronto entre $homeTeam e $awayTeam, ou sobre um desses times se não houver muito histórico direto. 
A pergunta deve ser criativa, nível médio/difícil, algo que um verdadeiro fã de futebol saberia.
Retorne APENAS um objeto JSON válido (sem markdown) no seguinte formato exato:
{
  "pergunta": "Texto da pergunta",
  "opcoes": ["Opção 1", "Opção 2", "Opção 3", "Opção 4"],
  "respostaCorreta": 0 // Índice numérico da opção correta (0 a 3)
}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        String jsonText = response.text!.trim();
        // Remove blocos de markdown caso a IA ainda os retorne
        if (jsonText.startsWith('```json')) jsonText = jsonText.substring(7);
        else if (jsonText.startsWith('```')) jsonText = jsonText.substring(3);
        if (jsonText.endsWith('```')) jsonText = jsonText.substring(0, jsonText.length - 3);

        final decoded = jsonDecode(jsonText.trim());
        return decoded;
      }
      return null;
    } catch (e) {
      print('Erro ao gerar quiz com a IA: $e');
      throw e;
    }
  }
}
