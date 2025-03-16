import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:betlecare/providers/notification_provider.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('දැනුම්දීම් සැකසුම්'),  // Notification Settings
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main notification toggle
              _buildMainToggleCard(context, notificationProvider),
              
              const SizedBox(height: 16),
              
              // Specific notification type toggles
              _buildNotificationTypesCard(context, notificationProvider),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainToggleCard(BuildContext context, NotificationProvider provider) {
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
                const Icon(Icons.notifications, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'දැනුම්දීම්',  // Notifications
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: provider.notificationsEnabled,
                  onChanged: (value) {
                    provider.updateNotificationPreferences(
                      notificationsEnabled: value,
                    );
                  },
                  activeColor: Colors.teal,
                ),
              ],
            ),
            Text(
              provider.notificationsEnabled
                  ? 'දැනුම්දීම් සක්‍රීයයි' // Notifications are enabled
                  : 'දැනුම්දීම් අක්‍රීයයි', // Notifications are disabled
              style: TextStyle(
                color: provider.notificationsEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationTypesCard(BuildContext context, NotificationProvider provider) {
    // Disable all toggles if main notifications are disabled
    final bool enableToggles = provider.notificationsEnabled;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'දැනුම්දීම් වර්ග',  // Notification Types
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Weather notifications
            _buildNotificationTypeToggle(
              icon: Icons.cloud,
              iconColor: Colors.blue,
              title: 'කාලගුණ දැනුම්දීම්',  // Weather notifications
              subtitle: 'අධික වැසි සහ උෂ්ණත්ව අනතුරු ඇඟවීම්',  // Heavy rain and temperature warnings
              value: provider.weatherNotificationsEnabled,
              enabled: enableToggles,
              onChanged: (value) {
                provider.updateNotificationPreferences(
                  weatherNotifications: value,
                );
              },
            ),
            
            const Divider(),
            
            // Harvest notifications
            _buildNotificationTypeToggle(
              icon: Icons.agriculture,
              iconColor: Colors.green,
              title: 'අස්වනු දැනුම්දීම්',  // Harvest notifications
              subtitle: 'අස්වනු කාලය පිළිබඳ මතක්කිරීම්',  // Harvest time reminders
              value: provider.harvestNotificationsEnabled,
              enabled: enableToggles,
              onChanged: (value) {
                provider.updateNotificationPreferences(
                  harvestNotifications: value,
                );
              },
            ),
            
            const Divider(),
            
            // Fertilizer notifications
            _buildNotificationTypeToggle(
              icon: Icons.spa,
              iconColor: Colors.teal,
              title: 'පොහොර දැනුම්දීම්',  // Fertilizer notifications
              subtitle: 'පොහොර යෙදීමේ කාලය පිළිබඳ මතක්කිරීම්',  // Fertilizing time reminders
              value: provider.fertilizeNotificationsEnabled,
              enabled: enableToggles,
              onChanged: (value) {
                provider.updateNotificationPreferences(
                  fertilizeNotifications: value,
                );
              },
            ),
            
            const Divider(),
            
            // Disease notifications
            _buildNotificationTypeToggle(
              icon: Icons.sick,
              iconColor: Colors.red,
              title: 'රෝග දැනුම්දීම්',  // Disease notifications
              subtitle: 'රෝග ආසාදන සහ පළිබෝධ පාලන මතක්කිරීම්',  // Disease and pest control reminders
              value: provider.diseaseNotificationsEnabled,
              enabled: enableToggles,
              onChanged: (value) {
                provider.updateNotificationPreferences(
                  diseaseNotifications: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationTypeToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: SwitchListTile(
        secondary: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: iconColor,
      ),
    );
  }
}