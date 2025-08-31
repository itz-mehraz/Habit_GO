class QuoteModel {
  final String id;
  final String text;
  final String author;
  final bool isFavorite;

  QuoteModel({
    required this.id,
    required this.text,
    required this.author,
    this.isFavorite = false,
  });

  factory QuoteModel.fromMap(Map<String, dynamic> map, String id) {
    return QuoteModel(
      id: id,
      text: map['text'] ?? '',
      author: map['author'] ?? 'Unknown',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'isFavorite': isFavorite,
    };
  }

  QuoteModel copyWith({
    bool? isFavorite,
  }) {
    return QuoteModel(
      id: id,
      text: text,
      author: author,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
