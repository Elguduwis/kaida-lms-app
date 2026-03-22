import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isLoading = true;
  List<dynamic> _digitalProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchDigitalDownloads();
  }

  Future<void> _fetchDigitalDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Assuming you have an endpoint for purchased digital products. 
      // Adjust the URL if your endpoint is different!
      final response = await http.post(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/my_downloads.php'), 
        body: {'user_id': userId.toString()}
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _digitalProducts = data['data'];
            _isLoading = false;
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(String fileUrl) async {
    if (fileUrl.isEmpty) return;
    
    if (!fileUrl.startsWith('http')) {
      fileUrl = 'https://academy.kainuwa.africa/' + fileUrl;
    }

    final Uri url = Uri.parse(fileUrl);
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch download link.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error launching download.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Detectors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    // In your screenshot, the card was dark. We'll make it adapt slightly but keep that premium feel.
    final cardColor = isDark ? AppTheme.darkSurfaceColor : const Color(0xFF1E1E21); 
    final cardTextColor = Colors.white; 
    final cardSubTextColor = Colors.grey.shade400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Downloads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _digitalProducts.isEmpty
              ? _buildEmptyState(textColor, subTextColor)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _digitalProducts.length,
                  itemBuilder: (context, index) {
                    final item = _digitalProducts[index];
                    
                    String rawThumb = item['thumbnail_url']?.toString() ?? '';
                    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
                      rawThumb = 'https://academy.kainuwa.africa/' + rawThumb;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: rawThumb.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: rawThumb,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Container(color: Colors.grey.shade800, child: const Icon(Icons.inventory_2, color: Colors.white)),
                                    )
                                  : Container(color: Colors.grey.shade800, child: const Icon(Icons.inventory_2, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'Digital Product',
                                  style: TextStyle(color: cardTextColor, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Digital Product',
                                  style: TextStyle(color: cardSubTextColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Download Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              _downloadFile(item['file_url'] ?? item['download_link'] ?? '');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No digital products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text('Any digital files you purchase will appear here.', style: TextStyle(color: subTextColor)),
        ],
      ),
    );
  }
}
