import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/chat/data/chat_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState>{
  final ChatService chatService;
  
  ChatCubit({required this.chatService})
    : super(const ChatState(messages: []));

    //sends a message and updates the state
    Future<void> sendMessage(String text) async {
      if(text.trim().isEmpty) return;

      // add user message to state
      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(ChatMessage(text: text, isUser: true));

      emit(state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        error: null,
      ));

      try {
        // call backend chat service
        final aiResponse = await chatService.sendQuery(text);

        // add ai response to state
        final newMessages = List<ChatMessage>.from(state.messages)
          ..add(ChatMessage(text: aiResponse, isUser: false));

        emit(state.copyWith(
          messages: newMessages,
          isLoading: false,
          error: null,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          error: e.toString(),
        ));
      }
    }

    
}