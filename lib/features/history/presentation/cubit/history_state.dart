class HistorySession {
  final String sessionId;
  final String title;
  final int messageCount;
  final int sourceCount;
  final String time;

  HistorySession({
    required this.sessionId,
    required this.title,
    required this.messageCount,
    required this.sourceCount,
    required this.time,
  });
}

class HistoryState {
  final List<HistorySession> sessions;
  final Map<String, List<Map<String, dynamic>>> sessionDetails; // {sessionId: [messages]}
  final bool isLoading;
  final String? error;

  HistoryState({
    required this.sessions,
    this.sessionDetails = const {},
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<HistorySession>? sessions,
    Map<String, List<Map<String, dynamic>>>? sessionDetails,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      sessionDetails: sessionDetails ?? this.sessionDetails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}