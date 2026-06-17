import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> addTokens(String uid, int amount) async {
    await _db.collection('users').doc(uid).update({
      'tokens': FieldValue.increment(amount),
    });
  }

  Future<void> addTokenTransaction(String uid, int amount, String type, String description) async {
    await _db.collection('token_transactions').add({
      'uid': uid,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordQuizSuccess(String uid, int fixtureId, int reward, String matchName) async {
    await _db.collection('users').doc(uid).update({
      'tokens': FieldValue.increment(reward),
      'answered_quizzes_count.$fixtureId': FieldValue.increment(1),
    });
    await addTokenTransaction(uid, reward, 'quiz_reward', 'Acerto no Quiz: $matchName');
  }

  Future<void> recordQuizFailure(String uid, int fixtureId, String matchName) async {
    await _db.collection('users').doc(uid).update({
      'answered_quizzes_count.$fixtureId': FieldValue.increment(1),
    });
    await addTokenTransaction(uid, 0, 'quiz_failure', 'Erro no Quiz: $matchName');
  }

  Future<void> toggleWhatsappNotifications(String uid, bool value) async {
    await _db.collection('users').doc(uid).update({
      'wants_whatsapp_notifications': value,
    });
  }

  Future<void> redeemPrize(String uid, int cost, Map<String, dynamic> redemptionData, String prizeName) async {
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
      
      transaction.update(userRef, {
        'tokens': currentTokens - cost,
      });
      
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
    final docSnap = await _db.collection('system_config').doc('general').get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data.containsKey('api_keys')) {
        return data['api_keys'] as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> getEconomySettings() async {
    final docSnap = await _db.collection('system_config').doc('general').get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      if (data.containsKey('economy')) {
        return data['economy'] as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<void> saveApiKeys(Map<String, String> keys) async {
    await _db.collection('settings').doc('api_keys').set(keys, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getPrizeRules() async {
    final docSnap = await _db.collection('settings').doc('prize_rules').get();
    if (docSnap.exists) {
      return docSnap.data()!;
    }
    return {
      'prize_value': 0.0,
      'total_prizes': 0,
      'batch_size': 0,
    };
  }

  Future<void> savePrizeRules(Map<String, dynamic> rules) async {
    await _db.collection('settings').doc('prize_rules').set(rules, SetOptions(merge: true));
  }
}

