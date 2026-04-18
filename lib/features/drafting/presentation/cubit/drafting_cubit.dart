import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/drafting/data/drafting_service.dart';
import 'drafting_state.dart';

class DraftingCubit extends Cubit<DraftingState> {
  final DraftingService _draftingService;

  DraftingCubit({required DraftingService draftingService})
      : _draftingService = draftingService,
        super(const DraftingState());

  Future<void> createDraft({required String text, required String format}) async {
    emit(state.copyWith(isLoading: true, error: null, draftResult: null));
    try {
      final result = await _draftingService.generateDraft(text: text, format: format);
      emit(state.copyWith(isLoading: false, draftResult: result));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(state.copyWith(isLoading: false, error: errorMessage));
    }
  }

  void reset() {
    emit(const DraftingState());
  }
}
