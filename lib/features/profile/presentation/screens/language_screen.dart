import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  // Currently selected language
  String _selectedLanguage = 'English (US)';
  
  // Available languages
  final List<Map<String, String>> _languages = [
    {'code': 'en_US', 'name': 'English (US)', 'native': 'English (US)'},
    {'code': 'en_GB', 'name': 'English (UK)', 'native': 'English (UK)'},
    {'code': 'es_ES', 'name': 'Spanish', 'native': 'Español'},
    {'code': 'fr_FR', 'name': 'French', 'native': 'Français'},
    {'code': 'de_DE', 'name': 'German', 'native': 'Deutsch'},
    {'code': 'it_IT', 'name': 'Italian', 'native': 'Italiano'},
    {'code': 'pt_BR', 'name': 'Portuguese (Brazil)', 'native': 'Português (Brasil)'},
    {'code': 'nl_NL', 'name': 'Dutch', 'native': 'Nederlands'},
    {'code': 'zh_CN', 'name': 'Chinese (Simplified)', 'native': '中文 (简体)'},
    {'code': 'ja_JP', 'name': 'Japanese', 'native': '日本語'},
    {'code': 'ko_KR', 'name': 'Korean', 'native': '한국어'},
  ];

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Language',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Your Preferred Language',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Option to use device language
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    'Use Device Language',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically match your device settings',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Radio<String>(
                    value: 'system',
                    groupValue: _selectedLanguage == 'system' ? 'system' : '',
                    activeColor: const Color(0xFF12B347),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = 'system';
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedLanguage = 'system';
                    });
                  },
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'All Languages',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF12B347),
                  ),
                ),
              ),
              
              // Language list
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final isSelected = _selectedLanguage == language['name'];
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          language['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF12B347) : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          language['native']!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Radio<String>(
                          value: language['name']!,
                          groupValue: _selectedLanguage,
                          activeColor: const Color(0xFF12B347),
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = language['name']!;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // Apply button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyLanguageChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12B347),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Apply Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Apply language change
  void _applyLanguageChange() {
    // Here we would actually change the app language
    // For now, just show a confirmation
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to $_selectedLanguage'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Return to previous screen after applying
    Navigator.pop(context);
  }
} 