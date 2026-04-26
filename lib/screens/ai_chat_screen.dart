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
          setState(() {
            _sessions = List<Map<String, dynamic>>.from(data['data']);
          });
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
    Navigator.pop(context); // Close drawer

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
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
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
      // Added an explicit 25-second timeout to prevent indefinite hanging
      final response = await http.post(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=chat'),
        body: {
          'user_id': _userId.toString(),
          'session_id': _currentSessionId?.toString() ?? '0',
          'message': text,
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _currentSessionId = data['session_id'];
            _messages.add(ChatMessage(text: data['message'], isUser: false));
            _isTyping = false;
          });
          _scrollToBottom();
          if (_sessions.isEmpty || _sessions.first['id'] != _currentSessionId) {
            _loadSessions(); // Refresh list if new session created
          }
        }
      } else {
        throw Exception("Server Error");
      }
    } on TimeoutException {
      setState(() {
        _messages.add(ChatMessage(text: "Request timed out. The AI took too long to respond. Please try again.", isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Network error. Please try again.", isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Kaida AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          )
        ],
      ),
      endDrawer: _buildHistoryDrawer(isDark),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : _messages.isEmpty 
                  ? _buildWelcomeScreen(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessageBubble(_messages[index], isDark),
                    ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Kaida AI is typing...', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              ),
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
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: AppTheme.primaryColor,
              child: const Text('Chat History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
              title: const Text('Start New Chat', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              onTap: _startNewChat,
            ),
            const Divider(),
            Expanded(
              child: _sessions.isEmpty
                ? Center(child: Text('No previous chats', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey)))
                : ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return ListTile(
                        leading: Icon(Icons.chat_bubble_outline, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        title: Text(session['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        onTap: () => _loadHistory(int.parse(session['id'].toString())),
                      );
                    },
                  ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text('Welcome to Kaida AI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            Text(
              'I can help you discover your path, choose the right courses, and learn how to monetize your skills.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: [
                _buildQuickStarter('I don\'t know what to learn. Help me!'),
                _buildQuickStarter('Suggest a course for beginners.'),
                _buildQuickStarter('How do I monetize my skills?'),
                _buildQuickStarter('What are my career options?'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStarter(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _handleSubmitted(text),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final bgColor = message.isUser 
        ? AppTheme.primaryColor 
        : (isDark ? AppTheme.darkSurfaceColor : Colors.white);
    final textColor = message.isUser 
        ? Colors.white 
        : (isDark ? Colors.white : Colors.black87);
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(message.isUser ? 20 : 0),
      bottomRight: Radius.circular(message.isUser ? 0 : 20),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isUser)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      if (!message.isUser)
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Message Kaida AI...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: _handleSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _handleSubmitted(_textController.text),
              child: Container(
                height: 48, width: 48,
                decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
