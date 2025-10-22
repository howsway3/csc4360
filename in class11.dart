
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;

void main() => runApp(const CardOrganizerApp());

class CardOrganizerApp extends StatelessWidget {
  const CardOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const FoldersScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FolderModel {
  final int? id;
  final String name;
  final String timestamp;
  FolderModel({this.id, required this.name, required this.timestamp});
  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(id: json['id'] as int?, name: json['name'] as String, timestamp: json['timestamp'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'timestamp': timestamp};
  FolderModel copyWith({int? id, String? name, String? timestamp}) => FolderModel(id: id ?? this.id, name: name ?? this.name, timestamp: timestamp ?? this.timestamp);
}

class CardModel {
  final int? id;
  final String name;
  final String suit;
  final String imageUrl;
  final int? folderId;
  final int rank;
  CardModel({this.id, required this.name, required this.suit, required this.imageUrl, this.folderId, required this.rank});
  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(id: json['id'] as int?, name: json['name'] as String, suit: json['suit'] as String, imageUrl: json['imageUrl'] as String, folderId: json['folderId'] as int?, rank: json['rank'] as int);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'suit': suit, 'imageUrl': imageUrl, 'folderId': folderId, 'rank': rank};
  CardModel copyWith({int? id, String? name, String? suit, String? imageUrl, int? folderId, int? rank}) => CardModel(id: id ?? this.id, name: name ?? this.name, suit: suit ?? this.suit, imageUrl: imageUrl ?? this.imageUrl, folderId: folderId ?? this.folderId, rank: rank ?? this.rank);
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final pathStr = path_helper.join(dbPath, filePath);
    return await openDatabase(pathStr, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE folders (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, timestamp TEXT NOT NULL)');
    await db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, suit TEXT NOT NULL, imageUrl TEXT NOT NULL, folderId INTEGER, rank INTEGER NOT NULL, FOREIGN KEY (folderId) REFERENCES folders (id) ON DELETE CASCADE)');
    await _prepopulateFolders(db);
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateFolders(Database db) async {
    for (var folder in ['Hearts', 'Spades', 'Diamonds', 'Clubs']) {
      await db.insert('folders', {'name': folder, 'timestamp': DateTime.now().toIso8601String()});
    }
  }

  Future<void> _prepopulateCards(Database db) async {
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final ranks = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];
    for (var suit in suits) {
      for (int i = 0; i < ranks.length; i++) {
        await db.insert('cards', {'name': '${ranks[i]} of $suit', 'suit': suit, 'imageUrl': 'https://deckofcardsapi.com/static/img/${_getCardCode(ranks[i], suit)}.png', 'folderId': null, 'rank': i + 1});
      }
    }
  }

  String _getCardCode(String rank, String suit) {
    String rankCode = rank == 'Ace' ? 'A' : rank == 'Jack' ? 'J' : rank == 'Queen' ? 'Q' : rank == 'King' ? 'K' : rank;
    return '$rankCode${suit[0]}';
  }

  Future<List<FolderModel>> getAllFolders() async => (await (await database).query('folders')).map((j) => FolderModel.fromJson(j)).toList();
  Future<int> createFolder(FolderModel folder) async => await (await database).insert('folders', folder.toJson());
  Future<int> updateFolder(FolderModel folder) async => await (await database).update('folders', folder.toJson(), where: 'id = ?', whereArgs: [folder.id]);
  Future<int> deleteFolder(int id) async {
    final db = await database;
    await db.update('cards', {'folderId': null}, where: 'folderId = ?', whereArgs: [id]);
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CardModel>> getCardsInFolder(int folderId) async => (await (await database).query('cards', where: 'folderId = ?', whereArgs: [folderId], orderBy: 'rank')).map((j) => CardModel.fromJson(j)).toList();
  Future<List<CardModel>> getUnassignedCardsBySuit(String suit) async => (await (await database).query('cards', where: 'suit = ? AND folderId IS NULL', whereArgs: [suit], orderBy: 'rank')).map((j) => CardModel.fromJson(j)).toList();
  Future<int> getCardCountInFolder(int folderId) async => Sqflite.firstIntValue(await (await database).rawQuery('SELECT COUNT(*) as count FROM cards WHERE folderId = ?', [folderId])) ?? 0;
  Future<int> updateCard(CardModel card) async => await (await database).update('cards', card.toJson(), where: 'id = ?', whereArgs: [card.id]);
  Future<int> assignCardToFolder(int cardId, int? folderId) async => await (await database).update('cards', {'folderId': folderId}, where: 'id = ?', whereArgs: [cardId]);
}

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});
  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<FolderModel> _folders = [];
  Map<int, int> _cardCounts = {};
  Map<int, CardModel?> _firstCards = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await _dbHelper.getAllFolders();
    final Map<int, int> counts = {};
    final Map<int, CardModel?> firstCards = {};
    for (var folder in folders) {
      counts[folder.id!] = await _dbHelper.getCardCountInFolder(folder.id!);
      final cards = await _dbHelper.getCardsInFolder(folder.id!);
      firstCards[folder.id!] = cards.isNotEmpty ? cards.first : null;
    }
    setState(() {
      _folders = folders;
      _cardCounts = counts;
      _firstCards = firstCards;
      _isLoading = false;
    });
  }

  Color _getSuitColor(String n) => n == 'Hearts' || n == 'Diamonds' ? Colors.red : Colors.black;
  IconData _getSuitIcon(String n) => n == 'Hearts' ? Icons.favorite : n == 'Diamonds' ? Icons.change_history : n == 'Spades' ? Icons.spa : n == 'Clubs' ? Icons.filter_vintage : Icons.folder;

  void _showAddFolderDialog() {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Add New Folder'), content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Folder Name', hintText: 'Enter folder name')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async {if (c.text.isNotEmpty) {await _dbHelper.createFolder(FolderModel(name: c.text, timestamp: DateTime.now().toIso8601String())); Navigator.pop(ctx); _loadFolders(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder created successfully')));}}, child: const Text('Add'))]));
  }

  void _showRenameFolderDialog(FolderModel f) {
    final c = TextEditingController(text: f.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Rename Folder'), content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Folder Name')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async {if (c.text.isNotEmpty) {await _dbHelper.updateFolder(f.copyWith(name: c.text)); Navigator.pop(ctx); _loadFolders(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder renamed successfully')));}}, child: const Text('Save'))]));
  }

  void _showDeleteFolderDialog(FolderModel f) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Folder'), content: Text('Are you sure you want to delete "${f.name}"? All cards will be unassigned.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {await _dbHelper.deleteFolder(f.id!); Navigator.pop(ctx); _loadFolders(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder deleted successfully')));}, child: const Text('Delete'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Organizer'), elevation: 2),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _folders.isEmpty ? const Center(child: Text('No folders found')) : RefreshIndicator(onRefresh: _loadFolders, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _folders.length, itemBuilder: (context, index) {
        final f = _folders[index];
        final cnt = _cardCounts[f.id] ?? 0;
        final fc = _firstCards[f.id];
        return Card(margin: const EdgeInsets.only(bottom: 16), elevation: 4, child: InkWell(onTap: () async {await Navigator.push(context, MaterialPageRoute(builder: (context) => CardsScreen(folder: f))); _loadFolders();}, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(width: 80, height: 112, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[400]!)), child: fc != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(fc.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Icon(_getSuitIcon(f.name), size: 40, color: _getSuitColor(f.name)))) : Icon(_getSuitIcon(f.name), size: 40, color: _getSuitColor(f.name))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(_getSuitIcon(f.name), color: _getSuitColor(f.name), size: 24), const SizedBox(width: 8), Text(f.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]), const SizedBox(height: 8), Text('$cnt cards', style: TextStyle(fontSize: 16, color: Colors.grey[600])), if (cnt < 3) const Text('⚠️ Need at least 3 cards', style: TextStyle(fontSize: 14, color: Colors.orange))])), PopupMenuButton(itemBuilder: (context) => [const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Rename')])), const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]))], onSelected: (value) {if (value == 'rename') _showRenameFolderDialog(f); else if (value == 'delete') _showDeleteFolderDialog(f);})]))));
      })),
      floatingActionButton: FloatingActionButton(onPressed: _showAddFolderDialog, child: const Icon(Icons.add)),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final FolderModel folder;
  const CardsScreen({super.key, required this.folder});
  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<CardModel> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await _dbHelper.getCardsInFolder(widget.folder.id!);
    setState(() {_cards = cards; _isLoading = false;});
  }

  Future<void> _showAddCardDialog() async {
    final cnt = await _dbHelper.getCardCountInFolder(widget.folder.id!);
    if (cnt >= 6) {
      if (mounted) showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Folder Full'), content: const Text('This folder can only hold 6 cards.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
      return;
    }
    final avail = await _dbHelper.getUnassignedCardsBySuit(widget.folder.name);
    if (avail.isEmpty) {
      if (mounted) showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('No Cards Available'), content: Text('All ${widget.folder.name} cards are already assigned.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
      return;
    }
    if (mounted) {
      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Add Card'), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: avail.length, itemBuilder: (context, index) {
        final card = avail[index];
        return ListTile(leading: SizedBox(width: 40, height: 56, child: Image.network(card.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported))), title: Text(card.name), onTap: () async {await _dbHelper.assignCardToFolder(card.id!, widget.folder.id!); Navigator.pop(ctx); _loadCards(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${card.name} added to folder')));});
      })), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))]));
    }
  }

  void _showEditCardDialog(CardModel card) {
    final c = TextEditingController(text: card.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Edit Card'), content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Card Name')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async {if (c.text.isNotEmpty) {await _dbHelper.updateCard(card.copyWith(name: c.text)); Navigator.pop(ctx); _loadCards(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card updated successfully')));}}, child: const Text('Save'))]));
  }

  void _showReassignCardDialog(CardModel card) async {
    final folders = await _dbHelper.getAllFolders();
    final other = folders.where((f) => f.id != widget.folder.id).toList();
    if (mounted) {
      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Reassign Card'), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: other.length, itemBuilder: (context, index) {
        final folder = other[index];
        return ListTile(title: Text(folder.name), onTap: () async {
          final cnt = await _dbHelper.getCardCountInFolder(folder.id!);
          if (cnt >= 6) {Navigator.pop(ctx); if (mounted) showDialog(context: context, builder: (ctx2) => AlertDialog(title: const Text('Folder Full'), content: Text('${folder.name} folder can only hold 6 cards.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('OK'))])); return;}
          await _dbHelper.assignCardToFolder(card.id!, folder.id!); Navigator.pop(ctx); _loadCards(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${card.name} moved to ${folder.name}')));
        });
      })), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))]));
    }
  }

  void _showDeleteCardDialog(CardModel card) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Remove Card'), content: Text('Remove "${card.name}" from this folder?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {await _dbHelper.assignCardToFolder(card.id!, null); Navigator.pop(ctx); _loadCards(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${card.name} removed from folder')));}, child: const Text('Remove'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.folder.name} Cards'), elevation: 2),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        if (_cards.length < 3) Container(width: double.infinity, padding: const EdgeInsets.all(16), color: Colors.orange[100], child: Row(children: [Icon(Icons.warning, color: Colors.orange[900]), const SizedBox(width: 8), Expanded(child: Text('You need at least 3 cards in this folder.', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold)))])),
        if (_cards.isEmpty) const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No cards in this folder', style: TextStyle(fontSize: 18, color: Colors.grey)), SizedBox(height: 8), Text('Tap + to add cards', style: TextStyle(fontSize: 14, color: Colors.grey))])))
        else Expanded(child: RefreshIndicator(onRefresh: _loadCards, child: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16), itemCount: _cards.length, itemBuilder: (context, idx) {
          final card = _cards[idx];
          return Card(elevation: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), child: Image.network(card.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, size: 48)))))),
            Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showEditCardDialog(card), tooltip: 'Edit', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                IconButton(icon: const Icon(Icons.swap_horiz, size: 20), onPressed: () => _showReassignCardDialog(card), tooltip: 'Reassign', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _showDeleteCardDialog(card), tooltip: 'Remove', padding: EdgeInsets.zero, constraints: const BoxConstraints())
              ])
            ]))
          ]));
        })))
      ]),
      floatingActionButton: FloatingActionButton(onPressed: _showAddCardDialog, child: const Icon(Icons.add)),
    );
  }
}
