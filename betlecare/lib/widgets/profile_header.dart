import 'package:betlecare/pages/notification_screen.dart';
import 'package:betlecare/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../pages/user/user-settings-page.dart';
import '../providers/user_provider.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final notificationProvider = Provider.of<NotificationProvider>(context);
    // Get current time of the user in the local time zone
    final currentHour = DateTime.now().hour;

    String greeting = '';
    if (currentHour >= 0 && currentHour < 5) {
      greeting = 'සුභ රාත්‍රියක්'; // Good night
    } else if (currentHour < 12) {
      greeting = 'සුභ උදෑසනක්'; // Good morning
    } else if (currentHour < 17) {
      greeting = 'සුභ දවසක්'; // Good afternoon
    } else {
      greeting = 'සුභ සන්ධ්‍යාවක්'; // Good evening
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // Profile section
            Expanded(
              child: Row(
                children: [
                  // Avatar - now opens drawer on tap
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user?.userMetadata?['avatar_url'] != null
                          ? NetworkImage(user!.userMetadata!['avatar_url'])
                          : const AssetImage('assets/images/profile.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text section - now navigates to settings when tapped
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserSettingsPage(),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '👋',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Name
                        Row(
                          children: [
                            Text(
                              (user?.userMetadata?['full_name'] ??
                                      user?.userMetadata?['first_name'] ??
                                      'Guest')
                                  .toString()
                                  .replaceFirstMapped(RegExp(r'^[a-z]'),
                                      (match) => match.group(0)!.toUpperCase()),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.settings,
                              size: 14,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              children: [
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) => badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -10, end: 0),
                    badgeContent: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    badgeAnimation: const badges.BadgeAnimation.scale(
                      animationDuration: Duration(seconds: 1),
                      colorChangeAnimationDuration: Duration(seconds: 1),
                      loopAnimation: false,
                    ),
                    badgeStyle: badges.BadgeStyle(
                      shape: badges.BadgeShape.circle,
                      badgeColor: Colors.red,
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      icon:
                          const Icon(LineIcons.bellAlt, color: Colors.black87),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotificationScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
