import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'catalog_screen.dart';
import 'item_details_screen.dart';

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
  String _selectedLanguage = 'English'; 
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, List<String>> _quickStarters = {
    'English': [
      'I don\'t know what to learn. Help me!',
      'Suggest a course for beginners.',
      'How do I monetize my skills?',
      'What are my career options?'
    ],
    'Hausa': [
      'Ban san abin da zan koya ba. Taimake ni!',
      'Ba ni shawarar kwas ga masu fara koyo.',
      'Ta yaya zan sami kudi da fasahata?',
      'Wadanne damar aiki nake da su?'
    ]
  };

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
    Navigator.pop(context); 

    try {
      // CRITICAL FIX: Appended &user_id=$_userId so the server actually returns the data!
      final response = await http.get(Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=get_history&session_id=$sessionId&user_id=$_userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          List<ChatMessage> loaded = [];
          for (var msg in data['data']) {
            loaded.add(ChatMessage(text: msg['message'].toString(), isUser: msg['role'] == 'user'));
          }
          setState(() {
            _messages = loaded;
            _isLoadingHistory = false;
          });
          _scrollToBottom();
        } else {
          throw Exception(data['message'] ?? "Unknown load error");
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
        _messages.add(ChatMessage(text: "Could not load history. Details: ${e.toString()}", isUser: false));
      });
    }
  }

  Future<void> _deleteSession(int sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=delete_session'),
        body: {
          'user_id': _userId.toString(),
          'session_id': sessionId.toString(),
        },
      );
      if (response.statusCode == 200) {
        if (_currentSessionId == sessionId) {
           _startNewChat();
        } else {
           _loadSessions();
        }
      }
    } catch (e) {
      debugPrint("Failed to delete session.");
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
      final response = await http.post(
        Uri.parse('https://academy.kainuwa.africa/api/mobile/ai_chat.php?action=chat'),
        body: {
          'user_id': _userId.toString(),
          'session_id': _currentSessionId?.toString() ?? '0',
          'message': text,
          'language': _selectedLanguage,
        },
      ).timeout(const Duration(seconds: 95));

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<')) throw Exception("SERVER_HTML_TIMEOUT");

        try {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              _currentSessionId = int.tryParse(data['session_id'].toString());
              _messages.add(ChatMessage(text: data['message'].toString(), isUser: false));
              _isTyping = false;
            });
            _scrollToBottom();
            
            if (_sessions.isEmpty || _sessions.first['id'].toString() != _currentSessionId.toString()) {
              _loadSessions(); 
            }
          } else {
            throw Exception(data['message'] ?? 'Unknown Error');
          }
        } catch (e) {
          throw Exception("SERVER_HTML_TIMEOUT");
        }
      } else {
        throw Exception("SERVER_HTML_TIMEOUT");
      }
    } on TimeoutException {
      setState(() {
        _messages.add(ChatMessage(text: "Kaida AI is currently helping many students. Please wait a moment and try asking again.", isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        if (e.toString().contains("SERVER_HTML_TIMEOUT")) {
           _messages.add(ChatMessage(text: "Kaida AI is currently helping many students. Please wait a moment and try asking again.", isUser: false));
        } else {
           _messages.add(ChatMessage(text: "Network error. Please check your connection and try again.", isUser: false));
        }
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: AppTheme.primaryColor,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                    }
                  },
                  items: <String>['English', 'Hausa'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
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
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _deleteSession(int.parse(session['id'].toString())),
                        ),
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
    String welcomeTitle = _selectedLanguage == 'Hausa' ? 'Barka da zuwa Kaida AI' : 'Welcome to Kaida AI';
    String welcomeSub = _selectedLanguage == 'Hausa' 
        ? 'Zan iya taimaka muku gano hanyarku, zabi kwasoshin da suka dace, da kuma koyon yadda zaku sami kudi da fasaharku.' 
        : 'I can help you discover your path, choose the right courses, and learn how to monetize your skills.';
    
    List<String> starters = _quickStarters[_selectedLanguage] ?? _quickStarters['English']!;

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
            Text(welcomeTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              welcomeSub,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: starters.map((text) => _buildQuickStarter(text)).toList(),
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
                  child: message.isUser
                      ? Text(message.text, style: TextStyle(color: textColor, fontSize: 15, height: 1.4))
                      : MarkdownBody(
                          data: message.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                            strong: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                            h1: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                            h2: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: textColor),
                            a: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          ),
                          onTapLink: (text, href, title) async {
                            if (href != null && href.startsWith('kaida://course/')) {
                              final slug = href.replaceAll('kaida://course/', '');
                              
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext c) => const Center(child: CircularProgressIndicator()),
                              );

                              try {
                                final response = await http.get(Uri.parse('https://academy.kainuwa.africa/api/mobile/catalog.php?action=courses'));
                                Navigator.pop(context); 
                                
                                if (response.statusCode == 200) {
                                  final data = json.decode(response.body);
                                  if (data['status'] == 'success') {
                                    List<dynamic> items = data['data'];
                                    var courseData = items.firstWhere((item) => item['slug'] == slug, orElse: () => null);
                                    
                                    if (courseData != null) {
                                      final linkedItem = CatalogItem.fromJson(courseData, 'courses');
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => ItemDetailsScreen(item: linkedItem)
                                      ));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course not found or unavailable.')));
                                    }
                                  }
                                }
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch course details.')));
                              }
                            }
                          },
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
