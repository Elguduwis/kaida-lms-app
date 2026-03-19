import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'profile_screen.dart'; // We import this to reuse your WebDashboardScreen

class CatalogItem {
  final String slug;
  final String title;
  final String thumbnailUrl;
  final String instructorName;
  final double price;
  final double discountPrice;
  final bool isFree;
  final String type; 

  CatalogItem({
    required this.slug, required this.title, required this.thumbnailUrl,
    required this.instructorName, required this.price, required this.discountPrice,
    required this.isFree, required this.type
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json, String itemType) {
    String rawThumb = json['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }
    
    return CatalogItem(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      thumbnailUrl: rawThumb,
      instructorName: json['instructor_name']?.toString() ?? json['username']?.toString() ?? 'Kainuwa',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      discountPrice: double.tryParse(json['discount_price']?.toString() ?? '0') ?? 0.0,
      isFree: json['is_free']?.toString() == '1',
      type: itemType == 'courses' ? 'course' : 'product',
    );
  }
}

class CatalogScreen extends StatefulWidget {
  final String actionType; // 'courses' or 'products'
  final String title;

  const CatalogScreen({Key? key, required this.actionType, required this.title}) : super(key: key);

  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _isLoading = true;
  List<CatalogItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    try {
      final response = await http.get(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/catalog.php?action=${widget.actionType}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          if (mounted) {
            setState(() {
              _items = list.map((item) => CatalogItem.fromJson(item, widget.actionType)).toList();
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDetails(CatalogItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    
    // Direct user to the correct web view based on the item type!
    final redirect = item.type == 'course' ? '/view_course.php?slug=${item.slug}' : '/view_product.php?slug=${item.slug}';
    final authUrl = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$userId&redirect=$redirect';
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebDashboardScreen(url: authUrl, title: item.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: _fetchCatalog,
            child: _items.isEmpty
              ? const Center(child: Text('No items available yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _openDetails(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            item.thumbnailUrl.isNotEmpty
                              ? Image.network(item.thumbnailUrl, height: 180, width: double.infinity, fit: BoxFit.cover)
                              : Container(height: 180, color: AppTheme.primaryColor, child: const Icon(Icons.image, size: 60, color: Colors.white)),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(item.type == 'course' ? 'By ${item.instructorName}' : 'KAIDA Product', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildPrice(item),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _openDetails(item),
                                        child: Text(item.type == 'course' ? 'Enroll' : 'Buy Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _buildPrice(CatalogItem item) {
    if (item.isFree || (item.price == 0 && item.discountPrice == 0)) {
      return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18));
    }
    if (item.discountPrice > 0 && item.discountPrice < item.price) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
          Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
        ],
      );
    }
    return Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor));
  }
}
