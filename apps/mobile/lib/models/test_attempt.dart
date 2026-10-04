import 'package:cloud_firestore/cloud_firestore.dart';

enum AttemptStatus {
  inProgress('in_progress'),
  submitted('submitted'),
  graded('graded');

  final String value;
  const AttemptStatus(this.value);

  static AttemptStatus fromString(String? val) {
    if (val == null) return AttemptStatus.inProgress;
    return AttemptStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => AttemptStatus.inProgress,
    );
  }

  bool get isInProgress => this == AttemptStatus.inProgress;
  bool get isSubmitted => this == AttemptStatus.submitted;
  bool get isGraded => this == AttemptStatus.graded;
}

class TestAttempt {
  final String id;
  final String userId;
  final String testId;
  final String classId;
  final int attemptNo;
  final Map<String, dynamic> answers; // qid -> answer
  final List<String> questionOrder; // urutan soal tersimpan untuk konsistensi recovery
  final double? score;
  final AttemptStatus status;
  final DateTime? startedAt;
  final DateTime? submittedAt;

  const TestAttempt({
    required this.id,
    required this.userId,
    required this.testId,
    required this.classId,
    required this.attemptNo,
    this.answers = const {},
    this.questionOrder = const [],
    this.score,
    this.status = AttemptStatus.inProgress,
    this.startedAt,
    this.submittedAt,
  });

  factory TestAttempt.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TestAttempt.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory TestAttempt.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawAnswers = map['answers'];
    final Map<String, dynamic> parsedAnswers = {};
    if (rawAnswers is Map) {
      rawAnswers.forEach((k, v) => parsedAnswers[k.toString()] = v);
    }

    final rawOrder = map['question_order'];
    final List<String> parsedOrder = [];
    if (rawOrder is List) {
      for (final q in rawOrder) {
        if (q != null) parsedOrder.add(q.toString());
      }
    }

    return TestAttempt(
      id: id,
      userId: map['user_id'] as String? ?? '',
      testId: map['test_id'] as String? ?? '',
      classId: map['class_id'] as String? ?? '',
      attemptNo: (map['attempt_no'] as num?)?.toInt() ?? 1,
      answers: parsedAnswers,
      questionOrder: parsedOrder,
      score: (map['score'] as num?)?.toDouble(),
      status: AttemptStatus.fromString(map['status'] as String?),
      startedAt: parseDate(map['started_at']),
      submittedAt: parseDate(map['submitted_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'test_id': testId,
      'class_id': classId,
      'attempt_no': attemptNo,
      'answers': answers,
      'question_order': questionOrder,
      'score': score,
      'status': status.value,
      'started_at': startedAt != null ? Timestamp.fromDate(startedAt!) : FieldValue.serverTimestamp(),
      'submitted_at': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
    };
  }

  TestAttempt copyWith({
    Map<String, dynamic>? answers,
    double? score,
    AttemptStatus? status,
    DateTime? submittedAt,
  }) {
    return TestAttempt(
      id: id,
      userId: userId,
      testId: testId,
      classId: classId,
      attemptNo: attemptNo,
      answers: answers ?? this.answers,
      questionOrder: questionOrder,
      score: score ?? this.score,
      status: status ?? this.status,
      startedAt: startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
