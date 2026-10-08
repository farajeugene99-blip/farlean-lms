import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/models/discussion.dart';
import 'package:mobile/repositories/discussion_repository.dart';

void main() {
  group('Discussion & DiscussionReply Model Tests', () {
    test('Discussion serialization and deserialization work consistently', () {
      final now = DateTime(2026, 10, 8, 14, 0);
      final discussion = Discussion(
        id: 'disc_01',
        classId: 'class_01',
        title: 'Tanya Algoritma Knapsack',
        body: 'Apakah greedy bisa optimal?',
        authorId: 'user_01',
        authorDisplayName: 'Budi Santoso',
        status: DiscussionStatus.active,
        replyCount: 3,
        lastActivityAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final map = discussion.toMap();
      expect(map['class_id'], equals('class_01'));
      expect(map['title'], equals('Tanya Algoritma Knapsack'));
      expect(map['body'], equals('Apakah greedy bisa optimal?'));
      expect(map['author_id'], equals('user_01'));
      expect(map['author_display_name'], equals('Budi Santoso'));
      expect(map['status'], equals('ACTIVE'));
      expect(map['reply_count'], equals(3));

      final fromMap = Discussion.fromMap(map, id: 'disc_01');
      expect(fromMap.id, equals('disc_01'));
      expect(fromMap.classId, equals('class_01'));
      expect(fromMap.title, equals('Tanya Algoritma Knapsack'));
      expect(fromMap.status, equals(DiscussionStatus.active));
      expect(fromMap.replyCount, equals(3));
    });

    test('DiscussionReply serialization and deserialization work consistently', () {
      final now = DateTime(2026, 10, 8, 14, 30);
      final reply = DiscussionReply(
        id: 'rep_01',
        discussionId: 'disc_01',
        authorId: 'user_02',
        authorDisplayName: 'Prof. Guru',
        body: 'Untuk 0/1 knapsack gunakan DP.',
        status: DiscussionStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final map = reply.toMap();
      expect(map['discussion_id'], equals('disc_01'));
      expect(map['author_id'], equals('user_02'));
      expect(map['author_display_name'], equals('Prof. Guru'));
      expect(map['body'], equals('Untuk 0/1 knapsack gunakan DP.'));
      expect(map['status'], equals('ACTIVE'));

      final fromMap = DiscussionReply.fromMap(map, id: 'rep_01');
      expect(fromMap.id, equals('rep_01'));
      expect(fromMap.body, equals('Untuk 0/1 knapsack gunakan DP.'));
      expect(fromMap.status, equals(DiscussionStatus.active));
    });

    test('DiscussionStatus fromString handles case variations and defaults to active', () {
      expect(DiscussionStatus.fromString('ACTIVE'), equals(DiscussionStatus.active));
      expect(DiscussionStatus.fromString('active'), equals(DiscussionStatus.active));
      expect(DiscussionStatus.fromString('ARCHIVED'), equals(DiscussionStatus.archived));
      expect(DiscussionStatus.fromString('archived'), equals(DiscussionStatus.archived));
      expect(DiscussionStatus.fromString(null), equals(DiscussionStatus.active));
      expect(DiscussionStatus.fromString('UNKNOWN'), equals(DiscussionStatus.active));
    });
  });

  group('DiscussionRepository Validation Tests', () {
    late DiscussionRepository repository;

    setUp(() {
      repository = DiscussionRepository();
    });

    test('getDiscussions returns empty list safely when Firestore uninitialized', () async {
      final result = await repository.getDiscussions(classId: 'class_01');
      expect(result, isEmpty);
    });

    test('getDiscussion returns null safely when Firestore uninitialized', () async {
      final result = await repository.getDiscussion('disc_01');
      expect(result, isNull);
    });

    test('getReplies returns empty list safely when Firestore uninitialized', () async {
      final result = await repository.getReplies(discussionId: 'disc_01');
      expect(result, isEmpty);
    });

    test('createThread throws ArgumentError on empty or invalid inputs', () {
      expect(() => repository.createThread(classId: '', title: 'Judul', body: 'Isi'), throwsArgumentError);
      expect(() => repository.createThread(classId: 'c1', title: 'ab', body: 'Isi'), throwsArgumentError);
      expect(() => repository.createThread(classId: 'c1', title: 'Judul', body: 'ab'), throwsArgumentError);
    });

    test('postReply throws ArgumentError on empty inputs', () {
      expect(() => repository.postReply(discussionId: '', body: 'Balasan'), throwsArgumentError);
      expect(() => repository.postReply(discussionId: 'd1', body: ''), throwsArgumentError);
    });

    test('ApiConfig has valid discussion endpoint URLs', () {
      expect(ApiConfig.discussionThreadUrl, contains('/api/discussion-thread'));
      expect(ApiConfig.discussionReplyUrl, contains('/api/discussion-reply'));
    });
  });
}
