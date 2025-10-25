import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import 'package:intl/intl.dart';

void main() {
  runApp(const SmartGroceryApp());
}

class SmartGroceryApp extends StatelessWidget {
  const SmartGroceryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grocery List',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const GroceryHomePage(),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grocery.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final pathStr = path_helper.join(dbPath, filePath);
    return await openDatabase(pathStr, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE grocery_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT,
        priority INTEGER NOT NULL,
        purchased INTEGER NOT NULL,
        price REAL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertItem(GroceryItem item) async {
    final db = await database;
    return await db.insert('grocery_items', item.toMap());
  }

  Future<List<GroceryItem>> getAllItems() async {
    final db = await database;
    final result = await db.query('grocery_items', orderBy: 'created_at DESC');
    return result.map((map) => GroceryItem.fromMap(map)).toList();
  }

  Future<int> updateItem(GroceryItem item) async {
    final db = await database;
    return await db.update('grocery_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('grocery_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearPurchasedItems() async {
    final db = await database;
    await db.delete('grocery_items', where: 'purchased = ?', whereArgs: [1]);
  }
}

class GroceryItem {
  int? id;
  String name;
  String quantity;
  String category;
  String? notes;
  bool priority;
  bool purchased;
  double? price;
  DateTime createdAt;

  GroceryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.notes,
    this.priority = false,
    this.purchased = false,
    this.price,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'notes': notes,
      'priority': priority ? 1 : 0,
      'purchased': purchased ? 1 : 0,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      category: map['category'],
      notes: map['notes'],
      priority: map['priority'] == 1,
      purchased: map['purchased'] == 1,
      price: map['price'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class GroceryCategories {
  static const List<String> categories = [
    'Produce', 'Dairy', 'Meat & Seafood', 'Bakery', 'Snacks',
    'Beverages', 'Frozen', 'Pantry', 'Health & Beauty', 'Household', 'Other',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Produce': return Icons.eco;
      case 'Dairy': return Icons.coffee;
      case 'Meat & Seafood': return Icons.set_meal;
      case 'Bakery': return Icons.bakery_dining;
      case 'Snacks': return Icons.cookie;
      case 'Beverages': return Icons.local_drink;
      case 'Frozen': return Icons.ac_unit;
      case 'Pantry': return Icons.kitchen;
      case 'Health & Beauty': return Icons.spa;
      case 'Household': return Icons.home;
      default: return Icons.shopping_basket;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case 'Produce': return Colors.green;
      case 'Dairy': return Colors.blue;
      case 'Meat & Seafood': return Colors.red;
      case 'Bakery': return Colors.orange;
      case 'Snacks': return Colors.purple;
      case 'Beverages': return Colors.cyan;
      case 'Frozen': return Colors.lightBlue;
      case 'Pantry': return Colors.brown;
      case 'Health & Beauty': return Colors.pink;
      case 'Household': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }
}

class GroceryHomePage extends StatefulWidget {
  const GroceryHomePage({Key? key}) : super(key: key);

  @override
  State<GroceryHomePage> createState() => _GroceryHomePageState();
}

class _GroceryHomePageState extends State<GroceryHomePage> {
  List<GroceryItem> _items = [];
  List<GroceryItem> _filteredItems = [];
  String _searchQuery = '';
  String _filterCategory = 'All';
  bool _showPriorityOnly = false;
  bool _showUnpurchasedOnly = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.instance.getAllItems();
    setState(() {
      _items = items;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredItems = _items.where((item) {
      bool matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesCategory = _filterCategory == 'All' || item.category == _filterCategory;
      bool matchesPriority = !_showPriorityOnly || item.priority;
      bool matchesPurchased = !_showUnpurchasedOnly || !item.purchased;
      return matchesSearch && matchesCategory && matchesPriority && matchesPurchased;
    }).toList();
  }

  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.instance.deleteItem(id);
    _loadItems();
  }

  Future<void> _togglePurchased(GroceryItem item) async {
    item.purchased = !item.purchased;
    await DatabaseHelper.instance.updateItem(item);
    _loadItems();
  }

  double _calculateTotal() {
    return _filteredItems.where((item) => !item.purchased && item.price != null).fold(0, (sum, item) => sum + item.price!);
  }

  @override
  Widget build(BuildContext context) {
    final priorityItems = _filteredItems.where((i) => i.priority && !i.purchased).length;
    final unpurchasedItems = _filteredItems.where((i) => !i.purchased).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyListGenerator())).then((_) => _loadItems()),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total', _filteredItems.length.toString(), Icons.shopping_cart),
                  _buildStat('Priority', priorityItems.toString(), Icons.priority_high),
                  _buildStat('Remaining', unpurchasedItems.toString(), Icons.pending),
                  _buildStat('Estimate', '\$${_calculateTotal().toStringAsFixed(2)}', Icons.attach_money),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No items yet! Tap + to add'))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(value: item.purchased, onChanged: (value) => _togglePurchased(item)),
                          title: Text(item.name, style: TextStyle(decoration: item.purchased ? TextDecoration.lineThrough : null)),
                          subtitle: Text('${item.quantity} • ${item.category}'),
                          trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteItem(item.id!)),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditItemPage(item: item))).then((_) => _loadItems()),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditItemPage())).then((_) => _loadItems()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class AddEditItemPage extends StatefulWidget {
  final GroceryItem? item;
  const AddEditItemPage({Key? key, this.item}) : super(key: key);

  @override
  State<AddEditItemPage> createState() => _AddEditItemPageState();
}

class _AddEditItemPageState extends State<AddEditItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  late TextEditingController _priceController;
  String _selectedCategory = 'Produce';
  bool _isPriority = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(text: widget.item?.quantity ?? '1');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _priceController = TextEditingController(text: widget.item?.price?.toString() ?? '');
    _selectedCategory = widget.item?.category ?? 'Produce';
    _isPriority = widget.item?.priority ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final item = GroceryItem(
        id: widget.item?.id,
        name: _nameController.text,
        quantity: _quantityController.text,
        category: _selectedCategory,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        priority: _isPriority,
        purchased: widget.item?.purchased ?? false,
        price: _priceController.text.isEmpty ? null : double.tryParse(_priceController.text),
      );
      if (widget.item == null) {
        await DatabaseHelper.instance.insertItem(item);
      } else {
        await DatabaseHelper.instance.updateItem(item);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item == null ? 'Add Item' : 'Edit Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Please enter item name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? 'Please enter quantity' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: GroceryCategories.categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (Optional)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Priority Item'),
              value: _isPriority,
              onChanged: (value) => setState(() => _isPriority = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveItem, child: Text(widget.item == null ? 'Add Item' : 'Save')),
          ],
        ),
      ),
    );
  }
}

class WeeklyListGenerator extends StatefulWidget {
  const WeeklyListGenerator({Key? key}) : super(key: key);

  @override
  State<WeeklyListGenerator> createState() => _WeeklyListGeneratorState();
}

class _WeeklyListGeneratorState extends State<WeeklyListGenerator> {
  final Map<String, List<String>> _templates = {
    'Produce': ['Bananas', 'Apples', 'Lettuce', 'Tomatoes'],
    'Dairy': ['Milk', 'Eggs', 'Cheese', 'Yogurt'],
    'Pantry': ['Rice', 'Pasta', 'Bread'],
  };
  final Set<String> _selected = {};

  Future<void> _generate() async {
    for (var item in _selected) {
      String cat = 'Other';
      for (var entry in _templates.entries) {
        if (entry.value.contains(item)) cat = entry.key;
      }
      await DatabaseHelper.instance.insertItem(GroceryItem(name: item, quantity: '1', category: cat));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly List')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _templates.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key),
                  children: entry.value.map((item) {
                    return CheckboxListTile(
                      title: Text(item),
                      value: _selected.contains(item),
                      onChanged: (value) => setState(() => value! ? _selected.add(item) : _selected.remove(item)),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selected.isEmpty ? null : _generate,
              child: Text('Add ${_selected.length} items'),
            ),
          ),
        ],
      ),
    );
  }
