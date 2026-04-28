import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../widgets/kaida_loader.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, List<dynamic>> _faqs = {};
  Map<String, String> _contactInfo = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHelpData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHelpData() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.helpCenter));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _faqs = Map<String, List<dynamic>>.from(data['data']['faqs']);
            _contactInfo = Map<String, String>.from(data['data']['contact']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Help Center Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String urlString, {bool isEmail = false}) async {
    if (urlString.isEmpty) return;
    
    final Uri url = isEmail 
        ? Uri(scheme: 'mailto', path: urlString, queryParameters: {'subject': 'Support Request - Kainuwa Academy'}) 
        : Uri.parse(urlString);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch application.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Help Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact Us'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: KaidaLoader())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFaqTab(isDark),
                _buildContactTab(isDark),
              ],
            ),
    );
  }

  Widget _buildFaqTab(bool isDark) {
    if (_faqs.isEmpty) {
      return Center(child: Text("No FAQs available.", style: TextStyle(color: Colors.grey.shade500)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _faqs.keys.length,
      itemBuilder: (context, index) {
        String category = _faqs.keys.elementAt(index);
        List<dynamic> questions = _faqs[category]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.toUpperCase(), 
                style: TextStyle(
                  color: AppTheme.primaryColor, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 12, 
                  letterSpacing: 1.2
                )
              ),
              const SizedBox(height: 12),
              ...questions.map((q) => _buildFaqTile(q['question'] ?? '', q['answer'] ?? '', isDark)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqTile(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Removes default expansion lines
        child: ExpansionTile(
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: isDark ? Colors.white : Colors.grey.shade600,
          title: Text(
            question, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 15, 
              color: isDark ? Colors.white : Colors.black87
            )
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer, 
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                  fontSize: 14, 
                  height: 1.5
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.support_agent_rounded, size: 80, color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            'How can we help you?', 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black
            )
          ),
          const SizedBox(height: 8),
          Text(
            'It looks like you are experiencing problems with our platform. We are here to help so please get in touch with us.', 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 15, 
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.5
            )
          ),
          const SizedBox(height: 40),

          // Email Card
          _buildContactCard(
            title: 'Email Us',
            subtitle: _contactInfo['email'] ?? 'support@kainuwa.africa',
            icon: Icons.email_rounded,
            iconColor: Colors.redAccent,
            isDark: isDark,
            onTap: () => _launchUrl(_contactInfo['email'] ?? '', isEmail: true),
          ),

          // Facebook Card
          if ((_contactInfo['facebook'] ?? '').isNotEmpty)
            _buildContactCard(
              title: 'Facebook',
              subtitle: 'Follow our page',
              icon: FontAwesomeIcons.facebook,
              iconColor: Colors.blue.shade700,
              isDark: isDark,
              onTap: () => _launchUrl(_contactInfo['facebook']!),
            ),

          // Twitter / X Card
          if ((_contactInfo['twitter'] ?? '').isNotEmpty)
            _buildContactCard(
              title: 'X (Twitter)',
              subtitle: 'Send us a direct message',
              icon: FontAwesomeIcons.xTwitter,
              iconColor: isDark ? Colors.white : Colors.black,
              isDark: isDark,
              onTap: () => _launchUrl(_contactInfo['twitter']!),
            ),

          // Instagram Card
          if ((_contactInfo['instagram'] ?? '').isNotEmpty)
            _buildContactCard(
              title: 'Instagram',
              subtitle: 'See our latest updates',
              icon: FontAwesomeIcons.instagram,
              iconColor: Colors.purple.shade400,
              isDark: isDark,
              onTap: () => _launchUrl(_contactInfo['instagram']!),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color iconColor, 
    required bool isDark,
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle
          ),
          child: FaIcon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
