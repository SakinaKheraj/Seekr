class ChatMessage {
  final String text;
  final bool isUser;
  final String? originalQuery;
  final List<Map<String, dynamic>>? sources;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.originalQuery,
    this.sources,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final List<String> followups;

  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
    this.followups = const [],
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    List<String>? followups,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      followups: followups ?? this.followups,
    );
  }
}
