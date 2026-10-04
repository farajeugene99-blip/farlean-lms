import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class UserRepository {
  final FirebaseFirestore? _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil profil pengguna dari Firestore users/{uid}
  Future<AppUser?> getUser(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan baca user: $e');
    }
    return null;
  }

  /// Memperbarui nama profil pengguna dengan kepatuhan penuh pada Security Rules:
  /// Hanya mengirim ['name', 'photo_url', 'last_active']
  /// Field role, account_type, email, dan mfa_enabled TIDAK disentuh.
  Future<bool> updateName(String uid, String newName, {String? photoUrl}) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      throw ArgumentError('Nama harus berupa teks antara 1 hingga 100 karakter.');
    }

    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final updates = <String, dynamic>{
        'name': trimmed,
        'photo_url': photoUrl,
        'last_active': FieldValue.serverTimestamp(),
      };

      await firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      debugPrint('Gagal memperbarui nama pengguna: $e');
      rethrow;
    }
  }

  /// Mengambil data identitas privat (NIM/NIP) dari users/{uid}/private/identity
  Future<String?> getPrivateIdentity(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('identity')
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['nim_nip'] as String?;
      }
    } catch (e) {
      debugPrint('Catatan baca private identity: $e');
    }
    return null;
  }

  /// Menyimpan atau memperbarui identitas privat (NIM/NIP) di users/{uid}/private/identity
  Future<bool> setPrivateIdentity(String uid, String nimNip) async {
    final cleanNimNip = nimNip.trim();
    if (cleanNimNip.isEmpty) {
      throw ArgumentError('NIM/NIP tidak boleh kosong.');
    }

    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('identity')
          .set({
        'nim_nip': cleanNimNip,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Gagal menyimpan private identity: $e');
      rethrow;
    }
  }
}
