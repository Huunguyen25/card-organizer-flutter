import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FolderScreen(),
    );
  }
}

class FolderScreen extends StatefulWidget {
  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Map<String, dynamic>> folders = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() async {
    final data = await dbHelper.fetchFolders();
    setState(() {
      folders = data;
    });
  }

  void _showFolderDialog() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Folder'),
          content: TextField(
            controller: folderController,
            decoration: InputDecoration(labelText: 'Folder Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                String folderName = folderController.text.trim();
                if (folderName.isNotEmpty) {
                  await dbHelper.insertFolder({'name': folderName});
                  _loadFolders();
                  Navigator.pop(context);  // Close the dialog
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // Close the dialog without saving
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Card Organizer')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return GestureDetector(
            onTap: () {
              // Navigate to CardsScreen for the selected folder
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardsScreen(folderId: folder['id']),
                ),
              );
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(
                    'https://deckofcardsapi.com/static/img/${folder['name'][0].toUpperCase()}${folder['name'][1].toUpperCase()}.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      folder['name'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${folder['cardCount']} cards',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Add button pressed'); // Debugging line
          _showFolderDialog(); // Call to show the dialog
        },
        child: Icon(Icons.add),
        tooltip: 'Add Folder',
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final int folderId;

  CardsScreen({required this.folderId});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() async {
    final data = await dbHelper.fetchCardsForFolder(widget.folderId);
    setState(() {
      cards = data;
    });
  }

  void _addCard() async {
    if (cards.length >= 6) {
      _showErrorDialog("This folder can only hold 6 cards.");
      return;
    }

    // Sample logic to add card (this can be updated based on user selection)
    await dbHelper.insertCard({
      'name': 'Ace of Hearts',
      'suit': 'Hearts',
      'imageUrl': 'https://deckofcardsapi.com/static/img/AH.png',
      'folderId': widget.folderId,
    });

    _loadCards(); // Refresh the list of cards
  }

  void _deleteCard(int cardId) async {
    await dbHelper.deleteCard(cardId);
    _loadCards(); // Refresh the list after deletion
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cards in Folder')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: GestureDetector(
              onTap: () {
                // Logic to update or view card details (can be expanded as required)
              },
              child: Column(
                children: [
                  Image.network(card['imageUrl'], height: 80, width: 80, fit: BoxFit.contain),
                  Text(card['name']),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteCard(card['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: Icon(Icons.add),
        tooltip: 'Add Card',
      ),
    );
  }
}