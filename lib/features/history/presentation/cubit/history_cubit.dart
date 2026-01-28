import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/history/data/history_service.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final HistoryService _historyService;

  HistoryCubit({required HistoryService historyService})
      : _historyService = historyService,
        super(HistoryState(sessions: const []));

  Future<void> loadHistory() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final historyItems = await _historyService.getHistory();

      final sessions = historyItems.map((item) {
        return HistorySession(
          title: item['last_message'] as String? ?? 'Session',
          messageCount: item['message_count'] as int? ?? 0,
          sourceCount: item['source_count'] as int? ?? 0,
          time: item['timestamp'] as String? ?? '',
        );
      }).toList();

      emit(
        state.copyWith(
          sessions: sessions,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }
}