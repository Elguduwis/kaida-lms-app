import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  // NATIVE DIRECT DOWNLOAD METHOD
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
        final Uri url = Uri.parse(data['url']);
        // This launches the phone's native file downloader!
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch downloader');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initiate download.')));
    } finally {
      setState(() => _downloadingItems.remove(itemId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('My Digital Downloads', style: TextStyle(color: Colors.white, fontSize: 16)), iconTheme: const IconThemeData(color: Colors.white)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _downloads.isEmpty
              ? const Center(child: Text('You have no digital downloads yet.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final item = _downloads[index];
                    String rawThumb = item['thumbnail_url']?.toString() ?? '';
                    if (rawThumb.isNotEmpty && !rawThumb.startsWith('http')) rawThumb = 'https://academy.kainuwa.africa/' + rawThumb;

                    int orderId = int.tryParse(item['order_id']?.toString() ?? '0') ?? 0;
                    int itemId = int.tryParse(item['item_id']?.toString() ?? '0') ?? 0;
                    bool isDownloading = _downloadingItems.contains(itemId);

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
                          icon: isDownloading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download, size: 16, color: Colors.white),
                          label: Text(isDownloading ? 'Starting...' : 'Download', style: const TextStyle(color: Colors.white)),
                          onPressed: (isDownloading || orderId == 0) ? null : () => _startNativeDownload(orderId, itemId),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
