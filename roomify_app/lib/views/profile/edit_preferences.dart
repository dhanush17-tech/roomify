import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';

class EditPreferencesScreen extends StatefulWidget {
  @override
  _EditPreferencesScreenState createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  List<String> _selectedPreferences = [];
  final Map<String, TextEditingController> _socialControllers = {
    'Facebook': TextEditingController(),
    'Twitter': TextEditingController(),
    'Snapchat': TextEditingController(),
    'Instagram': TextEditingController(),
  };

  static const List<String> availablePreferences = [
    'Early riser',
    'Night owl',
    'Non-smoker',
    'Pet lover',
    'Vegetarian',
    'Vegan',
    'Quiet',
    'Social',
    'Tidy',
    'Student',
  ];

  void _loadUserPreferences() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      setState(() {
        _selectedPreferences =
            user.preferences.map((p) => p.preference).toList();

        // Load social media links
        for (var link in user.socialLinks) {
          if (_socialControllers.containsKey(link.platform)) {
            _socialControllers[link.platform]!.text = link.username;
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _socialControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Preferences'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availablePreferences.map((preference) {
              return FilterChip(
                label: Text(preference),
                selected: _selectedPreferences.contains(preference),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPreferences.add(preference);
                    } else {
                      _selectedPreferences.remove(preference);
                    }
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          Text(
            'Social Media Links',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ..._socialControllers.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: entry.key,
                  prefixIcon: Icon(_getSocialIcon(entry.key)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _savePreferences,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Save Preferences'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreferences() async {
    try {
      final socialLinks = Map.fromEntries(
        _socialControllers.entries
            .where((e) => e.value.text.isNotEmpty)
            .map((e) => MapEntry(e.key, e.value.text)),
      );

      await context.read<ProfileProvider>().updatePreferences(
            preferences: _selectedPreferences,
          );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update preferences: $e')),
      );
  }
  }

  IconData _getSocialIcon(String platform) {
    switch (platform) {
      case 'Facebook':
        return Icons.facebook;
      case 'Twitter':
        return Icons.flutter_dash;
      case 'Instagram':
        return Icons.camera_alt;
      case 'Snapchat':
        return Icons.photo_camera;
      default:
        return Icons.link;
    }
  }
}
