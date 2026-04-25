import '../widgets/kaida_loader.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'item_details_screen.dart';

class CatalogItem {
  final int id;
  final String slug;
  final String title;
  final String thumbnailUrl;
  final String instructorName;
  final double price;
  final double discountPrice;
  final bool isFree;
  final String type; 
  final String categoryName;
  final String productType;
  final DateTime? releaseDate;
  final String language; // NEW: Language attribute

  CatalogItem({
    required this.id, required this.slug, required this.title, required this.thumbnailUrl,
    required this.instructorName, required this.price, required this.discountPrice,
    required this.isFree, required this.type, required this.categoryName,
    this.productType = '', this.releaseDate, required this.language,
  });

  bool get isComingSoon {
    if (releaseDate == null) return false;
    return releaseDate!.isAfter(DateTime.now());
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json, String itemType) {
    String rawThumb = json['thumbnail_url']?.toString() ?? '';
    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
      rawThumb = 'https://academy.kainuwa.africa/$rawThumb';
    }
    
    DateTime? parsedDate;
    if (json['release_date'] != null) {
      parsedDate = DateTime.tryParse(json['release_date'].toString());
    }

    return CatalogItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      thumbnailUrl: rawThumb,
      instructorName: json['instructor_name']?.toString() ?? json['username']?.toString() ?? 'Kaida Learn',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      discountPrice: double.tryParse(json['discount_price']?.toString() ?? '0') ?? 0.0,
      isFree: (json['is_free']?.toString() == '1'),
      type: itemType,
      categoryName: json['category_name']?.toString() ?? 'General',
      productType: json['product_type']?.toString() ?? '',
      releaseDate: parsedDate,
      language: json['language']?.toString() ?? 'Hausa', // Fallback ensures UI never crashes
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
  Set<int> _wishlistedIds = {};
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
    _fetchData();
  }

  Future<void> _fetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    // 1. Instantly load from offline memory
    final cachedWishlist = prefs.getString('cached_wishlist_${widget.actionType}');
    if (cachedWishlist != null) {
      List<dynamic> list = json.decode(cachedWishlist);
      if (mounted) {
        setState(() {
          _wishlistedIds = list.map((e) => int.parse(e.toString())).toSet();
        });
      }
    }

    // 2. Sync with database in the background
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getWishlist),
        body: {'user_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> items = data['data'];
          Set<int> syncedIds = {};
          String expectedType = widget.actionType == 'courses' ? 'course' : 'product';
          
          for (var item in items) {
            if (item['item_type'] == expectedType) {
              syncedIds.add(int.parse(item['item_id'].toString()));
            }
          }
          if (mounted) {
            setState(() => _wishlistedIds = syncedIds);
            prefs.setString('cached_wishlist_${widget.actionType}', json.encode(syncedIds.toList()));
          }
        }
      }
    } catch (e) {
      debugPrint("Wishlist API Error: $e");
    }
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('https://academy.kainuwa.africa/api/mobile/catalog.php?action=${widget.actionType}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          List<CatalogItem> parsedItems = [];
          Set<String> uniqueCategories = {'All'};

          for (var item in list) {
            try {
              final parsed = CatalogItem.fromJson(item, widget.actionType);
              parsedItems.add(parsed);
              if (parsed.categoryName.isNotEmpty && parsed.categoryName != 'General') {
                uniqueCategories.add(parsed.categoryName);
              }
            } catch (e) {
              debugPrint("Parse error: $e");
            }
          }

          // --- SMART SORTING ALGORITHM ---
          // This forces active courses to the top, and 'Coming Soon' to the bottom
          parsedItems.sort((a, b) {
            if (a.isComingSoon && !b.isComingSoon) return 1;
            if (!a.isComingSoon && b.isComingSoon) return -1;
            return 0; // Maintain natural API order otherwise
          });

          if (mounted) {
            setState(() {
              _allItems = parsedItems;
              _filteredItems = parsedItems;
              _categories = uniqueCategories.toList();
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              item.instructorName.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || item.categoryName == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _toggleWishlist(CatalogItem item) async {
    setState(() {
      if (_wishlistedIds.contains(item.id)) {
        _wishlistedIds.remove(item.id);
      } else {
        _wishlistedIds.add(item.id);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_wishlist_${widget.actionType}', json.encode(_wishlistedIds.toList()));

    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      await http.post(
        Uri.parse('https://academy.kainuwa.africa/api/toggle_wishlist.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'item_id': item.id,
          'item_type': widget.actionType == 'courses' ? 'course' : 'product'
        }),
      );
    } catch (e) {
      debugPrint("Wishlist error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.primaryColor,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterItems();
                  },
                  decoration: InputDecoration(
                    hintText: widget.actionType == 'courses' ? 'Search courses, mentors...' : 'Search products...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          if (!_isLoading && _categories.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8), 
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            _filterItems();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkSurfaceColor : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: KaidaLoader()))
          else if (_filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No results found.', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildModernCard(_filteredItems[index], isDark),
                  childCount: _filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernCard(CatalogItem item, bool isDark) {
    String subtitleText = widget.actionType == 'products' 
        ? (item.productType == 'digital' ? 'Digital Download' : 'Physical Item')
        : item.instructorName;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!item.isComingSoon) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This item is launching soon!')));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          errorWidget: (context, url, error) => Container(color: AppTheme.primaryColor, child: Icon(widget.actionType == 'courses' ? Icons.school : Icons.shopping_bag, color: Colors.white)),
                        )
                      : Container(color: AppTheme.primaryColor, child: Icon(widget.actionType == 'courses' ? Icons.school : Icons.shopping_bag, size: 40, color: Colors.white)),
                  
                  // NEW: Category & Language Badges
                  Positioned(
                    top: 8, left: 8,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                          child: Text(item.categoryName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                        if (widget.actionType == 'courses') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language, size: 9, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(item.language.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleWishlist(item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          _wishlistedIds.contains(item.id) ? Icons.favorite : Icons.favorite_border,
                          color: _wishlistedIds.contains(item.id) ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (item.isComingSoon)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(child: Icon(Icons.lock_clock, color: Colors.white, size: 30)),
                    )
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2, color: isDark ? Colors.white : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(widget.actionType == 'courses' ? Icons.person : Icons.inventory_2, size: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(child: Text(subtitleText, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                    _buildPrice(item, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrice(CatalogItem item, bool isDark) {
    if (item.isComingSoon) return const Text('COMING SOON', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12));
    if (item.isFree || (item.price == 0 && item.discountPrice == 0)) return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14));
    
    if (item.discountPrice > 0 && item.discountPrice < item.price) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('₦${item.price.toStringAsFixed(0)}', style: TextStyle(decoration: TextDecoration.lineThrough, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w600)),
          Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor)),
        ],
      );
    }
    return Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor));
  }
}
