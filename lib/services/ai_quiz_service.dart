import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

final aiQuizServiceProvider = Provider<AiQuizService>((ref) {
  return AiQuizService();
});

class AiQuizService {
  Future<Map<String, dynamic>?> generateQuiz(String homeTeam, String awayTeam) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuário não autenticado.");
      }
      final idToken = await user.getIdToken();

      final dio = Dio();
      final response = await dio.post(
        'https://us-central1-raspadinhadogol.cloudfunctions.net/generateQuiz',
        data: {
          'data': {
            'context': 'Confronto entre $homeTeam e $awayTeam'
          }
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      final data = response.data['result'];
      if (data != null && data['success'] == true) {
        return {
          'quizId': data['quizId'],
          'pergunta': data['question'],
          'opcoes': data['options'],
        };
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data['error'];
        if (errorData != null && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Erro de conexão ao gerar quiz: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao gerar quiz com a IA: $e');
    }
  }
}
