class Folder {
  final int id;
  final String name;
  final String createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
    };
  }

  Folder copyWith({String? name}) {
    return Folder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }
}
