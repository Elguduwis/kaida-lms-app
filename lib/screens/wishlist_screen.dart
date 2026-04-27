import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import 'catalog_screen.dart';
import 'item_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoading = true;
  List<CatalogItem> _wishlistedItems = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    
    if (_userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(Uri.parse(ApiConfig.getWishlist), body: {'user_id': _userId.toString()});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> list = data['data'];
          List<CatalogItem> parsedList = [];
          for (var item in list) {
            try { parsedList.add(CatalogItem.fromJson(item, 'courses')); } catch (e) {}
          }
          if (mounted) {
            setState(() {
              _wishlistedItems = parsedList;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(int courseId) async {
    if (_userId == null) return;

    // Optimistic UI Removal
    setState(() {
      _wishlistedItems.removeWhere((item) => item.id == courseId);
    });

    try {
      await http.post(
        Uri.parse(ApiConfig.toggleWishlist),
        body: {'user_id': _userId.toString(), 'item_id': courseId.toString(), 'item_type': 'course'}
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist'), duration: Duration(seconds: 1)));
    } catch (e) {
      _fetchWishlist(); // Re-fetch if API failed
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('My Wishlist', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: KaidaLoader())
            : _wishlistedItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_outline_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Wishlist Empty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        const SizedBox(height: 8),
                        Text('Courses you favorite will appear here.', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: _fetchWishlist,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 260,
                      ),
                      itemCount: _wishlistedItems.length,
                      itemBuilder: (context, index) => _buildGridCard(_wishlistedItems[index], isDark),
                    ),
                  ),
      ),
    );
  }

  Widget _buildGridCard(CatalogItem item, bool isDark) {
    int discountPercent = 0;
    if (item.price > 0 && item.discountPrice > 0 && item.discountPrice < item.price) {
      discountPercent = (((item.price - item.discountPrice) / item.price) * 100).round();
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item))).then((_) => _fetchWishlist()),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          boxShadow: [BoxShadow(color: isDark ? Colors.black12 : Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: item.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: item.thumbnailUrl, height: 110, width: double.infinity, fit: BoxFit.cover)
                      : Container(height: 110, color: AppTheme.primaryColor.withOpacity(0.2), child: const Icon(Icons.school_rounded, size: 40, color: AppTheme.primaryColor)),
                ),
                if (discountPercent > 0 && !item.isComingSoon)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                      child: Text('-$discountPercent%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item.categoryName.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item.instructorName, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Spacer(),
                    if (item.isFree || (item.price == 0 && item.discountPrice == 0))
                      const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))
                    else if (item.discountPrice > 0 && item.discountPrice < item.price)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor)),
                        ],
                      )
                    else
                      Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
