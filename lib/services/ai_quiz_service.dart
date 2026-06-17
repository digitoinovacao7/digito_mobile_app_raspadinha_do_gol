import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

final aiQuizServiceProvider = Provider<AiQuizService>((ref) {
  return AiQuizService();
});

class AiQuizService {
  Future<Map<String, dynamic>?> generateQuiz(String homeTeam, String awayTeam) async {
    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('generateQuiz').call({
        'context': 'Confronto entre $homeTeam e $awayTeam'
      });
      
      final data = result.data;
      if (data['success'] == true) {
        return {
          'quizId': data['quizId'],
          'pergunta': data['question'],
          'opcoes': data['options'],
        };
      }
      return null;
    } catch (e) {
      print('Erro ao gerar quiz com a IA: $e');
      throw e;
    }
  }
}
