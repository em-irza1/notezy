import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class FormattingToolbar extends StatelessWidget {
  final quill.QuillController controller;

  const FormattingToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8C5D1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _button(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onPressed: () {
                controller.formatSelection(quill.Attribute.bold);
              },
            ),

            _button(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onPressed: () {
                controller.formatSelection(quill.Attribute.italic);
              },
            ),

            _button(
              icon: Icons.format_underlined_rounded,
              tooltip: 'Underline',
              onPressed: () {
                controller.formatSelection(quill.Attribute.underline);
              },
            ),

            const SizedBox(width: 4),

            _button(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet list',
              onPressed: () {
                controller.formatSelection(quill.Attribute.ul);
              },
            ),

            _button(
              icon: Icons.format_list_numbered_rounded,
              tooltip: 'Numbered list',
              onPressed: () {
                controller.formatSelection(quill.Attribute.ol);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: const Color(0xFF806572)),
      ),
    );
  }
}
