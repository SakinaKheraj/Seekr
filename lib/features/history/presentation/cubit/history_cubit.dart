import 'package:flutter_bloc/flutter_bloc.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState>{
  HistoryCubit()
    : super(
      HistoryState(
        sessions: [
          HistorySession(title: title, messageCount: messageCount, sourceCount: sourceCount, time: time)
        ]
        )
    )
}