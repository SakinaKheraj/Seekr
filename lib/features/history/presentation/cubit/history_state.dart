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

  HistoryState({required this.sessions});

}