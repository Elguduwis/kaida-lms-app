import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart'; // To reuse WebDashboardScreen

class ItemDetailsScreen extends StatelessWidget {
  final CatalogItem item;

  const ItemDetailsScreen({Key? key, required this.item}) : super(key: key);

  void _processCheckout(BuildContext context, String actionType) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    
    // Direct user to the correct web view based on the item type
    final redirect = item.type == 'course' ? '/view_course.php?slug=${item.slug}' : '/view_product.php?slug=${item.slug}';
    final authUrl = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$userId&redirect=$redirect';
    
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
      body: CustomScrollView(
        slivers: [
          // Native Image Header
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: item.thumbnailUrl.isNotEmpty
                  ? Image.network(item.thumbnailUrl, fit: BoxFit.cover)
                  : Container(color: AppTheme.primaryColor, child: const Icon(Icons.school, size: 80, color: Colors.white)),
            ),
          ),
          
          // Native Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(item.categoryName, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(item.type == 'course' ? 'Instructor: ${item.instructorName}' : 'Kainuwa Digital Product', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Price Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildPriceDisplay(),
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => _processCheckout(context, 'enroll'),
                            child: Text(item.type == 'course' ? 'Enroll Now' : 'Buy Now', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (item.type == 'course')
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              icon: const Icon(Icons.card_giftcard, color: AppTheme.primaryColor),
                              label: const Text('Gift this Course', style: TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              onPressed: () => _processCheckout(context, 'gift'), // Routes to web to handle the gift modal
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (item.isFree || (item.price == 0 && item.discountPrice == 0)) {
      return const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 28));
    }
    if (item.discountPrice > 0 && item.discountPrice < item.price) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('₦${item.discountPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryColor)),
          const SizedBox(width: 8),
          Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 16)),
        ],
      );
    }
    return Text('₦${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryColor));
  }
}
