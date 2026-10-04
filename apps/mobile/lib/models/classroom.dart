import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  final String id;
  final String name;
  final String teacherId;

  const Classroom({
    required this.id,
    required this.name,
    required this.teacherId,
  });

  factory Classroom.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Classroom.fromMap(data, id: doc.id);
  }

  factory Classroom.fromMap(Map<String, dynamic> map, {required String id}) {
    return Classroom(
      id: id,
      name: map['name'] as String? ?? 'Kelas Tanpa Nama',
      teacherId: map['teacher_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teacher_id': teacherId,
    };
  }
}
