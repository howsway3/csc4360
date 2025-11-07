import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inclass15/item.dart';

class FirestoreService {
  // Create reference to the 'items' collection
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  // Add a new item to Firestore
  Future<void> addItem(Item item) async {
    try {
      await _itemsCollection.add(item.toMap());
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  // Get real-time stream of items
  Stream<List<Item>> getItemsStream() {
    return _itemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update an existing item
  Future<void> updateItem(Item item) async {
    try {
      if (item.id == null) {
        throw Exception('Item ID cannot be null for update');
      }
      await _itemsCollection.doc(item.id).update(item.toMap());
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete an item by ID
  Future<void> deleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Bulk delete multiple items
  Future<void> deleteMultipleItems(List<String> itemIds) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String id in itemIds) {
        batch.delete(_itemsCollection.doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete multiple items: $e');
    }
  }

  // Search items by name
  Stream<List<Item>> searchItems(String query) {
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          })
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Filter items by category
  Stream<List<Item>> filterByCategory(String category) {
    return _itemsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
