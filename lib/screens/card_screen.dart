import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/folder_model.dart';
import '../models/card_model.dart' as card_model;

class CardScreen extends StatefulWidget {
  final Folder folder;

  const CardScreen({super.key, required this.folder});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<card_model.Card> _cardsInFolder = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cards = await _dbHelper.getCardsInFolder(widget.folder.id);
      setState(() {
        _cardsInFolder = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cards: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.name} Cards'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Cards in ${widget.folder.name}: ${_cardsInFolder.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _cardsInFolder.length < 3
                    ? _buildWarningBanner()
                    : const SizedBox.shrink(),
                Expanded(
                  child: _cardsInFolder.isEmpty
                      ? const Center(
                          child: Text('No cards in this folder yet.'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _cardsInFolder.length,
                          itemBuilder: (context, index) {
                            return _buildCardItem(_cardsInFolder[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      color: Colors.amber,
      padding: const EdgeInsets.all(8.0),
      child: const Text(
        'You need at least 3 cards in this folder.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardItem(card_model.Card card) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              card.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCardFromFolder(card),
                      tooltip: 'Remove from folder',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCardDialog() async {
    final unassignedCards = await _dbHelper.getUnassignedCards();
    
    if (unassignedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cards available to add.'))
      );
      return;
    }
    
    if (_cardsInFolder.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This folder can only hold 6 cards.'))
      );
      return;
    }

    // Filter unassigned cards to only show cards of this folder's suit
    final suitCards = unassignedCards.where(
      (card) => card.suit.toLowerCase() == widget.folder.name.toLowerCase()
    ).toList();
    
    if (suitCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No ${widget.folder.name} cards available to add.'))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${widget.folder.name} Card'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suitCards.length,
              itemBuilder: (context, index) {
                final card = suitCards[index];
                return ListTile(
                  leading: Image.asset(
                    card.imageUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                  title: Text(card.name),
                  onTap: () {
                    Navigator.pop(context);
                    _addCardToFolder(card);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCardToFolder(card_model.Card card) async {
    if (_cardsInFolder.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This folder can only hold 6 cards.'))
      );
      return;
    }
    
    final result = await _dbHelper.assignCardToFolder(card.id, widget.folder.id);
    
    if (result > 0) {
      _loadCards();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} added to folder'))
      );
    } else if (result == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This folder can only hold 6 cards.'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add card to folder'))
      );
    }
  }

  Future<void> _removeCardFromFolder(card_model.Card card) async {
    // Check if removing would make the folder have less than 3 cards
    if (_cardsInFolder.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least 3 cards in this folder.'))
      );
      return;
    }

    final result = await _dbHelper.removeCardFromFolder(card.id);
    
    if (result > 0) {
      _loadCards();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.name} removed from folder'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove card from folder'))
      );
    }
  }
}
