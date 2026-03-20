import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'profile_screen.dart'; // To reuse WebDashboardScreen

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isLoading = true;
  List<dynamic> _downloads = [];

  @override
  void initState() {
    super.initState();
    _fetchDownloads();
  }

  Future<void> _fetchDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.myDownloads),
        body: {'user_id': userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) setState(() => _downloads = data['data']);
        }
      }
    } catch (e) {
      debugPrint("Downloads API Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDownloadWeb(String slug, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;
    
    // Open the product page natively so they can access their files securely
    final authUrl = 'https://academy.kainuwa.africa/api/mobile/webview_auth.php?user_id=$userId&redirect=/view_product.php?slug=$slug';
    
    Navigator.push(context, MaterialPageRoute(builder: (context) => WebDashboardScreen(url: authUrl, title: title)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('My Digital Downloads')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : _downloads.isEmpty
          ? const Center(child: Text('You have not purchased any digital products yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _downloads.length,
              itemBuilder: (context, index) {
                final item = _downloads[index];
                String rawThumb = item['thumbnail_url']?.toString() ?? '';
                if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
                  rawThumb = 'https://academy.kainuwa.africa/' + rawThumb;
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: rawThumb.isNotEmpty 
                        ? Image.network(rawThumb, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: AppTheme.primaryColor, child: const Icon(Icons.inventory_2, color: Colors.white)),
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Digital Product', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      icon: const Icon(Icons.download, size: 16, color: Colors.white),
                      label: const Text('Access', style: TextStyle(color: Colors.white)),
                      onPressed: () => _openDownloadWeb(item['slug'], item['title']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
