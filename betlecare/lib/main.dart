// main.dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:betlecare/pages/market/a_market_screen.dart';
import 'package:betlecare/pages/notification_screen.dart'; // Add this for the notification screen
import 'package:betlecare/pages/sidebar_menu.dart';
import 'package:betlecare/providers/notification_provider.dart';
import 'package:betlecare/providers/user_provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:betlecare/pages/harvest/harvest_screen.dart';
import 'package:betlecare/pages/home_screen.dart';
import 'package:betlecare/pages/profile_screen.dart';
import 'package:betlecare/pages/splash_screen.dart';
import 'package:betlecare/widgets/bottom_nav_bar.dart';
import 'package:betlecare/widgets/profile_header.dart';
import 'package:betlecare/pages/login_page.dart';
import 'package:betlecare/pages/signup_page.dart';
import 'package:betlecare/supabase_client.dart';
import 'package:line_icons/line_icons.dart';
import 'package:betlecare/pages/weather/weather_screen.dart';
import 'package:betlecare/pages/disease/disease_management_home.dart';
import 'package:betlecare/services/popup_notification_service.dart';
import 'dart:async'; // Add this for Timer

// Add a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null, // no app icon, will use default
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for general updates',
        defaultColor: Colors.teal,
        ledColor: Colors.teal,
        importance: NotificationImportance.High,
      ),
      NotificationChannel(
        channelGroupKey: 'alerts_channel_group',
        channelKey: 'alerts_channel',
        channelName: 'Alert Notifications',
        channelDescription: 'Urgent notifications that require attention',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        importance: NotificationImportance.High,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic Group',
      ),
      NotificationChannelGroup(
        channelGroupKey: 'alerts_channel_group',
        channelGroupName: 'Alert Group',
      ),
    ],
    debug: true,
  );
  
  await SupabaseClientManager.instance;

  final userProvider = UserProvider();
  await userProvider.initializeUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: userProvider,
        ),
        ChangeNotifierProvider(
          create: (context) => BetelBedProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// This static method is required for handling background/terminated notification actions
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  // Navigate to notification screen when notification is tapped
  if (receivedAction.channelKey == 'basic_channel' || 
      receivedAction.channelKey == 'alerts_channel') {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Set up notification listeners
    _setupNotificationListeners();
  }
  
  // Add this function for handling notification actions
  void _setupNotificationListeners() {
    // Set up listeners for notification actions in the newer API
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onNotificationActionReceived,
    );
  }
  
  @override
  void dispose() {
    // No need to close action sink in newer version
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulating splash delay

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is already logged in, navigate to main
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/main');
      });
    } else {
      // No session found, navigate to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Add this line
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/main': (context) => const MainPage(),
        '/notifications': (context) => const NotificationScreen(), // Add notification route
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 2;
  Timer? _notificationTimer;

  final List<Widget> _screens = [
    const HarvestScreen(),
    const MarketsScreen(),
    const HomeScreen(),
    const DiseaseManagementScreen(),
    const WeatherScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Preload betel bed data when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BetelBedProvider>(context, listen: false).loadBeds();

      // Initialize notification provider
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialize();
      
      // Check for notifications when app starts - after beds are loaded
      Future.delayed(const Duration(seconds: 2), () {
        notificationProvider.checkAllNotifications();
      });
      
      // Set up a periodic check (every 6 hours)
      _notificationTimer = Timer.periodic(const Duration(hours: 6), (_) {
        if (mounted) {
          notificationProvider.checkAllNotifications();
        }
      });

      // Check for arguments (selected tab index) when navigating back from sub-screens
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int && args >= 0 && args < _screens.length) {
        setState(() {
          _selectedIndex = args;
        });
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for notifications when app is resumed
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).checkAllNotifications();
      }
    }
  }

  void _onTabChange(int index) {
    // Check if we need to navigate back to main screen first
    if (Navigator.of(context).canPop()) {
      // Pop back to the main screen and then update the tab
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    setState(() {
      _selectedIndex = index;
    });
  }

 Future<void> _logout(BuildContext context) async {
    try {
      final supabase = await SupabaseClientManager.instance;
      await supabase.client.auth.signOut();

      // Delay to ensure session is cleared before navigating
      await Future.delayed(const Duration(milliseconds: 500));

      if (supabase.client.auth.currentSession == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SidebarMenu(
        onTabChange: _onTabChange,
      ),
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}