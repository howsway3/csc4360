import 'package:flutter/material.dart';
import 'package:inclass15/firestore_service.dart';
import 'package:inclass15/item.dart';
import 'package:inclass15/add_edit_item_screen.dart';
import 'package:inclass15/dashboard_screen.dart';

class InventoryHomePage extends StatefulWidget {
  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _bulkSelectMode = false;
  Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_bulkSelectMode 
            ? '${_selectedItems.length} Selected' 
            : 'Inventory Management'),
        actions: [
          if (!_bulkSelectMode) ...[
            IconButton(
              icon: Icon(Icons.dashboard),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _bulkSelectMode = true;
                  _selectedItems.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _selectedItems.isEmpty ? null : _deleteBulkItems,
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _bulkSelectMode = false;
                  _selectedItems.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Category filter chips
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('Electronics', 'Electronics'),
                _buildFilterChip('Furniture', 'Furniture'),
                _buildFilterChip('Clothing', 'Clothing'),
                _buildFilterChip('Food', 'Food'),
                _buildFilterChip('Other', 'Other'),
              ],
            ),
          ),
          Divider(),
          // Items list
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                // Empty state
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + to add your first item',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Display items
                final items = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _bulkSelectMode 
          ? null 
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditItemScreen(),
                  ),
                );
              },
              child: Icon(Icons.add),
            ),
    );
  }

  Widget _buildFilterChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final isSelected = _selectedItems.contains(item.id);
    final isLowStock = item.quantity < 10;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _bulkSelectMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedItems.add(item.id!);
                    } else {
                      _selectedItems.remove(item.id);
                    }
                  });
                },
              )
            : CircleAvatar(
                backgroundColor: isLowStock ? Colors.red : Colors.blue,
                child: Text(
                  item.quantity.toString(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
        title: Text(
          item.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Category: ${item.category}'),
            Text('\$${item.price.toStringAsFixed(2)} each'),
            if (isLowStock)
              Text(
                'Low Stock!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: _bulkSelectMode
            ? null
            : Text(
                '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
        onTap: _bulkSelectMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedItems.remove(item.id);
                  } else {
                    _selectedItems.add(item.id!);
                  }
                });
              }
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditItemScreen(item: item),
                  ),
                );
              },
      ),
    );
  }

  Stream<List<Item>> _getFilteredStream() {
    Stream<List<Item>> stream;

    if (_selectedCategory != null) {
      stream = _firestoreService.filterByCategory(_selectedCategory!);
    } else {
      stream = _firestoreService.getItemsStream();
    }

    if (_searchQuery.isNotEmpty) {
      stream = _firestoreService.searchItems(_searchQuery);
    }

    return stream;
  }

  void _deleteBulkItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Bulk Delete'),
        content: Text('Delete ${_selectedItems.length} selected items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteMultipleItems(_selectedItems.toList());
        setState(() {
          _bulkSelectMode = false;
          _selectedItems.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Items deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting items: $e')),
        );
      }
    }
  }
}
