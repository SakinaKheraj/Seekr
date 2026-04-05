import 'package:seekr/features/collections/data/models/bookmark_model.dart';

class CollectionsState {
  final Map<String, List<BookmarkItem>> folders;
  final bool isLoading;
  final String? error;

  const CollectionsState({
    this.folders = const <String, List<BookmarkItem>>{},
    this.isLoading = false,
    this.error,
  });

  CollectionsState copyWith({
    Map<String, List<BookmarkItem>>? folders,
    bool? isLoading,
    String? error,
  }) {
    return CollectionsState(
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
