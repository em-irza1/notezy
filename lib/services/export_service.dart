import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/note_model.dart';

class ExportService {
  ExportService._();

  static Future<Uint8List> _buildPdf(NoteModel note) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Notezy', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Your note is ready to export.',
                  style: const pw.TextStyle(fontSize: 15),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> saveNoteAsPdf(NoteModel note) async {
    final bytes = await _buildPdf(note);

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFileName(note.title)}.pdf',
    );
  }

  static Future<void> printNote(NoteModel note) async {
    final bytes = await _buildPdf(note);

    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareNoteAsPdf(NoteModel note) async {
    final bytes = await _buildPdf(note);

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFileName(note.title)}.pdf',
    );
  }

  static Future<void> saveNoteAsDocx(NoteModel note) async {
    // DOCX export will be added separately.
    // This keeps the project compiling while we build the main editor.
  }

  static String _safeFileName(String title) {
    final cleaned = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    return cleaned.isEmpty ? 'notezy_note' : cleaned;
  }
}
