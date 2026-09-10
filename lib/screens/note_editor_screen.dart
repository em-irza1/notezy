import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../services/note_storage_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NotesyNote? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController titleController;
  late final QuillController quillController;
  final FocusNode editorFocusNode = FocusNode();
  final ScrollController editorScrollController = ScrollController();
  bool _saving = false;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? '');
    if (widget.note != null) {
      final document = NoteStorageService.documentFromJson(
        widget.note!.content,
      );
      quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      quillController = QuillController.basic();
    }
    quillController.addListener(_editorChanged);
  }

  void _editorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    titleController.dispose();
    quillController.removeListener(_editorChanged);
    quillController.dispose();
    editorFocusNode.dispose();
    editorScrollController.dispose();
    super.dispose();
  }

  void _toggleFormat(Attribute attribute) {
    // Flutter Quill keeps a small "toggled style" for the next characters
    // when the cursor is collapsed. Using the same toggle pattern as Quill's
    // own toolbar makes Bold/Italic/Underline reliably switch OFF as well as ON.
    final attributes = quillController.getSelectionStyle().attributes;
    final isActive = attributes.containsKey(attribute.key);
    final nextAttribute = isActive
        ? Attribute.clone(attribute, null)
        : attribute;

    quillController
      ..skipRequestKeyboard = true
      ..formatSelection(nextAttribute);
    editorFocusNode.requestFocus();
    if (mounted) setState(() {});
  }

  void _toggleHighlight() {
    final attributes = quillController.getSelectionStyle().attributes;
    final isActive = attributes.containsKey(Attribute.background.key);
    final nextAttribute = isActive
        ? Attribute.clone(Attribute.background, null)
        : const BackgroundAttribute('#FFF1A8');

    quillController
      ..skipRequestKeyboard = true
      ..formatSelection(nextAttribute);
    editorFocusNode.requestFocus();
    if (mounted) setState(() {});
  }

  void _toggleBulletList() {
    final attributes = quillController.getSelectionStyle().attributes;
    final currentList = attributes[Attribute.ul.key];
    final isActive = currentList?.value == Attribute.ul.value;
    final nextAttribute = isActive
        ? Attribute.clone(Attribute.ul, null)
        : Attribute.ul;

    quillController
      ..skipRequestKeyboard = true
      ..formatSelection(nextAttribute);
    editorFocusNode.requestFocus();
    if (mounted) setState(() {});
  }

  void _clearFormatting() {
    final selection = quillController.selection;
    if (selection.isCollapsed) {
      // Clear formatting that would otherwise be inherited by newly typed text.
      quillController.toggledStyle = const Style();
    } else {
      // For selected text, remove the common inline/block formatting safely.
      quillController.formatSelection(null);
    }
    editorFocusNode.requestFocus();
    if (mounted) setState(() {});
  }

  void _undo() {
    quillController.undo();
    editorFocusNode.requestFocus();
  }

  void _redo() {
    quillController.redo();
    editorFocusNode.requestFocus();
  }

  bool _isActive(Attribute attribute) =>
      quillController.getSelectionStyle().attributes.containsKey(attribute.key);

  bool get _isEmptyNote =>
      titleController.text.trim().isEmpty &&
      quillController.document.toPlainText().trim().isEmpty;

  // Empty new notes are cancelled when Back is pressed.
  // Existing notes or notes containing content are saved automatically.
  Future<void> _handleBack() async {
    if (_saving) return;

    if (_isEmptyNote && !isEditing) {
      Navigator.pop(context, false);
      return;
    }

    final saved = await _saveNote();
    if (!mounted || !saved) return;
    Navigator.pop(context, true);
  }

  Future<bool> _saveNote() async {
    if (_saving) return false;

    final title = titleController.text.trim();
    final plainText = quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Write something before saving your note.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    setState(() => _saving = true);

    try {
      final note = NotesyNote(
        id: widget.note?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.isEmpty ? 'Untitled Note' : title,
        content: NoteStorageService.documentToJson(quillController.document),
        updatedAt: DateTime.now(),
        favorite: widget.note?.favorite ?? false,
      );

      await NoteStorageService.saveNote(note);

      if (!mounted) return true;
      setState(() => _saving = false);
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the note. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Future<void> _saveAndClose() async {
    final saved = await _saveNote();
    if (!mounted || !saved) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF5),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF806572)),
          onPressed: _saving ? null : _handleBack,
        ),
        title: Text(
          isEditing ? 'Edit Note' : 'New Note',
          style: const TextStyle(
            color: Color(0xFF66515A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _saving ? null : _saveAndClose,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFB85C7A),
                    ),
                  )
                : const Icon(Icons.check_rounded, color: Color(0xFF806572)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screenWidth < 500 ? 20 : 28,
            12,
            screenWidth < 500 ? 20 : 28,
            18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF66515A),
                ),
                decoration: const InputDecoration(
                  hintText: 'Note title',
                  hintStyle: TextStyle(color: Color(0xFFB8A6AD)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: Color(0xFFE8D6DD), height: 1),
              const SizedBox(height: 10),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEDDE3)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _formatButton(
                        icon: Icons.format_bold_rounded,
                        selected: _isActive(Attribute.bold),
                        onPressed: () => _toggleFormat(Attribute.bold),
                      ),
                      _formatButton(
                        icon: Icons.format_italic_rounded,
                        selected: _isActive(Attribute.italic),
                        onPressed: () => _toggleFormat(Attribute.italic),
                      ),
                      _formatButton(
                        icon: Icons.format_underline_rounded,
                        selected: _isActive(Attribute.underline),
                        onPressed: () => _toggleFormat(Attribute.underline),
                      ),
                      _formatButton(
                        icon: Icons.highlight_rounded,
                        selected: _isActive(Attribute.background),
                        onPressed: _toggleHighlight,
                      ),
                      const VerticalDivider(
                        color: Color(0xFFE8D6DD),
                        width: 18,
                        indent: 10,
                        endIndent: 10,
                      ),
                      _formatButton(
                        icon: Icons.format_list_bulleted_rounded,
                        selected: _isActive(Attribute.ul),
                        onPressed: _toggleBulletList,
                      ),
                      _formatButton(icon: Icons.undo_rounded, onPressed: _undo),
                      _formatButton(icon: Icons.redo_rounded, onPressed: _redo),
                      _formatButton(
                        icon: Icons.format_clear_rounded,
                        onPressed: _clearFormatting,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0DFE5)),
                  ),
                  child: QuillEditor(
                    controller: quillController,
                    focusNode: editorFocusNode,
                    scrollController: editorScrollController,
                    config: const QuillEditorConfig(
                      placeholder: 'Start writing your note...',
                      padding: EdgeInsets.zero,
                      scrollable: true,
                      expands: false,
                      autoFocus: false,
                      enableInteractiveSelection: true,
                      enableSelectionToolbar: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    return IconButton(
      tooltip: icon == Icons.format_clear_rounded
          ? 'Clear formatting'
          : 'Formatting',
      onPressed: onPressed,
      splashRadius: 20,
      icon: Icon(
        icon,
        size: 20,
        color: selected ? const Color(0xFFB85C7A) : const Color(0xFF806572),
      ),
    );
  }
}
