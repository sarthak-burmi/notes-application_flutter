class Note {
  String id;
  String title;
  String content;
  String ownerId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.ownerId,
  });

  factory Note.fromMap(Map<String, dynamic> data, String documentId) {
    return Note(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      ownerId: data['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'ownerId': ownerId,
    };
  }
}
