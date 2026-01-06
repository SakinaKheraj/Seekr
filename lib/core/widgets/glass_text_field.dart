import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seekr/core/theme/colors.dart';

class GlassChatField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const GlassChatField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MyColors.glassBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: MyColors.glassBorder,
              ),
              boxShadow: const [
                BoxShadow(
                  color: MyColors.shadowLight,
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                      color: MyColors.primaryText,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: TextStyle(
                        color: MyColors.secondaryText,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                SizedBox(
                  width: 38,
                  height: 38,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          MyColors.gradient1,
                          MyColors.gradient2,
                        ],
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(
                        Icons.send,
                        color: MyColors.iconLight,
                      ),
                      onPressed: onSend,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
