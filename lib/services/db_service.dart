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

