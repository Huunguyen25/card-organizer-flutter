import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/folder_model.dart';
import 'models/card_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create cards table
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        value INTEGER NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER,
        FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE
      )
    ''');

    // Insert default folders
    await db.insert(
        'folders', {'name': 'Hearts', 'createdAt': DateTime.now().toString()});
    await db.insert(
        'folders', {'name': 'Spades', 'createdAt': DateTime.now().toString()});
    await db.insert('folders',
        {'name': 'Diamonds', 'createdAt': DateTime.now().toString()});
    await db.insert(
        'folders', {'name': 'Clubs', 'createdAt': DateTime.now().toString()});

    // Prepopulate cards
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateCards(Database db) async {
    // Map card values to names
    Map<int, String> cardNames = {
      1: 'Ace',
      2: '2',
      3: '3',
      4: '4',
      5: '5',
      6: '6',
      7: '7',
      8: '8',
      9: '9',
      10: '10',
      11: 'Jack',
      12: 'Queen',
      13: 'King'
    };

    // Insert cards for each suit
    for (String suit in ['Hearts', 'Spades', 'Diamonds', 'Clubs']) {
      String suitLower = suit.toLowerCase();
      for (int i = 1; i <= 13; i++) {
        String cardName = cardNames[i]!;
        String imageUrl =
            'assets/png/${i == 1 ? 'ace' : i == 11 ? 'jack' : i == 12 ? 'queen' : i == 13 ? 'king' : i}_of_$suitLower.png';

        await db.insert('cards', {
          'name': '$cardName of $suit',
          'suit': suit,
          'value': i,
          'imageUrl': imageUrl,
          'folderId': null, // Initially not in any folder
        });
      }
    }
  }

  // Folder CRUD operations
  Future<List<Folder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');

    return List.generate(maps.length, (i) {
      return Folder.fromMap(maps[i]);
    });
  }

  Future<Folder> getFolder(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('folders', where: 'id = ?', whereArgs: [id]);

    return Folder.fromMap(maps.first);
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Card CRUD operations
  Future<List<Card>> getCardsInFolder(int folderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );

    return List.generate(maps.length, (i) {
      return Card.fromMap(maps[i]);
    });
  }

  Future<List<Card>> getUnassignedCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'folderId IS NULL',
    );

    return List.generate(maps.length, (i) {
      return Card.fromMap(maps[i]);
    });
  }

  Future<int> assignCardToFolder(int cardId, int folderId) async {
    // Check if folder already has 6 cards
    final cardsInFolder = await getCardsInFolder(folderId);
    if (cardsInFolder.length >= 6) {
      return -1; // Indicates folder is full
    }

    final db = await database;
    return await db.update(
      'cards',
      {'folderId': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> removeCardFromFolder(int cardId) async {
    final db = await database;
    return await db.update(
      'cards',
      {'folderId': null},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> countCardsInFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cards WHERE folderId = ?', [folderId]);
    return result.first['count'] as int;
  }

  Future<Card?> getFirstCardInFolder(int folderId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Card.fromMap(maps.first);
    }
    return null;
  }
}
