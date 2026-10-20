import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoProvider {
  youtube('youtube'),
  cloudinary('cloudinary');

  final String value;
  const VideoProvider(this.value);

  static VideoProvider fromString(String? val) {
    if (val == null) return VideoProvider.youtube;
    return VideoProvider.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => VideoProvider.youtube,
    );
  }
}

class VideoItem {
  final String id;
  final String meetingId;
  final String classId;
  final String url;
  final VideoProvider provider;
  final String title;
  final String description;
  final String? thumbnail;
  final int? duration; // dalam detik

  const VideoItem({
    required this.id,
    required this.meetingId,
    required this.classId,
    required this.url,
    required this.provider,
    this.title = '',
    this.description = '',
    this.thumbnail,
    this.duration,
  });

  factory VideoItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return VideoItem.fromMap(doc.data() ?? {}, id: doc.id);
  }

  factory VideoItem.fromMap(Map<String, dynamic> map, {required String id}) {
    return VideoItem(
      id: id,
      meetingId: map['meeting_id'] as String? ?? '',
      classId: map['class_id'] as String? ?? '',
      url: map['url'] as String? ?? '',
      provider: VideoProvider.fromString(map['provider'] as String?),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      thumbnail: map['thumbnail'] as String?,
      duration: (map['duration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meeting_id': meetingId,
      'class_id': classId,
      'url': url,
      'provider': provider.value,
      if (title.isNotEmpty) 'title': title,
      if (description.isNotEmpty) 'description': description,
      'thumbnail': thumbnail,
      'duration': duration,
    };
  }

  VideoItem copyWith({
    String? meetingId,
    String? classId,
    String? url,
    VideoProvider? provider,
    String? title,
    String? description,
    String? thumbnail,
    int? duration,
  }) {
    return VideoItem(
      id: id,
      meetingId: meetingId ?? this.meetingId,
      classId: classId ?? this.classId,
      url: url ?? this.url,
      provider: provider ?? this.provider,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
    );
  }
}
