import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  multipleChoice('multiple_choice'),
  essay('essay');

  final String value;
  const QuestionType(this.value);

  static QuestionType fromString(String? val) {
    if (val == null) return QuestionType.multipleChoice;
    return QuestionType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => QuestionType.multipleChoice,
    );
  }
}

/// Model soal untuk konsumsi client.
/// ATURAN KEAMANAN: Model ini TIDAK MEMUAT kunci jawaban atau penjelasan.
/// Kunci jawaban disimpan terisolasi di koleksi `answer_keys` yang hanya dapat diakses oleh server.
class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final int points;
  final String tag;

  const Question({
    required this.id,
    required this.text,
    this.type = QuestionType.multipleChoice,
    this.options = const [],
    this.points = 10,
    this.tag = 'general',
  });

  factory Question.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Question.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory Question.fromMap(Map<String, dynamic> map, {required String id}) {
    final rawOptions = map['options'];
    final List<String> parsedOptions = [];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt != null) parsedOptions.add(opt.toString());
      }
    }

    return Question(
      id: id,
      text: map['text'] as String? ?? '',
      type: QuestionType.fromString(map['type'] as String?),
      options: parsedOptions,
      points: (map['points'] as num?)?.toInt() ?? 10,
      tag: map['tag'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.value,
      'options': options,
      'points': points,
      'tag': tag,
    };
  }
}
