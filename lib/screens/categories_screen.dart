import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import 'catalog_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.categories));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _categories = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Categories Fetch Error: $e");
    } finally {
      // FIX: Ensure the loading spinner always stops, regardless of success or error
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Assigns a native Flutter icon based on the category name
  IconData _getIconForCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('design')) return Icons.brush_rounded;
    if (lowerName.contains('code') || lowerName.contains('development') || lowerName.contains('tech')) return Icons.code_rounded;
    if (lowerName.contains('business') || lowerName.contains('finance')) return Icons.business_center_rounded;
    if (lowerName.contains('market')) return Icons.campaign_rounded;
    if (lowerName.contains('photo') || lowerName.contains('video')) return Icons.camera_alt_rounded;
    if (lowerName.contains('health')) return Icons.favorite_rounded;
    if (lowerName.contains('music') || lowerName.contains('audio')) return Icons.music_note_rounded;
    if (lowerName.contains('language')) return Icons.language_rounded;
    return Icons.category_rounded; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('All Categories', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: KaidaLoader())
          : _categories.isEmpty
              ? Center(child: Text("No categories found.", style: TextStyle(color: Colors.grey.shade500)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final catName = cat['name'] ?? 'Category';
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(_getIconForCategory(catName), color: AppTheme.primaryColor),
                      ),
                      title: Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(
                          actionType: 'category_${cat['id']}', 
                          title: catName
                        )));
                      },
                    );
                  },
                ),
    );
  }
}
