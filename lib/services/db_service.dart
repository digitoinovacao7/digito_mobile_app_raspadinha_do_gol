import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/app_user.dart';

class DbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AppUser> createOrUpdateUser(AppUser user) async {
    final docRef = _db.collection('users').doc(user.id);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // Usuário existe, pegar o objeto atualizado do banco
      return AppUser.fromMap(docSnap.data()!, user.id);
    } else {
      // Primeiro login, criar
      await docRef.set(user.toMap());
      return user;
    }
  }

  Future<AppUser?> getUser(String uid) async {
    final docSnap = await _db.collection('users').doc(uid).get();
    if (docSnap.exists) {
      return AppUser.fromMap(docSnap.data()!, uid);
    }
    return null;
  }

  Future<void> updateUserProfile(AppUser user) async {
    await _db.collection('users').doc(user.id).update({
      'name': user.name,
      if (user.phone != null) 'phone': user.phone,
      if (user.cpf != null) 'cpf': user.cpf,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> addTokens(String uid, int amount) async {
    await _db.collection('users').doc(uid).update({
      'tokens': FieldValue.increment(amount),
    });
  }

  Future<void> addTokenTransaction(
    String uid,
    int amount,
    String type,
    String description,
  ) async {
    await _db.collection('token_transactions').add({
      'uid': uid,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markWatchingMatch({
    required String uid,
    required int fixtureId,
    required String homeTeam,
    required String awayTeam,
  }) async {
    await _db.collection('users').doc(uid).set({
      'watching_fixture_id': fixtureId,
      'watching_home_team': homeTeam,
      'watching_away_team': awayTeam,
      'watching_match_started_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleWhatsappNotifications(String uid, bool value) async {
    await _db.collection('users').doc(uid).update({
      'wants_whatsapp_notifications': value,
    });
  }

  Future<void> incrementQuizCount(String uid, String fixtureId) async {
    await _db.collection('users').doc(uid).set({
      'answered_quizzes_count': {
        fixtureId: FieldValue.increment(1),
      }
    }, SetOptions(merge: true));
  }

  Future<void> redeemPrize(
    String uid,
    int cost,
    Map<String, dynamic> redemptionData,
    String prizeName,
  ) async {
    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(uid);
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception("Usuário não encontrado.");
      }

      final currentTokens = snapshot.data()?['tokens'] as int? ?? 0;
      if (currentTokens < cost) {
        throw Exception("Saldo insuficiente.");
      }

      transaction.update(userRef, {'tokens': currentTokens - cost});

      final redemptionRef = _db.collection('redemptions').doc();
      transaction.set(redemptionRef, {
        ...redemptionData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final txRef = _db.collection('token_transactions').doc();
      transaction.set(txRef, {
        'uid': uid,
        'amount': -cost,
        'type': 'prize_redemption',
        'description': 'Resgate de Prêmio: $prizeName',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Map<String, dynamic>>> getUserScratchHistory(String uid) {
    return _db
        .collection('scratch_history')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  Future<Map<String, dynamic>> getApiKeys() async {
    final docSnap = await _db.collection('settings').doc('general').get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data.containsKey('api_keys')) {
        return data['api_keys'] as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<void> requestPixOtp(String pixKey, int amount, String phone) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('requestPixOtp');
    final result = await callable.call({
      'pixKey': pixKey,
      'amount': amount,
      'phone': phone,
    });
    final data = result.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erro ao solicitar OTP');
    }
  }

  Future<void> validatePixOtpAndWithdraw(String otp) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('validatePixOtpAndWithdraw');
    final result = await callable.call({'otp': otp});
    final data = result.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erro ao validar OTP');
    }
  }
}
