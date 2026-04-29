import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';
import 'main_layout.dart'; // Needed for home routing

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const WebViewScreen({Key? key, required this.title, required this.url}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false; 

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) { if (mounted) setState(() { _isLoading = true; _hasError = false; }); },
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
          onWebResourceError: (WebResourceError error) { if (mounted) setState(() { _isLoading = false; _hasError = true; }); },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () async {
            if (await _controller.canGoBack()) {
              _controller.goBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.title, 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home_rounded, color: isDark ? Colors.white : Colors.black, size: 22), 
            onPressed: () {
              // Immediately routs the user back to the app homepage
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const MainLayout()), 
                (route) => false
              );
            }
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black, size: 22), 
            onPressed: () {
              setState(() { _hasError = false; _isLoading = true; });
              _controller.reload();
            }
          ),
          const SizedBox(width: 8), // Small padding on the right edge
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Connection Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    onPressed: () { setState(() { _hasError = false; _isLoading = true; }); _controller.reload(); },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
            
          if (_isLoading && !_hasError) const Center(child: KaidaLoader()),
        ],
      ),
    );
  }
}
