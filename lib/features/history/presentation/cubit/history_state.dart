class HistorySession {
  final String title;
  final int messageCount;
  final int sourceCount;
  final String time;

  HistorySession({
    required this.title,
    required this.messageCount,
    required this.sourceCount,
    required this.time,
  });
}

class HistoryState {
  final List<HistorySession> sessions;
  final bool isLoading;
  final String? error;

  HistoryState({
    required this.sessions,
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<HistorySession>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

}