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
  final String productType; // NEW: Captures physical vs digital

  CatalogItem({
    required this.slug, required this.title, required this.thumbnailUrl,
    required this.instructorName, required this.price, required this.discountPrice,
    required this.isFree, required this.type, required this.categoryName,
    this.productType = '',
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
      productType: json['product_type']?.toString() ?? 'digital', // Reads from your DB!
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
  String _errorMessage = ''; 
  List<CatalogItem> _allItems = [];
  List<CatalogItem> _filteredItems = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await http.get(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/catalog.php?action=${widget.actionType}'),
      );

      if (response.statusCode == 200) {
        try {
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
                debugPrint("Parse error on single item: $e");
              }
            }
            
            if (mounted) {
              setState(() {
                _allItems = parsedItems;
                _categories = uniqueCategories.toList();
                _applyFilters();
              });
            }
          } else {
            if (mounted) setState(() => _errorMessage = data['message'] ?? 'API Error');
          }
        } catch (e) {
          if (mounted) setState(() => _errorMessage = 'JSON Parse Error. Server sent:\n${response.body}');
        }
      } else {
        if (mounted) setState(() => _errorMessage = 'Server Status Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Network Connection Error: $e');
    } finally {
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
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _applyFilters(); }); }) : null,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          
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

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _errorMessage.isNotEmpty
                  ? _buildErrorDisplay() 
                  : RefreshIndicator(
                      color: AppTheme.primaryColor,
                      onRefresh: _fetchCatalog,
                      child: _filteredItems.isEmpty
                        ? ListView(children: const [SizedBox(height: 100), Center(child: Text('No results found.'))]) 
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.70,
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
  
  Widget _buildErrorDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchCatalog,
              child: const Text('Try Again'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(CatalogItem item) {
    // DYNAMIC SUBTITLE BASED ON DB PRODUCT TYPE
    String subtitleText = item.type == 'course' 
        ? item.instructorName 
        : (item.productType.toLowerCase() == 'physical' ? 'Physical Product' : 'Digital Product');

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
            Expanded(
              flex: 5,
              child: item.thumbnailUrl.isNotEmpty
                ? Image.network(item.thumbnailUrl, width: double.infinity, fit: BoxFit.cover)
                : Container(width: double.infinity, color: AppTheme.primaryColor, child: const Icon(Icons.image, color: Colors.white)),
            ),
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
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(subtitleText, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
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
