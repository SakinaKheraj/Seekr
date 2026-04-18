import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/chat/data/chat_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState>{
  final ChatService chatService;
  
  ChatCubit({required this.chatService})
    : super(const ChatState(messages: []));

    //sends a message and updates the state
    Future<void> sendMessage(String text) async {
      if(text.trim().isEmpty || state.isLoading) return;

      // add user message to state and clear previous follow-ups
      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(ChatMessage(text: text, isUser: true));

      emit(state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        error: null,
        followups: [],
      ));

      try {
        // call backend chat service — returns record with answer + followups
        final result = await chatService.sendQuery(text);

        // add ai response to state
        final newMessages = List<ChatMessage>.from(state.messages)
          ..add(ChatMessage(
            text: result.answer, 
            isUser: false,
            originalQuery: text,
            sources: result.sources,
          ));

        emit(state.copyWith(
          messages: newMessages,
          isLoading: false,
          error: null,
          followups: result.followups,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          error: e.toString(),
          followups: [],
        ));
      }
    }

    
}