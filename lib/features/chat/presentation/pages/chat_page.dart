import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/routes/app_routes.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/core/widgets/glass_text_field.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/authentication/presentation/cubits/auth_cubit.dart';
import 'package:seekr/features/chat/data/chat_service.dart';
import 'package:seekr/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:seekr/features/chat/presentation/cubit/chat_state.dart';
import 'package:seekr/features/collections/presentation/cubits/collections_cubit.dart';
import 'package:seekr/features/drafting/data/drafting_service.dart';
import 'package:seekr/features/drafting/presentation/cubit/drafting_cubit.dart';
import 'package:seekr/features/drafting/presentation/cubit/drafting_state.dart';

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
            icon: const Icon(Icons.bookmark_border),
            color: MyColors.iconDark,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.collections);
            },
          ),
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
                          originalQuery: msg.originalQuery ?? '',
                          sources: msg.sources ?? [],
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
  final String originalQuery;
  final List<Map<String, dynamic>> sources;

  const _ChatBubble({
    required this.text, 
    required this.isUser,
    this.originalQuery = '',
    this.sources = const [],
  });

  void _showBookmarkSheet(BuildContext context) {
    final folderController = TextEditingController(text: 'Favorites');
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.backgroundMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bContext).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save Bookmark',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: folderController,
              style: const TextStyle(color: MyColors.primaryText),
              decoration: InputDecoration(
                labelText: 'Folder Name',
                labelStyle: const TextStyle(color: MyColors.secondaryText),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: MyColors.glassBorder)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: MyColors.gradient2)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.gradient1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final folder = folderController.text.trim();
                  if (folder.isNotEmpty) {
                    context.read<CollectionsCubit>().saveBookmark(
                      folderName: folder,
                      query: originalQuery,
                      answer: text,
                      sources: sources,
                    );
                    Navigator.pop(bContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved to $folder')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDraftingSheet(BuildContext context) {
    final draftingService = DraftingService(authRepo: context.read<AuthRepo>());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (_) => DraftingCubit(draftingService: draftingService),
        child: _DraftingView(text: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser
                ? const [MyColors.userBubbleStart, MyColors.userBubbleEnd]
                : const [MyColors.botBubbleStart, MyColors.botBubbleEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isUser 
              ? Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MyColors.lightText,
                    height: 1.4,
                  ),
                )
              : MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.poppins(
                      color: MyColors.primaryText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    strong: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser)
                    InkWell(
                      onTap: () => _showBookmarkSheet(context),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.bookmark_add_outlined, size: 16, color: MyColors.secondaryText),
                      ),
                    ),
                  if (!isUser) const SizedBox(width: 8),
                  if (!isUser)
                    InkWell(
                      onTap: () => _showDraftingSheet(context),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.drive_file_rename_outline, size: 16, color: MyColors.secondaryText),
                      ),
                    ),
                  if (!isUser) const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: isUser ? MyColors.lightText.withOpacity(0.8) : MyColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drafting View Widget ───────────────────────────────────────────────────────

class _DraftingView extends StatelessWidget {
  final String text;
  const _DraftingView({required this.text});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: MyColors.backgroundMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              'Drafting Lab',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.primaryText),
            ),
            const SizedBox(height: 8),
            const Text('Choose a format to transform this result', style: TextStyle(color: MyColors.secondaryText)),
            const SizedBox(height: 24),

            // Format chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DraftOption(icon: Icons.email_outlined, label: 'Email', onSelect: () => context.read<DraftingCubit>().createDraft(text: text, format: 'email')),
                _DraftOption(icon: Icons.article_outlined, label: 'Report', onSelect: () => context.read<DraftingCubit>().createDraft(text: text, format: 'markdown')),
                _DraftOption(icon: Icons.share_outlined, label: 'Social', onSelect: () => context.read<DraftingCubit>().createDraft(text: text, format: 'linkedin')),
                _DraftOption(icon: Icons.summarize_outlined, label: 'Summary', onSelect: () => context.read<DraftingCubit>().createDraft(text: text, format: 'summary')),
              ],
            ),
            
            const SizedBox(height: 32),

            Expanded(
              child: BlocBuilder<DraftingCubit, DraftingState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error != null) {
                    return Center(child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)));
                  }
                  if (state.draftResult == null) {
                    return Center(
                      child: Opacity(
                        opacity: 0.3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_fix_high, size: 64, color: MyColors.secondaryText),
                            const SizedBox(height: 16),
                            Text('Waiting for selection...', style: GoogleFonts.poppins(color: MyColors.secondaryText)),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: MyColors.gradient1.withOpacity(0.2))
                          ),
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: state.draftResult!,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.poppins(color: MyColors.primaryText, fontSize: 13, height: 1.5),
                                strong: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: MyColors.gradient3, fontSize: 14),
                                listBullet: const TextStyle(color: MyColors.gradient2, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.gradient1,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.draftResult!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft copied')));
                        },
                        icon: const Icon(Icons.content_copy, color: Colors.white),
                        label: const Text(
                          'Copy Draft',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
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

class _DraftOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onSelect;

  const _DraftOption({required this.icon, required this.label, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: MyColors.gradient1.withOpacity(0.4)), // Themed blue border
            ),
            child: Icon(icon, color: MyColors.gradient2, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: MyColors.secondaryText)),
        ],
      ),
    );
  }
}
