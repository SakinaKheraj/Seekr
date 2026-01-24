class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatState {
  final List<ChatMessage> messages;

  ChatState({required this.messages});

}