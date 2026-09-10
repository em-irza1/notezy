enum AiRefineAction { polish, shorten, expand, fixGrammar }

extension AiRefineActionExtension on AiRefineAction {
  String get label {
    switch (this) {
      case AiRefineAction.polish:
        return 'Polish writing';
      case AiRefineAction.shorten:
        return 'Make it shorter';
      case AiRefineAction.expand:
        return 'Expand ideas';
      case AiRefineAction.fixGrammar:
        return 'Fix grammar';
    }
  }

  String get emoji {
    switch (this) {
      case AiRefineAction.polish:
        return '✨';
      case AiRefineAction.shorten:
        return '✂️';
      case AiRefineAction.expand:
        return '💡';
      case AiRefineAction.fixGrammar:
        return '📝';
    }
  }
}

class AiRefineService {
  AiRefineService._();

  static Future<String> refine({
    required String plainText,
    required AiRefineAction action,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final text = plainText.trim();

    if (text.isEmpty) {
      return text;
    }

    switch (action) {
      case AiRefineAction.polish:
        return _polish(text);

      case AiRefineAction.shorten:
        return _shorten(text);

      case AiRefineAction.expand:
        return _expand(text);

      case AiRefineAction.fixGrammar:
        return _fixGrammar(text);
    }
  }

  static String _polish(String text) {
    String result = text;

    // Clean up unnecessary spaces.
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Fix spaces before punctuation.
    result = result.replaceAll(RegExp(r'\s+([,.!?;:])'), r'$1');

    // Make sure the first character is capitalized.
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    // Make sure the note ends with punctuation.
    if (result.isNotEmpty && !RegExp(r'[.!?]$').hasMatch(result)) {
      result += '.';
    }

    return result;
  }

  static String _shorten(String text) {
    final words = text.split(RegExp(r'\s+'));

    if (words.length <= 20) {
      return text;
    }

    return '${words.take(20).join(' ')}…';
  }

  static String _expand(String text) {
    return '$text\n\nMore details:\n'
        '• Add important information or examples.\n'
        '• Explain the main idea in more detail.\n'
        '• Add any useful points or conclusions.';
  }

  static String _fixGrammar(String text) {
    String result = text;

    // Clean repeated spaces.
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Remove spaces before punctuation.
    result = result.replaceAll(RegExp(r'\s+([,.!?;:])'), r'$1');

    // Add a space after punctuation when missing.
    result = result.replaceAllMapped(
      RegExp(r'([,.!?;:])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    // Capitalize the first letter of the note.
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    // Capitalize letters after sentence-ending punctuation.
    result = result.replaceAllMapped(
      RegExp(r'([.!?]\s+)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );

    // Common basic corrections.
    final corrections = <String, String>{
      ' i ': ' I ',
      ' im ': " I'm ",
      ' dont ': " don't ",
      ' cant ': " can't ",
      ' wont ': " won't ",
      ' isnt ': " isn't ",
      ' doesnt ': " doesn't ",
      ' didnt ': " didn't ",
      ' wasnt ': " wasn't ",
      ' werent ': " weren't ",
      ' youre ': " you're ",
      ' theyre ': " they're ",
      ' its ': " it's ",
      ' thats ': " that's ",
    };

    for (final entry in corrections.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Fix accidental duplicated spaces again after replacements.
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

    return result;
  }
}
