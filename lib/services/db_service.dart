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

  Future<int> claimAdReward() async {
    final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('claimAdReward');
    final result = await callable.call();
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erro ao resgatar recompensa.');
    }
    return (data['amount'] as num?)?.toInt() ?? 250;
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
    final prizeId = redemptionData['prizeId']?.toString();
    if (prizeId == null || prizeId.isEmpty) {
      throw Exception('ID do prêmio ausente.');
    }

    final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('redeemPrize');
    final result = await callable.call({
      'prizeId': prizeId,
      'prizeName': prizeName,
      'userName': redemptionData['userName'],
      'userEmail': redemptionData['userEmail'],
      'userPhone': redemptionData['userPhone'],
      'userCpf': redemptionData['userCpf'],
      'address': redemptionData['address'],
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Erro ao resgatar prêmio.');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserScratchHistory(String uid) {
    return _db
        .collection('scratch_history')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(50)
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
    final secretSnap =
        await _db.collection('private_settings').doc('secrets').get();
    if (secretSnap.exists && secretSnap.data()!.containsKey('api_keys')) {
      return secretSnap.data()!['api_keys'] as Map<String, dynamic>;
    }
    final docSnap = await _db.collection('settings').doc('general').get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data.containsKey('api_keys')) {
        return data['api_keys'] as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<void> requestPixOtp(String pixKey, int amountTokens, double amountReal, String phone) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('requestPixOtp');
    final result = await callable.call({
      'pixKey': pixKey,
      'amount': amountTokens,
      'amountReal': amountReal,
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

  Future<Map<String, dynamic>> createBolaoActivationPix({
    required String bolaoName,
    double amount = 4.90,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('createBolaoActivationPix');
    final result = await callable.call({
      'bolaoName': bolaoName,
      'amount': amount,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> checkBolaoActivationPixStatus({
    required int paymentId,
    required String activationId,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('checkBolaoActivationPixStatus');
    final result = await callable.call({
      'paymentId': paymentId,
      'activationId': activationId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> activateBolaoWithTokens() async {
    final callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1')
        .httpsCallable('activateBolaoWithTokens');
    final result = await callable.call();
    return Map<String, dynamic>.from(result.data as Map);
  }
}
