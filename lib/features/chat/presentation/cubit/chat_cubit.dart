import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState>{
  ChatCubit() :
    super(
      ChatState(
        messages: [
          ChatMessage(
            text: "Hello! I'm Seekr, your AI assistant. How can I help you today?",
            isUser: false,
          ),
        ],
      ),
    );

    void sendMessage(String text) {
      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(ChatMessage(text: text, isUser: true));

        emit(ChatState(messages: updatedMessages));
    }
}