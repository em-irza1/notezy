class NoteModel {
  String id;
  String title;
  String contentJson;
  int colorIndex;
  DateTime updatedAt;

  NoteModel({
    required this.id,
    this.title = '',
    this.contentJson = '',
    this.colorIndex = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}
