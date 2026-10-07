import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/class_member.dart';
import '../models/classroom.dart';

class ClassRepository {
  final http.Client _httpClient;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  ClassRepository({
    http.Client? httpClient,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _httpClient = httpClient ?? http.Client(),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
        _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null);

  Future<String?> _getIdToken() async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Mengambil daftar kelas pengguna (yang dimiliki dan yang diikuti)
  Future<Map<String, List<Classroom>>> getMyClasses() async {
    final token = await _getIdToken();
    if (token != null) {
      try {
        final response = await _httpClient.get(
          Uri.parse(ApiConfig.myClassesUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final ownedList = (data['owned'] as List? ?? [])
              .map((c) => Classroom.fromMap(c as Map<String, dynamic>, id: c['id'] ?? ''))
              .toList();
          final joinedList = (data['joined'] as List? ?? [])
              .map((c) => Classroom.fromMap(c as Map<String, dynamic>, id: c['id'] ?? ''))
              .toList();

          return {'owned': ownedList, 'joined': joinedList};
        }
      } catch (e) {
        debugPrint('Catatan getMyClasses backend fallback: $e');
      }
    }

    // Fallback direct Firestore
    final firestore = _firestore;
    final uid = _auth?.currentUser?.uid;
    if (firestore == null || uid == null) {
      return {'owned': [], 'joined': []};
    }

    try {
      final ownedSnap = await firestore
          .collection('classes')
          .where('teacher_id', isEqualTo: uid)
          .get();

      final owned = ownedSnap.docs.map(Classroom.fromFirestore).toList();
      return {'owned': owned, 'joined': []};
    } catch (e) {
      debugPrint('Catatan Firestore getMyClasses: $e');
      return {'owned': [], 'joined': []};
    }
  }

  /// Mengambil detail satu kelas berdasarkan ID
  Future<Classroom?> getClass(String classId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection('classes').doc(classId).get();
      if (doc.exists) {
        return Classroom.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Catatan getClass: $e');
      rethrow;
    }
    return null;
  }

  /// Membuat kelas baru melalui Backend API (menjamin transaksi atomik kode kelas)
  Future<Classroom> createClass({
    required String name,
    String description = '',
    String? customCode,
  }) async {
    final token = await _getIdToken();
    if (token == null) {
      throw StateError('Sesi pengguna tidak valid. Silakan login terlebih dahulu.');
    }

    final response = await _httpClient.post(
      Uri.parse(ApiConfig.createClassUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name.trim(),
        'description': description.trim(),
        if (customCode != null && customCode.trim().isNotEmpty)
          'customCode': customCode.trim().toUpperCase(),
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201) {
      return Classroom(
        id: data['classId'] ?? '',
        name: data['name'] ?? name,
        code: data['code'] ?? '',
        description: description,
        teacherId: data['teacherId'] ?? _auth?.currentUser?.uid ?? '',
        status: 'Active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      throw StateError(data['error'] ?? 'Gagal membuat kelas.');
    }
  }

  /// Memperbarui informasi nama dan deskripsi kelas
  Future<void> updateClass(Classroom classroom) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('classes').doc(classroom.id).update({
        'name': classroom.name,
        'description': classroom.description,
        'status': classroom.status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Catatan updateClass: $e');
      rethrow;
    }
  }

  /// Mengarsipkan kelas
  Future<void> archiveClass(String classId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('classes').doc(classId).update({
        'status': 'Archived',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Catatan archiveClass: $e');
      rethrow;
    }
  }

  /// Mengaktifkan kembali kelas yang berstatus Archived
  Future<void> reactivateClass(String classId) async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore.collection('classes').doc(classId).update({
        'status': 'Active',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Catatan reactivateClass: $e');
      rethrow;
    }
  }

  /// Mengambil daftar anggota kelas dengan perlindungan privasi
  Future<List<ClassMember>> getClassMembers(String classId) async {
    final token = await _getIdToken();
    if (token != null) {
      try {
        final uri = Uri.parse('${ApiConfig.classMembersUrl}?classId=$classId');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final list = (data['members'] as List? ?? []).map((m) {
            return ClassMember.fromMap(m as Map<String, dynamic>, uid: m['uid'] ?? '');
          }).toList();
          return list;
        }
      } catch (e) {
        debugPrint('Catatan getClassMembers backend fallback: $e');
      }
    }

    // Fallback direct Firestore
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snap = await firestore
          .collection('classes')
          .doc(classId)
          .collection('members')
          .get();

      return snap.docs.map(ClassMember.fromFirestore).toList();
    } catch (e) {
      debugPrint('Catatan getClassMembers: $e');
      return [];
    }
  }
}
