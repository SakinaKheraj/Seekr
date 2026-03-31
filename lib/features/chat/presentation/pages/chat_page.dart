import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/routes/app_routes.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/core/widgets/glass_text_field.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/chat/data/chat_service.dart';
import 'package:seekr/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:seekr/features/chat/presentation/cubit/chat_state.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepo>();

    return BlocProvider(
      create: (_) => ChatCubit(
        chatService: ChatService(authRepo: authRepo),
      ),
      child: BlocListener<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: const _ChatView(),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().sendMessage(text);
    messageController.clear();
    _scrollToBottom();
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
          child: BlocConsumer<ChatCubit, ChatState>(
            listener: (context, state) {
              // Auto-scroll whenever messages or loading state changes
              _scrollToBottom();
            },
            builder: (context, state) {
              return Column(
                children: [
                  const SizedBox(height: 70),

                  // ── Message list ──────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.messages.length +
                          (state.isLoading ? 1 : 0),  // +1 for typing indicator
                      itemBuilder: (context, index) {
                        if (index == state.messages.length && state.isLoading) {
                          return const _TypingIndicator();
                        }
                        final msg = state.messages[index];
                        return _ChatBubble(
                          text: msg.text,
                          isUser: msg.isUser,
                        );
                      },
                    ),
                  ),

                  // ── Follow-up chips ───────────────────────────────────
                  if (state.followups.isNotEmpty)
                    _FollowupChipsRow(
                      followups: state.followups,
                      onTap: (q) => _sendMessage(context, q),
                    ),

                  // ── Input field ───────────────────────────────────────
                  GlassChatField(
                    controller: messageController,
                    onSend: () => _sendMessage(context, messageController.text.trim()),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Typing indicator widget ────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )
        ..repeat(reverse: true, period: const Duration(milliseconds: 900));
    });

    // stagger each dot by 200 ms
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }

    _animations = _controllers
        .map((c) => Tween<double>(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MyColors.botBubbleStart, MyColors.botBubbleEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _animations[i],
              builder: (context, child) => Opacity(
                opacity: _animations[i].value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: MyColors.primaryText,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Follow-up chips row ────────────────────────────────────────────────────────

class _FollowupChipsRow extends StatelessWidget {
  final List<String> followups;
  final void Function(String) onTap;

  const _FollowupChipsRow({
    required this.followups,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: followups
              .where((q) => q.isNotEmpty)
              .map((q) => _FollowupChip(question: q, onTap: () => onTap(q)))
              .toList(),
        ),
      ),
    );
  }
}

class _FollowupChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;

  const _FollowupChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [MyColors.gradient1, MyColors.gradient2],
          ),
          backgroundBlendMode: BlendMode.srcOver,
          border: Border.all(
            color: MyColors.glassBorder,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, size: 14, color: MyColors.iconLight),
            const SizedBox(width: 6),
            Text(
              question,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MyColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat bubble ────────────────────────────────────────────────────────────────

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
        constraints: const BoxConstraints(maxWidth: 260),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 36, 10),
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
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.copy,
                  size: 16,
                  color: isUser ? MyColors.iconLight : MyColors.secondaryText,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
