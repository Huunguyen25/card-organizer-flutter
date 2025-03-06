class Card {
  final int id;
  final String name;
  final String suit;
  final int value;
  final String imageUrl;
  final int? folderId;

  Card({
    required this.id,
    required this.name,
    required this.suit,
    required this.value,
    required this.imageUrl,
    this.folderId,
  });

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      value: map['value'],
      imageUrl: map['imageUrl'],
      folderId: map['folderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'value': value,
      'imageUrl': imageUrl,
      'folderId': folderId,
    };
  }

  Card copyWith({int? folderId}) {
    return Card(
      id: id,
      name: name,
      suit: suit,
      value: value,
      imageUrl: imageUrl,
      folderId: folderId ?? this.folderId,
    );
  }
}
