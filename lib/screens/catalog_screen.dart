import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import 'item_details_screen.dart';

class CatalogItem {
  final String slug;
  final String title;
  final String thumbnailUrl;
  final String instructorName;
  final double price;
  final double discountPrice;
  final bool isFree;
  final String type; 
  final String categoryName;

  CatalogItem({
    required this.slug, required this.title, required this.thumbnailUrl,
    required this.instructorName, required this.price, required this.discountPrice,
    required this.isFree, required this.type, required this.categoryName
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
      categoryName: json['category_name']?.toString() ?? 'General',
    );
  }
}

class CatalogScreen extends StatefulWidget {
  final String actionType; 
  final String title;

  const CatalogScreen({Key? key, required this.actionType, required this.title}) : super(key: key);

  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _isLoading = true;
  List<CatalogItem> _allItems = [];
  List<CatalogItem> _filteredItems = [];
  
  // Filtering States
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/catalog.php?action=${widget.actionType}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          
          List<CatalogItem> parsedItems = [];
          Set<String> uniqueCategories = {'All'};
          
          for (var item in list) {
            try {
              var parsed = CatalogItem.fromJson(item, widget.actionType);
              parsedItems.add(parsed);
              uniqueCategories.add(parsed.categoryName);
            } catch (e) {
              debugPrint("Error parsing item: $e");
            }
          }
          
          if (mounted) {
            setState(() {
              _allItems = parsedItems;
              _categories = uniqueCategories.toList();
              _applyFilters();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      // THIS PREVENTS INFINITE LOADING REGARDLESS OF ERRORS
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              item.instructorName.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || item.categoryName == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor,
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          // 2. Category Filter Chips
          if (_categories.length > 1)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                          _applyFilters();
                        });
                      },
                    ),
                  );
                },
              ),
            ),

          // 3. Grid View Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _fetchCatalog,
                  child: _filteredItems.isEmpty
                    ? ListView(children: const [SizedBox(height: 100), Center(child: Text('No results found.'))]) // ListView allows pull-to-refresh even when empty
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70, // Adjusts height of the cards
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildGridCard(item);
                        },
                      ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(CatalogItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Expanded(
              flex: 5,
              child: item.thumbnailUrl.isNotEmpty
                ? Image.network(item.thumbnailUrl, width: double.infinity, fit: BoxFit.cover)
                : Container(width: double.infinity, color: AppTheme.primaryColor, child: const Icon(Icons.image, color: Colors.white)),
            ),
            
            // Text Area
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.type == 'course' ? item.instructorName : 'Digital Product', 
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    _buildPrice(item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrice(CatalogItem item) {
    if (item.isFree || (item.price == 0 && item.discountPrice == 0)) {
      return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14));
    }
    if (item.discountPrice > 0 && item.discountPrice < item.price) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
          Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 10)),
        ],
      );
    }
    return Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor));
  }
}
