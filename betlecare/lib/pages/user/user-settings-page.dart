import 'package:betlecare/pages/notification_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:betlecare/providers/notification_provider.dart';
 

import '../../styles/auth_styles.dart';
import '../../supabase_client.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({Key? key}) : super(key: key);

  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingSettings = true;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // User settings
  bool _notificationsEnabled = true;
  bool _paymentStatus = false;
  bool _isNewUser = true;

  // User info
  String _firstName = '';
  String _lastName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user != null) {
        setState(() {
          _firstName = user.userMetadata?['first_name'] ?? '';
          _lastName = user.userMetadata?['last_name'] ?? '';
          _email = user.email ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('පරිශීලක දත්ත පූරණය කිරීමේ දෝෂයක්: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoadingSettings = true;
    });

    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user != null) {
        final response = await supabase.client
            .from('user_settings')
            .select()
            .eq('userid', user.id)
            .single();

        setState(() {
          _notificationsEnabled = response['notification_enable'] ?? true;
          _paymentStatus = response['payment_status'] ?? false;
          _isNewUser = response['new_user'] ?? true;
          _isLoadingSettings = false;
        });
        
        // Update notification provider with the latest setting
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.updateNotificationPreferences(
          notificationsEnabled: _notificationsEnabled,
        );
      }
    } catch (e) {
      print('Error loading settings: $e');
      // If settings don't exist yet, create default settings
      _createDefaultSettings();
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user != null) {
        await supabase.client.from('user_settings').insert({
          'userid': user.id,
          'payment_status': false,
          'notification_enable': true,
          'new_user': true,
        });

        setState(() {
          _notificationsEnabled = true;
          _paymentStatus = false;
          _isNewUser = true;
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSettings = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('සැකසුම් සුරැකීමේ දෝෂයක්: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateNotificationSettings(bool value) async {
    try {
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user != null) {
        await supabase.client
            .from('user_settings')
            .update({'notification_enable': value}).eq('userid', user.id);

        setState(() {
          _notificationsEnabled = value;
        });
        
        // Update notification provider with the latest setting
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.updateNotificationPreferences(
          notificationsEnabled: value,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('දැනුම්දීම් සැකසුම් යාවත්කාලීන කරන ලදී')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('සැකසුම් යාවත්කාලීන කිරීමේ දෝෂයක්: ${e.toString()}')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('නව මුරපද නොගැලපේ')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('මුරපදය අක්ෂර 6 කට වඩා දිග විය යුතුය')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = await SupabaseClientManager.instance;

      // Update password
      await supabase.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('මුරපදය සාර්ථකව යාවත්කාලීන කරන ලදී')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('මුරපදය යාවත්කාලීන කිරීමේ දෝෂයක්: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('පරිශීලක සැකසුම්'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoadingSettings
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  SizedBox(height: 16),
                  _buildPasswordChangeCard(),
                  SizedBox(height: 16),
                  _buildNotificationSettingsCard(),
                  SizedBox(height: 16),
                  _buildPaymentStatusCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AuthStyles.primaryColor.withOpacity(0.2),
                  child: Text(
                    _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AuthStyles.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_firstName $_lastName',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _email,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordChangeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: AuthStyles.primaryColor),
                SizedBox(width: 8),
                Text(
                  'මුරපදය වෙනස් කරන්න',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              decoration: AuthStyles.inputDecoration('වත්මන් මුරපදය').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AuthStyles.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureCurrentPassword,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: AuthStyles.inputDecoration('නව මුරපදය').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AuthStyles.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureNewPassword,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration:
                  AuthStyles.inputDecoration('නව මුරපදය තහවුරු කරන්න').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AuthStyles.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('මුරපදය යාවත්කාලීන කරන්න'),
                style: AuthStyles.elevatedButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: AuthStyles.primaryColor),
                SizedBox(width: 8),
                Text(
                  'දැනුම්දීම් සැකසුම්',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('දැනුම්දීම් සක්‍රීය කරන්න'),
              subtitle: Text(
                  'අස්වැන්න සහ අනෙකුත් යාවත්කාලීන කිරීම් සඳහා දැනුම්දීම් ලබා ගන්න'),
              value: _notificationsEnabled,
              activeColor: AuthStyles.primaryColor,
              onChanged: (bool value) {
                _updateNotificationSettings(value);
              },
            ),
            SizedBox(height: 8),
            // Button to navigate to detailed notification settings
            Center(
              child: OutlinedButton.icon(
                icon: Icon(Icons.settings),
                label: Text('තවත් දැනුම්දීම් සැකසුම්'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationPreferencesScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuthStyles.primaryColor,
                  side: BorderSide(color: AuthStyles.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: _paymentStatus ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  'ගෙවීම් තත්ත්වය',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _paymentStatus
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _paymentStatus
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _paymentStatus ? Icons.check_circle : Icons.info,
                        color: _paymentStatus ? Colors.green : Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _paymentStatus
                            ? 'ගෙවීම් සම්පූර්ණයි'
                            : 'ගෙවීම් අවශ්‍යයි',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _paymentStatus
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _paymentStatus
                        ? 'ඔබගේ ගිණුම සක්‍රීයයි. සියලුම විශේෂාංග භාවිතා කිරීමට ඔබට ප්‍රවේශය ඇත.'
                        : 'සියලුම විශේෂාංග භාවිතා කිරීමට ඔබගේ දායකත්වය යාවත්කාලීන කරන්න.',
                    style: TextStyle(
                      color: _paymentStatus
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  if (!_paymentStatus) ...[
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to payment page
                        },
                        icon: Icon(Icons.credit_card),
                        label: Text('දැන් ගෙවන්න'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}