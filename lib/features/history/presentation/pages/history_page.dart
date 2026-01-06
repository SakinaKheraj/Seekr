import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const int totalSessions = 1; // Dummy data
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: MyColors.primaryText)),
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
            // session count
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Total Sessions: $totalSessions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MyColors.primaryText,
                ),
              ),
            ),

            // history list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return const _HistoryTile(
                    sessionTitle: 'Flutter Project Ideas',
                    messageCount: 5,
                    sourceCount: 3,
                    time: 'Yesterday, 3:45 PM',

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
          // Session icon
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

          // Session info
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

          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: MyColors.secondaryText,
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
