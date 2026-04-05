// Clean model for bookmarks

class BookmarkSource {
  final String title;
  final String link;

  BookmarkSource({required this.title, required this.link});

  factory BookmarkSource.fromJson(Map<String, dynamic> json) {
    return BookmarkSource(
      title: json['title'] as String? ?? 'Source',
      link: json['link'] as String? ?? '',
    );
  }
}

class BookmarkItem {
  final String id;
  final String query;
  final String answer;
  final List<BookmarkSource> sources;
  final String createdAt;

  BookmarkItem({
    required this.id,
    required this.query,
    required this.answer,
    required this.sources,
    required this.createdAt,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List<dynamic>? ?? [];
    return BookmarkItem(
      id: json['id'] as String? ?? '',
      query: json['query'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      sources: rawSources.map((e) => BookmarkSource.fromJson(e)).toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
