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

  Future<Map<String, String>> getApiKeys() async {
    final docSnap = await _db.collection('settings').doc('api_keys').get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      return {
        'api_football': data['api_football']?.toString() ?? '',
        'mercado_pago': data['mercado_pago']?.toString() ?? '',
        'z_api': data['z_api']?.toString() ?? '',
      };
    }
    return {
      'api_football': '',
      'mercado_pago': '',
      'z_api': '',
    };
  }

  Future<void> saveApiKeys(Map<String, String> keys) async {
    await _db.collection('settings').doc('api_keys').set(keys, SetOptions(merge: true));
  }
}
