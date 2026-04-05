import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/collections/data/collections_service.dart';
import 'package:seekr/features/collections/presentation/cubits/collections_state.dart';
import 'package:seekr/features/collections/data/models/bookmark_model.dart';

class CollectionsCubit extends Cubit<CollectionsState> {
  final CollectionsService _collectionsService;

  CollectionsCubit({required CollectionsService collectionsService})
      : _collectionsService = collectionsService,
        super(const CollectionsState());

  Future<void> loadCollections() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final folders = await _collectionsService.getCollections();
      emit(state.copyWith(folders: folders, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> saveBookmark({
    required String folderName,
    required String query,
    required String answer,
    required List<Map<String, dynamic>> sources,
  }) async {
    try {
      await _collectionsService.saveBookmark(
        folderName: folderName,
        query: query,
        answer: answer,
        sources: sources,
      );
      // newly saved item is visible if they open the page
      await loadCollections();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> deleteBookmark(String folderName, String bookmarkId) async {
    try {
      await _collectionsService.deleteBookmark(bookmarkId);
      
      // Optimistic update with correct types
      final Map<String, List<BookmarkItem>> currentFolders = 
        state.folders.map((key, value) => MapEntry(key, List<BookmarkItem>.from(value)));

      if (currentFolders.containsKey(folderName)) {
        currentFolders[folderName]!.removeWhere((item) => item.id == bookmarkId);
        if (currentFolders[folderName]!.isEmpty) {
          currentFolders.remove(folderName);
        }
      }
      
      emit(state.copyWith(folders: currentFolders));
      // Real reload to ensure sync
      await loadCollections();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
