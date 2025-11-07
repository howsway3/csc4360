import 'package:flutter/material.dart';
import 'package:inclass15/firestore_service.dart';
import 'package:inclass15/item.dart';

class DashboardScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Dashboard'),
      ),
      body: StreamBuilder<List<Item>>(
        stream: _firestoreService.getItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data!;
          final totalItems = items.length;
          final totalValue = items.fold<double>(
            0,
            (sum, item) => sum + (item.quantity * item.price),
          );
          final outOfStockItems = items.where((item) => item.quantity == 0).toList();
          final lowStockItems = items.where((item) => item.quantity > 0 && item.quantity < 10).toList();

          // Category breakdown
          final categoryMap = <String, int>{};
          for (var item in items) {
            categoryMap[item.category] = (categoryMap[item.category] ?? 0) + 1;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Items',
                        totalItems.toString(),
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Value',
                        '\$${totalValue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Out of Stock',
                        outOfStockItems.length.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Low Stock',
                        lowStockItems.length.toString(),
                        Icons.trending_down,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Category breakdown
                Text(
                  'Category Breakdown',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: categoryMap.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(fontSize: 16),
                              ),
                              Chip(
                                label: Text('${entry.value} items'),
                                backgroundColor: Colors.blue.shade50,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Out of stock items
                if (outOfStockItems.isNotEmpty) ...[
                  Text(
                    'Out of Stock Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ...outOfStockItems.map((item) => Card(
                        color: Colors.red.shade50,
                        child: ListTile(
                          leading: Icon(Icons.warning, color: Colors.red),
                          title: Text(item.name),
                          subtitle: Text(item.category),
                          trailing: Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )),
                  SizedBox(height: 24),
                ],

                // Low stock items
                if (lowStockItems.isNotEmpty) ...[
                  Text(
                    'Low Stock Items (< 10)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ...lowStockItems.map((item) => Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              item.quantity.toString(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Text(item.category),
                          trailing: Text(
                            '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
