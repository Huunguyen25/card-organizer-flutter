import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // Prepopulate folders
    await db.insert('folders', {'name': 'Hearts'});
    await db.insert('folders', {'name': 'Spades'});
    await db.insert('folders', {'name': 'Diamonds'});
    await db.insert('folders', {'name': 'Clubs'});

    // Prepopulate all 52 cards with image URLs
    List<String> suits = ['H', 'S', 'D', 'C'];
    List<String> suitNames = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    List<String> ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

    List<Map<String, dynamic>> initialCards = [];

    for (int i = 0; i < suits.length; i++) {
      String suit = suits[i];
      String suitName = suitNames[i];
      for (String rank in ranks) {
        initialCards.add({
          'name': '$rank of $suitName',
          'suit': suitName,
          'imageUrl': 'https://deckofcardsapi.com/static/img/$rank$suit.png',
          'folderId': null
        });
      }
    }

    for (var card in initialCards) {
      await db.insert('cards', card);
    }
  }

  Future<List<Map<String, dynamic>>> fetchFolders() async {
    final db = await instance.database;
    // Fetch folders along with the count of cards
    final List<Map<String, dynamic>> folderList = await db.rawQuery('''
      SELECT folders.*, COUNT(cards.id) AS cardCount
      FROM folders
      LEFT JOIN cards ON cards.folderId = folders.id
      GROUP BY folders.id
    ''');

    return folderList;
  }

  Future<List<Map<String, dynamic>>> fetchCardsForFolder(int folderId) async {
    final db = await instance.database;
    return await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
  }

  Future<int> insertFolder(Map<String, dynamic> folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder);
  }

  Future<int> insertCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    return await db.insert('cards', card);
  }

  Future<void> deleteCard(int cardId) async {
    final db = await instance.database;
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<void> updateCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    await db.update(
      'cards',
      card,
      where: 'id = ?',
      whereArgs: [card['id']],
    );
  }
}
