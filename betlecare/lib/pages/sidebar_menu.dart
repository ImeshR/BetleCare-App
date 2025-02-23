import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../supabase_client.dart';
import '../providers/user_provider.dart';

class SidebarMenu extends StatelessWidget {
  final Function(int) onTabChange;

  const SidebarMenu({Key? key, required this.onTabChange}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      final supabase = await SupabaseClientManager.instance;
      await supabase.client.auth.signOut();
      Provider.of<UserProvider>(context, listen: false).clearUser();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final userData = userProvider.userData;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user?.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user!.userMetadata!['avatar_url'])
                        : const AssetImage('assets/images/profile.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (user?.userMetadata?['full_name'] ??
                            user?.userMetadata?['first_name'] ??
                            'Guest')
                        .toString()
                        .replaceFirstMapped(RegExp(r'^[a-z]'),
                            (match) => match.group(0)!.toUpperCase()),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(LineIcons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              onTabChange(2);
            },
          ),
          ListTile(
            leading: const Icon(LineIcons.leaf),
            title: const Text('Harvest'),
            onTap: () {
              Navigator.pop(context);
              onTabChange(0);
            },
          ),
          ListTile(
            leading: const Icon(LineIcons.user),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              onTabChange(1);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LineIcons.alternateSignOut, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
