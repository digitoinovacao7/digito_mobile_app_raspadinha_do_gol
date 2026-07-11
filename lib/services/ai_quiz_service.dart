import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';

final aiQuizServiceProvider = Provider<AiQuizService>((ref) {
  return AiQuizService();
});

class AiQuizService {
  final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<Map<String, dynamic>?> generateQuiz(
    String homeTeam,
    String awayTeam,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado no FirebaseAuth local.');
      }

      final callable = functions.httpsCallable('generateQuiz');
      final result = await callable.call({
        'context': 'Confronto entre $homeTeam e $awayTeam',
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] == true) {
        return {
          'quizId': data['quizId'],
          'pergunta': data['question'],
          'opcoes': List<String>.from(data['options'] as List),
        };
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      log('Erro Cloud Function no Quiz: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Erro ao gerar o Quiz.');
    } catch (e) {
      log('Erro geral no Quiz: $e');
      throw Exception('Falha ao gerar o Quiz. Tente novamente.');
    }
  }

  Future<Map<String, dynamic>> answerQuiz({
    required String quizId,
    required int answerId,
    required String fixtureId,
    required String matchName,
  }) async {
    try {
      final callable = functions.httpsCallable('answerQuiz');
      final result = await callable.call({
        'quizId': quizId,
        'answerId': answerId,
        'fixtureId': fixtureId,
        'matchName': matchName,
      });

      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      log('Erro ao responder Quiz: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Erro ao responder o Quiz.');
    } catch (e) {
      log('Erro geral ao responder Quiz: $e');
      throw Exception('Falha ao responder o Quiz. Tente novamente.');
    }
  }
}
