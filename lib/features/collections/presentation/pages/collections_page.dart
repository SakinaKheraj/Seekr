import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seekr/core/theme/colors.dart';
import 'package:seekr/features/collections/presentation/cubits/collections_cubit.dart';
import 'package:seekr/features/collections/presentation/cubits/collections_state.dart';
import 'package:seekr/features/collections/data/models/bookmark_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CollectionsView();
  }
}

class _CollectionsView extends StatelessWidget {
  const _CollectionsView();

  void _shareFolder(
    BuildContext context,
    String folderName,
    List<BookmarkItem> bookmarks,
  ) {
    if (bookmarks.isEmpty) return;

    final StringBuffer sb = StringBuffer();
    sb.writeln('📂 *${folderName.toUpperCase()} - Seekr Collection*');
    sb.writeln('Shared via Seekr AI\n');

    for (var i = 0; i < bookmarks.length; i++) {
      final b = bookmarks[i];
      sb.writeln('📍 *${i + 1}. ${b.query}*');
      sb.writeln('${b.answer}\n');
      
      if (b.sources.isNotEmpty) {
        sb.writeln('🔗 *Sources:*');
        for (var s in b.sources) {
          sb.writeln('• ${s.title}: ${s.link}');
        }
      }
      if (i < bookmarks.length - 1) {
        sb.writeln('\n───────────────────\n');
      }
    }

    Share.share(
      sb.toString(),
      subject: 'Seekr Collection: $folderName',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: MyColors.iconDark,
          onPressed: () => Navigator.of(context).pop(),
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
              'Collections',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: MyColors.primaryText,
              ),
            ),
          ],
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
        child: SafeArea(
          child: BlocBuilder<CollectionsCubit, CollectionsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Text(
                    'Error: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (state.folders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Color.fromARGB(255, 16, 44, 137),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No collections yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Color.fromARGB(255, 16, 44, 137),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                itemCount: state.folders.keys.length,
                itemBuilder: (context, index) {
                  final folderName = state.folders.keys.elementAt(index);
                  final items = state.folders[folderName]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(220, 255, 255, 255),
                          Color.fromARGB(180, 240, 243, 255),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: MyColors.glassBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(25, 0, 0, 0),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          folderName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: MyColors.primaryText,
                          ),
                        ),
                        subtitle: Text(
                          '${items.length} Informations',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: MyColors.secondaryText,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.ios_share,
                                size: 20,
                                color: MyColors.primaryText,
                              ),
                              onPressed: () =>
                                  _shareFolder(context, folderName, items),
                            ),
                            const Icon(
                              Icons.expand_more,
                              color: MyColors.primaryText,
                            ),
                          ],
                        ),
                        children: items
                            .map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: MyColors.glassBorder,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  title: Text(
                                    item.query,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: MyColors.primaryText,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      item.answer,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: MyColors.secondaryText,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => DraggableScrollableSheet(
                                        expand: false,
                                        initialChildSize: 0.72,
                                        minChildSize: 0.4,
                                        maxChildSize: 0.95,
                                        builder: (context, scrollController) => Container(
                                          decoration: BoxDecoration(
                                            color: MyColors.backgroundStart,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(28),
                                                ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color.fromARGB(
                                                  40,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                blurRadius: 24,
                                                offset: Offset(0, -8),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              20,
                                              20,
                                              0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: Container(
                                                    width: 50,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: MyColors
                                                          .secondaryText
                                                          .withOpacity(0.35),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 18),
                                                Text(
                                                  item.query,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: MyColors.primaryText,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    controller:
                                                        scrollController,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.answer,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 15,
                                                                color: MyColors
                                                                    .primaryText,
                                                                height: 1.6,
                                                              ),
                                                        ),
                                                        if (item
                                                            .sources
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 18,
                                                          ),
                                                          Text(
                                                            'Sources',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: MyColors
                                                                  .primaryText,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Wrap(
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            children: item.sources
                                                                .map(
                                                                  (source) => ActionChip(
                                                                    backgroundColor: Colors.white,
                                                                    elevation: 0,
                                                                    side: const BorderSide(color: MyColors.glassBorder),
                                                                    label: Text(
                                                                      source.title,
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.w500,
                                                                        color: MyColors.gradient3,
                                                                        decoration: TextDecoration.underline,
                                                                      ),
                                                                    ),
                                                                    onPressed: () async {
                                                                      String urlString = source.link;
                                                                      // Prepend https if missing
                                                                      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                                                                        urlString = 'https://$urlString';
                                                                      }
                                                                      
                                                                      try {
                                                                        final url = Uri.parse(urlString);
                                                                        if (await canLaunchUrl(url)) {
                                                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                                                        } else {
                                                                          if (context.mounted) {
                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              const SnackBar(content: Text('Could not open link in browser')),
                                                                            );
                                                                          }
                                                                        }
                                                                      } catch (e) {
                                                                        if (context.mounted) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(content: Text('Invalid URL: $urlString')),
                                                                          );
                                                                        }
                                                                      }
                                                                    },
                                                                  ),
                                                                )
                                                                .toList(),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              MyColors
                                                                  .gradient1,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                vertical: 14,
                                                              ),
                                                          child: Text(
                                                            'Close',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    OutlinedButton(
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: MyColors
                                                              .gradient3,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        context
                                                            .read<
                                                              CollectionsCubit
                                                            >()
                                                            .deleteBookmark(
                                                              folderName,
                                                              item.id,
                                                            );
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 14,
                                                            ),
                                                        child: Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: MyColors
                                                                .gradient3,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
