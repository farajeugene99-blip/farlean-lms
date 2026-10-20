import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/class_group.dart';
import '../models/class_member.dart';

class GroupRepository {
  final FirebaseFirestore? _firestore;

  GroupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Mengambil semua kelompok dalam suatu kelas
  Future<List<ClassGroup>> getGroups(String classId) async {
    final cleanClassId = classId.trim();
    if (cleanClassId.isEmpty || cleanClassId == 'default_class') return [];

    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('groups')
          .get();

      final list = snapshot.docs
          .map((doc) => ClassGroup.fromFirestore(doc, classId: cleanClassId))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('Catatan baca groups: $e');
      rethrow;
    }
  }

  /// Mengambil anggota kelas aktif yang belum memiliki kelompok
  Future<List<ClassMember>> getAvailableMembers(String classId) async {
    final cleanClassId = classId.trim();
    if (cleanClassId.isEmpty || cleanClassId == 'default_class') return [];

    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
          .collection('classes')
          .doc(cleanClassId)
          .collection('members')
          .where('status', isEqualTo: 'active')
          .get();

      final allMembers = snapshot.docs.map((doc) => ClassMember.fromFirestore(doc)).toList();
      // Filter di memori: HANYA anggota MAHASISWA aktif yang belum memiliki kelompok
      return allMembers.where((m) =>
          m.accountType == AccountType.mahasiswa &&
          m.status == MemberStatus.active &&
          (m.groupId == null || m.groupId!.isEmpty)
      ).toList();
    } catch (e) {
      debugPrint('Catatan baca available members: $e');
      rethrow;
    }
  }

  /// Membuat kelompok baru secara ATOMIK (menyimpan dokumen grup + mengupdate group_id pada tiap member)
  Future<String> createGroup({
    required String classId,
    required String name,
    String? leaderUid,
    required List<ClassMember> members,
  }) async {
    final cleanClassId = classId.trim();
    final cleanName = name.trim();
    if (cleanClassId.isEmpty) throw ArgumentError('classId tidak boleh kosong.');
    if (cleanName.isEmpty) throw ArgumentError('Nama kelompok tidak boleh kosong.');

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    final groupRef = firestore.collection('classes').doc(cleanClassId).collection('groups').doc();

    final memberUids = members.map((m) => m.uid).toList();
    final Map<String, String> memberNames = {
      for (final m in members) m.uid: m.displayName,
    };

    final group = ClassGroup(
      id: groupRef.id,
      classId: cleanClassId,
      name: cleanName,
      leaderUid: leaderUid,
      memberUids: memberUids,
      memberNames: memberNames,
    );

    final batch = firestore.batch();
    batch.set(groupRef, group.toMap());

    // Update group_id pada dokumen setiap member di kelas
    final membersCollection = firestore.collection('classes').doc(cleanClassId).collection('members');
    for (final member in members) {
      batch.update(membersCollection.doc(member.uid), {'group_id': groupRef.id});
    }

    try {
      await batch.commit();
      return groupRef.id;
    } catch (e) {
      debugPrint('Gagal membuat group: $e');
      rethrow;
    }
  }

  /// Memperbarui informasi kelompok & keanggotaan secara ATOMIK
  Future<void> updateGroup({
    required String classId,
    required String groupId,
    required String name,
    String? leaderUid,
    required List<ClassMember> newMembers,
    required List<String> removedMemberUids,
  }) async {
    final cleanClassId = classId.trim();
    final cleanGroupId = groupId.trim();
    final cleanName = name.trim();
    if (cleanClassId.isEmpty || cleanGroupId.isEmpty) throw ArgumentError('ID tidak valid.');
    if (cleanName.isEmpty) throw ArgumentError('Nama kelompok tidak boleh kosong.');

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    final groupRef = firestore.collection('classes').doc(cleanClassId).collection('groups').doc(cleanGroupId);
    final membersCollection = firestore.collection('classes').doc(cleanClassId).collection('members');

    final memberUids = newMembers.map((m) => m.uid).toList();
    final Map<String, String> memberNames = {
      for (final m in newMembers) m.uid: m.displayName,
    };

    final batch = firestore.batch();
    batch.update(groupRef, {
      'name': cleanName,
      'leader_uid': (leaderUid != null && leaderUid.isNotEmpty) ? leaderUid : FieldValue.delete(),
      'member_uids': memberUids,
      'member_names': memberNames,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Tetapkan group_id untuk anggota yang baru ditambahkan
    for (final m in newMembers) {
      batch.update(membersCollection.doc(m.uid), {'group_id': cleanGroupId});
    }

    // Hapus group_id untuk anggota yang dikeluarkan
    for (final uid in removedMemberUids) {
      batch.update(membersCollection.doc(uid), {'group_id': FieldValue.delete()});
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Gagal update group: $e');
      rethrow;
    }
  }

  /// Menghapus kelompok secara ATOMIK (menghapus dokumen grup + menghapus group_id dari seluruh anggotanya)
  Future<void> deleteGroup({
    required String classId,
    required String groupId,
    required List<String> memberUids,
  }) async {
    final cleanClassId = classId.trim();
    final cleanGroupId = groupId.trim();
    if (cleanClassId.isEmpty || cleanGroupId.isEmpty) throw ArgumentError('ID tidak valid.');

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    final groupRef = firestore.collection('classes').doc(cleanClassId).collection('groups').doc(cleanGroupId);
    final membersCollection = firestore.collection('classes').doc(cleanClassId).collection('members');

    final batch = firestore.batch();
    batch.delete(groupRef);

    for (final uid in memberUids) {
      batch.update(membersCollection.doc(uid), {'group_id': FieldValue.delete()});
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Gagal menghapus group: $e');
      rethrow;
    }
  }

  /// Menyimpan sejumlah kelompok acak sekaligus secara ATOMIK
  Future<void> createRandomizedGroups({
    required String classId,
    required List<ClassGroup> groups,
  }) async {
    final cleanClassId = classId.trim();
    if (cleanClassId.isEmpty) throw ArgumentError('classId tidak boleh kosong.');
    if (groups.isEmpty) return;

    final firestore = _firestore;
    if (firestore == null) throw StateError('Firestore belum diinisialisasi.');

    final batch = firestore.batch();
    final groupsCollection = firestore.collection('classes').doc(cleanClassId).collection('groups');
    final membersCollection = firestore.collection('classes').doc(cleanClassId).collection('members');

    for (final group in groups) {
      final docRef = group.id.isNotEmpty ? groupsCollection.doc(group.id) : groupsCollection.doc();
      final effectiveGroup = group.id.isNotEmpty ? group : group.copyWith(id: docRef.id);
      batch.set(docRef, effectiveGroup.toMap());

      for (final uid in effectiveGroup.memberUids) {
        batch.update(membersCollection.doc(uid), {'group_id': docRef.id});
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Gagal menyimpan kelompok acak: $e');
      rethrow;
    }
  }
}
