enum ContentStatus {
  draft('Draft'),
  published('Published'),
  archived('Archived');

  final String value;
  const ContentStatus(this.value);

  static ContentStatus fromString(String? val) {
    if (val == null) return ContentStatus.draft;
    return ContentStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == val.toLowerCase(),
      orElse: () => ContentStatus.draft,
    );
  }

  bool get isDraft => this == ContentStatus.draft;
  bool get isPublished => this == ContentStatus.published;
  bool get isArchived => this == ContentStatus.archived;
}
