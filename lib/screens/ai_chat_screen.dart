import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  _AiChatScreenState createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  int? _userId;
  int? _currentSessionId;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _sessions = [];
  bool _isTyping = false;
  bool _isLoadingHistory = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    if (_userId != null) {
      _loadSessions();
    } else {
      _messages.add(ChatMessage(text: "Please log in to chat with Kaida AI.", isUser: false));
      setState(() {});
    }
  }

  Future<void> _loadSessions() async {
    try {
      final response = await http.get(Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=get_sessions&user_id=$_userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() { _sessions = List<Map<String, dynamic>>.from(data['data']); });
        }
      }
    } catch (e) {
      debugPrint("Failed to load sessions.");
    }
  }

  Future<void> _loadHistory(int sessionId) async {
    setState(() {
      _isLoadingHistory = true;
      _currentSessionId = sessionId;
      _messages.clear();
    });
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) Navigator.pop(context);

    try {
      final response = await http.get(Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=get_history&session_id=$sessionId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<ChatMessage> loaded = [];
          for (var msg in data['data']) {
            loaded.add(ChatMessage(text: msg['message'], isUser: msg['role'] == 'user'));
          }
          setState(() {
            _messages = loaded;
            _isLoadingHistory = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
    });
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) Navigator.pop(context);
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _userId == null) return;
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=chat'),
        body: {
          'user_id': _userId.toString(),
          'session_id': _currentSessionId?.toString() ?? '0',
          'message': text,
        },
      ).timeout(const Duration(seconds: 40)); // PROTECTIVE TIMEOUT

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _currentSessionId = data['session_id'];
            _messages.add(ChatMessage(text: data['message'], isUser: false));
            _isTyping = false;
          });
          _scrollToBottom();
          if (_sessions.isEmpty || _sessions.first['id'] != _currentSessionId) _loadSessions();
        }
      } else {
        throw Exception("Server Error");
      }
    } on TimeoutException {
      setState(() {
        _messages.add(ChatMessage(text: "Kaida AI is taking longer than usual. The response will appear in your history once processed.", isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Network error. Please check your connection and try again.", isUser: false));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.primaryColor,
        title: const Text('Kaida AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openEndDrawer())],
      ),
      endDrawer: _buildHistoryDrawer(isDark),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _messages.isEmpty ? _buildWelcomeScreen(isDark) : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index], isDark),
                ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Kaida AI is thinking...', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(16), width: double.infinity, color: AppTheme.primaryColor, child: const Text('Chat History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ListTile(leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor), title: const Text('New Chat'), onTap: _startNewChat),
            const Divider(),
            Expanded(child: ListView.builder(itemCount: _sessions.length, itemBuilder: (context, index) => ListTile(
              title: Text(_sessions[index]['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _loadHistory(int.parse(_sessions[index]['id'].toString())),
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.auto_awesome, size: 64, color: AppTheme.primaryColor),
      const SizedBox(height: 16),
      Text('Welcome to Kaida AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    ]));
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.primaryColor : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.text, style: TextStyle(color: message.isUser ? Colors.white : (isDark ? Colors.white : Colors.black87))),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceColor : Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
      child: SafeArea(child: Row(children: [
        Expanded(child: TextField(controller: _textController, decoration: const InputDecoration(hintText: 'Ask Kaida AI...', border: InputBorder.none))),
        IconButton(icon: const Icon(Icons.send, color: AppTheme.primaryColor), onPressed: () => _handleSubmitted(_textController.text)),
      ])),
    );
  }
}
