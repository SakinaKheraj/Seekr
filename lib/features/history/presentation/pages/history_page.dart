import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/features/authentication/domain/repos/auth_repo.dart';
import 'package:seekr/features/history/data/history_service.dart';
import 'package:seekr/features/history/presentation/cubit/history_cubit.dart';
import 'package:seekr/features/history/presentation/cubit/history_state.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: MyColors.primaryText,
          ),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///  Session count
            BlocBuilder<HistoryCubit, HistoryState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Sessions: ${state.sessions.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: MyColors.primaryText,
                    ),
                  ),
                );
              },
            ),

            ///  History list
            Expanded(
              child: BlocBuilder<HistoryCubit, HistoryState>(
                builder: (context, state) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      return _HistoryTile(
                        sessionTitle: session.title,
                        messageCount: session.messageCount,
                        sourceCount: session.sourceCount,
                        time: session.time,
                      );
                    },
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

class _HistoryTile extends StatelessWidget {
  final String sessionTitle;
  final int messageCount;
  final int sourceCount;
  final String time;

  const _HistoryTile({
    required this.sessionTitle,
    required this.messageCount,
    required this.sourceCount,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  MyColors.gradient1,
                  MyColors.gradient2,
                ],
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: MyColors.iconLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MyColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MetaChip(
                      icon: Icons.message_outlined,
                      label: '$messageCount msgs',
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: Icons.link,
                      label: '$sourceCount sources',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: MyColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.copy,
              size: 16,
              color: MyColors.secondaryText,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: sessionTitle));
              messenger.showSnackBar(
                const SnackBar(content: Text('Session title copied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MyColors.backgroundMid,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: MyColors.secondaryText),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: MyColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
