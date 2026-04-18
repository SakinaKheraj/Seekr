import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/history/data/history_service.dart';
import 'package:seekr/features/history/presentation/cubit/history_cubit.dart';
import 'package:seekr/features/history/presentation/cubit/history_state.dart';
import 'package:seekr/features/drafting/data/drafting_service.dart';
import 'package:seekr/features/drafting/presentation/cubit/drafting_cubit.dart';
import 'package:seekr/features/drafting/presentation/cubit/drafting_state.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepo>();

    return BlocProvider(
      create: (_) =>
          HistoryCubit(historyService: HistoryService(authRepo: authRepo))
            ..loadHistory(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Archive',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: MyColors.primaryText,
          ),
        ),
        actions: [
          BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              if (state.sessions.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                onPressed: () => _showClearConfirmation(context),
              );
            },
          ),
          const SizedBox(width: 8),
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
              const SizedBox(height: 20),
              
              // ── Header Stats ───────────────────────────────────────────────
              BlocBuilder<HistoryCubit, HistoryState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MetaChip(
                          icon: Icons.chat_bubble_outline,
                          label: '${state.sessions.length} Sessions',
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),

              // ── Session List ──────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<HistoryCubit, HistoryState>(
                  builder: (context, state) {
                    if (state.isLoading && state.sessions.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.sessions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 64, color: MyColors.secondaryText.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No history found', style: GoogleFonts.poppins(color: MyColors.secondaryText)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<HistoryCubit>().loadHistory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.sessions.length,
                        itemBuilder: (context, index) {
                          final session = state.sessions[index];
                          return _HistoryCard(session: session);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MyColors.backgroundMid,
        title: Text('Clear Archive?', style: GoogleFonts.poppins(color: MyColors.primaryText)),
        content: Text('This will delete all your search history locally and on the server.', style: GoogleFonts.poppins(color: MyColors.secondaryText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<HistoryCubit>().clearHistory();
              Navigator.pop(dialogContext);
            }, 
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}

// ── Optimized History Card ───────────────────────────────────────────────────

class _HistoryCard extends StatefulWidget {
  final HistorySession session;
  const _HistoryCard({required this.session});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85), // Clean white glass instead of gray
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white), 
        boxShadow: const [
          BoxShadow(color: MyColors.shadowLight, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() => isExpanded = !isExpanded);
          if (isExpanded) {
            context.read<HistoryCubit>().loadSessionDetails(widget.session.sessionId);
          }
        },
        child: Column(
          children: [
            Row(
              children: [
                // Blue accent stripe
                Container(
                  width: 4,
                  height: 100, // Sufficient for the collapsed card height
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [MyColors.gradient1, MyColors.gradient2],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.session.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: MyColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.chevron_right, color: MyColors.secondaryText),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: MyColors.secondaryText.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(widget.session.time),
                              style: GoogleFonts.poppins(fontSize: 12, color: MyColors.secondaryText),
                            ),
                            const Spacer(),
                            _StatBadge(icon: Icons.message_outlined, count: widget.session.messageCount),
                            const SizedBox(width: 8),
                            _StatBadge(icon: Icons.link, count: widget.session.sourceCount),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // ── Expanded Message List ──────────────────────────────────────
            if (isExpanded)
              BlocBuilder<HistoryCubit, HistoryState>(
                builder: (context, state) {
                  final details = state.sessionDetails[widget.session.sessionId];
                  if (details == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: MyColors.gradient1.withOpacity(0.03), // Very faint blue
                      border: Border(top: BorderSide(color: MyColors.gradient1.withOpacity(0.1))),
                    ),
                    child: Column(
                      children: details.expand((msg) {
                        return [
                          // User Question (if available)
                          if ((msg['query'] ?? '').isNotEmpty)
                            _HistoryChatBubble(
                              text: msg['query'],
                              isUser: true,
                              sources: const [],
                            ),
                          // AI Answer
                          _HistoryChatBubble(
                            text: msg['answer'] ?? msg['text'] ?? '',
                            isUser: false,
                            sources: List<Map<String, dynamic>>.from(msg['sources'] ?? []),
                          ),
                        ];
                      }).toList(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month) return 'Today, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  const _StatBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MyColors.gradient1.withOpacity(0.08), // Subtle blue tint
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: MyColors.gradient2), // Themed icon
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: MyColors.primaryText),
          ),
        ],
      ),
    );
  }
}

// ── Optimized Bubble ─────────────────────────────────────────────────────────

class _HistoryChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>> sources;

  const _HistoryChatBubble({
    required this.text,
    required this.isUser,
    required this.sources,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUser
                ? [MyColors.userBubbleStart, MyColors.userBubbleEnd]
                : [MyColors.botBubbleStart, MyColors.botBubbleEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isUser 
              ? Text(
                  text,
                  style: GoogleFonts.poppins(fontSize: 14, color: MyColors.lightText, height: 1.4),
                )
              : MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.poppins(color: MyColors.primaryText, fontSize: 13, height: 1.5),
                    strong: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            if (!isUser && sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sources.map((s) => _HistorySourceChip(title: s['title'] ?? 'Source')).toList(),
                ),
              ),
            ],
            if (!isUser) 
              _BubbleActions(text: text),
          ],
        ),
      ),
    );
  }
}

class _BubbleActions extends StatelessWidget {
  final String text;
  const _BubbleActions({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drafting Tab
          _SmallIconButton(
            icon: Icons.drive_file_rename_outline, 
            onTap: () => _showDrafting(context, text),
          ),
          const SizedBox(width: 8),
          // Copy
          _SmallIconButton(
            icon: Icons.copy, 
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), behavior: SnackBarBehavior.floating));
            },
          ),
        ],
      ),
    );
  }

  void _showDrafting(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (_) => DraftingCubit(draftingService: DraftingService(authRepo: context.read<AuthRepo>())),
        child: _DraftingView(text: text),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: MyColors.secondaryText),
      ),
    );
  }
}

// ── Reusable Component: Source Chip ──────────────────────────────────────────

class _HistorySourceChip extends StatelessWidget {
  final String title;
  const _HistorySourceChip({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        title.length > 15 ? '${title.substring(0, 15)}...' : title,
        style: GoogleFonts.poppins(fontSize: 10, color: MyColors.secondaryText),
      ),
    );
  }
}

// ── Reusable Component: Meta Chip ─────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MyColors.backgroundMid.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MyColors.secondaryText),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: MyColors.primaryText, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Drafting View (Re-integrated cleanup) ─────────────────────────────────────

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
            Text('Drafting Lab', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.primaryText)),
            const SizedBox(height: 24),
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
                  if (state.isLoading) return const Center(child: CircularProgressIndicator());
                  if (state.error != null) return Center(child: Text(state.error!, style: const TextStyle(color: Colors.redAccent)));
                  if (state.draftResult == null) return const Center(child: Icon(Icons.auto_fix_high, size: 64, color: Colors.white10));

                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, // Clean white background for drafting text
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: MyColors.gradient1.withOpacity(0.2))
                          ),
                          child: SingleChildScrollView(
                            child: MarkdownBody(
                              data: state.draftResult!,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.poppins(color: MyColors.primaryText, fontSize: 13, height: 1.5),
                                strong: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: MyColors.gradient3, fontSize: 14), // Dark blue for contrast
                                listBullet: const TextStyle(color: MyColors.gradient2, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: MyColors.gradient1, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.draftResult!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft copied')));
                        },
                        icon: const Icon(Icons.content_copy, color: Colors.white),
                        label: const Text('Copy Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              color: Colors.white, // Clean white icon background
              shape: BoxShape.circle, 
              border: Border.all(color: MyColors.gradient1.withOpacity(0.4))
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
