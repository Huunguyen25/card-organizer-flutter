import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/folder_model.dart';
import '../models/card_model.dart' as card_model;
import 'card_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final folders = await _dbHelper.getFolders();
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading folders: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                return _buildFolderCard(_folders[index]);
              },
            ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getFolderDetails(folder.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final cardCount = snapshot.data?['count'] ?? 0;
        final previewCard = snapshot.data?['firstCard'] as card_model.Card?;

        return GestureDetector(
          onTap: () => _openFolder(folder),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: previewCard != null
                      ? Image.asset(
                          previewCard.imageUrl,
                          fit: BoxFit.contain,
                        )
                      : Container(
                          color: _getFolderColor(folder.name),
                          child: const Center(
                            child: Icon(Icons.folder, size: 64, color: Colors.white),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('$cardCount cards'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getFolderDetails(int folderId) async {
    final count = await _dbHelper.countCardsInFolder(folderId);
    final firstCard = await _dbHelper.getFirstCardInFolder(folderId);
    return {'count': count, 'firstCard': firstCard};
  }

  Color _getFolderColor(String folderName) {
    switch (folderName.toLowerCase()) {
      case 'hearts':
        return Colors.red;
      case 'spades':
        return Colors.black87;
      case 'diamonds':
        return Colors.redAccent;
      case 'clubs':
        return Colors.black54;
      default:
        return Colors.blueGrey;
    }
  }

  void _openFolder(Folder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardScreen(folder: folder),
      ),
    ).then((_) => _loadFolders());
  }
}

