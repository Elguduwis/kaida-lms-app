import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../config/app_theme.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _downloads = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    List<Map<String, dynamic>> loaded = [];

    for (String key in keys) {
      if (key.startsWith('offline_lesson_')) {
        String path = prefs.getString(key)!;
        File file = File(path);
        
        if (await file.exists()) {
          int sizeInBytes = await file.length();
          double sizeInMb = sizeInBytes / (1024 * 1024);
          String lessonId = key.replaceFirst('offline_lesson_', '');
          
          loaded.add({
            'key': key,
            'path': path,
            'lesson_id': lessonId,
            'size': '${sizeInMb.toStringAsFixed(2)} MB',
            // Since we don't have a local DB of titles, we use a generic placeholder
            'title': 'Offline Lesson $lessonId', 
          });
        } else {
          // Cleanup missing files from SharedPreferences
          await prefs.remove(key);
        }
      }
    }

    if (mounted) {
      setState(() {
        _downloads = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(String key, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    
    File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    
    _loadDownloads();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download removed'), backgroundColor: Colors.red)
      );
    }
  }

  void _playVideo(String path, String title) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => OfflinePlayerScreen(videoPath: path, title: title))
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Theme Detectors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _downloads.isEmpty
              ? _buildEmptyState(textColor, subTextColor)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final item = _downloads[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.video_library, color: AppTheme.primaryColor),
                        ),
                        title: Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        subtitle: Text(item['size'], style: TextStyle(color: subTextColor, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 32),
                              onPressed: () => _playVideo(item['path'], item['title']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteDownload(item['key'], item['path']),
                            ),
                          ],
                        ),
                        onTap: () => _playVideo(item['path'], item['title']),
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
          Icon(Icons.cloud_download_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No downloads yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text(
            'Save videos to watch them offline.',
            style: TextStyle(color: subTextColor),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// OFFLINE VIDEO PLAYER SCREEN
// ==========================================
class OfflinePlayerScreen extends StatefulWidget {
  final String videoPath;
  final String title;

  const OfflinePlayerScreen({Key? key, required this.videoPath, required this.title}) : super(key: key);

  @override
  _OfflinePlayerScreenState createState() => _OfflinePlayerScreenState();
}

class _OfflinePlayerScreenState extends State<OfflinePlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() => _hasError = true);
        return;
      }

      _videoController = VideoPlayerController.file(file);
      await _videoController.initialize();
      
      if (mounted) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: false,
            allowPlaybackSpeedChanging: true,
            errorBuilder: (context, errorMessage) {
              return Center(child: Text('Playback Error: $errorMessage', style: const TextStyle(color: Colors.white)));
            },
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Video players should always have a black background
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        elevation: 0,
      ),
      body: Center(
        child: _hasError
            ? const Text('Error loading video file. It may be corrupted or deleted.', style: TextStyle(color: Colors.red))
            : (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }
}
