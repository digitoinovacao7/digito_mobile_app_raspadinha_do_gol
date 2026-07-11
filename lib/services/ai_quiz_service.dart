import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

final aiQuizServiceProvider = Provider<AiQuizService>((ref) {
  return AiQuizService();
});

class AiQuizService {
  Future<Map<String, dynamic>?> generateQuiz(String homeTeam, String awayTeam) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('generateQuiz');
      final response = await callable.call({
        'context': 'Confronto entre $homeTeam e $awayTeam'
      });
      
      var data = response.data;
      if (data is Map && data.containsKey('result')) {
        data = data['result'];
      }
      
      if (data != null && data['success'] == true) {
        return {
          'quizId': data['quizId'],
          'pergunta': data['question'],
          'opcoes': data['options'],
        };
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Erro na função de gerar quiz: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao gerar quiz com a IA: $e');
    }
  }
}
