import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import '../utils/kaida_alert.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isLoading = true;
  List<dynamic> _downloads = [];
  Set<int> _downloadingItems = {};

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
      final response = await http.post(Uri.parse(ApiConfig.myDownloads), body: {'user_id': userId.toString()});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _downloads = data['data']);
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startNativeDownload(int orderId, int itemId) async {
    setState(() => _downloadingItems.add(itemId));
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getDownloadLink),
        body: {'user_id': userId.toString(), 'order_id': orderId.toString(), 'item_id': itemId.toString()},
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        String downloadUrl = data['url'];
        
        if (!downloadUrl.startsWith('http')) {
          downloadUrl = 'https://academy.kainuwa.africa/' + downloadUrl.replaceFirst(RegExp(r'^/+'), '');
        }

        final Uri url = Uri.parse(downloadUrl);
        
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch downloader');
        }
      } else {
        if (!mounted) return;
        KaidaAlert.showModal(context: context, title: 'Download Error', message: data['message'] ?? 'Error generating link', isError: true);
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (!mounted) return;
      KaidaAlert.showModal(context: context, title: 'Download Failed', message: 'Failed to initiate download. Please check your connection.', isError: true);
    } finally {
      setState(() => _downloadingItems.remove(itemId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final cardColor = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Saved Downloads', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
        ),
      ),
      body: _isLoading
          ? const Center(child: KaidaLoader())
          : _downloads.isEmpty
              ? Center(child: Text('You have no digital downloads yet.', style: TextStyle(color: subTextColor, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final item = _downloads[index];
                    String rawThumb = item['thumbnail_url']?.toString() ?? '';
                    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) {
                      rawThumb = 'https://academy.kainuwa.africa/' + rawThumb.replaceFirst(RegExp(r'^/+'), '');
                    }

                    int orderId = int.tryParse(item['order_id']?.toString() ?? '0') ?? 0;
                    int itemId = int.tryParse(item['item_id']?.toString() ?? '0') ?? 0;
                    bool isDownloading = _downloadingItems.contains(itemId);

                    return Card(
                      color: cardColor,
                      elevation: isDark ? 0 : 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: rawThumb.isNotEmpty 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(rawThumb, width: 60, height: 60, fit: BoxFit.cover)
                              )
                            : Container(width: 60, height: 60, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2, color: Colors.white)),
                        title: Text(item['title'] ?? 'Digital Product', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        subtitle: Text('Digital Product', style: TextStyle(color: subTextColor, fontSize: 12)),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.primaryColor, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                            side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.transparent),
                          ),
                          icon: isDownloading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download, size: 16, color: Colors.white),
                          label: Text(isDownloading ? 'Starting...' : 'Download', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: (isDownloading || orderId == 0) ? null : () => _startNativeDownload(orderId, itemId),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
