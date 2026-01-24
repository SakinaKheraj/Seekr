import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/routes/app_routes.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/core/widgets/glass_text_field.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:seekr/features/chat/presentation/cubit/chat_state.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ChatCubit(), child: const _ChatView());
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({super.key});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: MyColors.iconDark,
          onPressed: () {
            context.read<AuthCubit>().logout();
          },
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [MyColors.gradient1, MyColors.gradient2],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: MyColors.iconLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Seekr',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: MyColors.primaryText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            color: MyColors.iconDark,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.history);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: MyColors.iconDark,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyColors.backgroundStart,
              MyColors.backgroundMid,
              MyColors.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 70),

              Expanded(
                child: BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return _ChatBubble(
                          text: msg.text,
                          isUser: msg.isUser,
                        );
                      },
                    );
                  },
                ),
              ),

              GlassChatField(
                controller: messageController,
                onSend: () {
                  final text = messageController.text.trim();
                  if (text.isEmpty) return;
                  context.read<ChatCubit>().sendMessage(text);
                  messageController.clear();
                  // later: send message via cubit
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser
                ? const [MyColors.userBubbleStart, MyColors.userBubbleEnd]
                : const [MyColors.botBubbleStart, MyColors.botBubbleEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? MyColors.lightText : MyColors.primaryText,
          ),
        ),
      ),
    );
  }
}
