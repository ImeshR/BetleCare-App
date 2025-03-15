import 'package:betlecare/pages/market/a_market_screen.dart';
import 'package:betlecare/pages/sidebar_menu.dart';
import 'package:betlecare/providers/notification_provider.dart';
import 'package:betlecare/providers/user_provider.dart';
import 'package:betlecare/providers/betel_bed_provider.dart'; // Added import for BetelBedProvider
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

void main() async {
  await dotenv.load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
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
          create: (context) => NotificationProvider(), // Add this line
        ),
      ],
      child: const MyApp(),
    ),
  );
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
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 2;

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
    // Preload betel bed data when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BetelBedProvider>(context, listen: false).loadBeds();

      // Check for arguments (selected tab index) when navigating back from sub-screens
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int && args >= 0 && args < _screens.length) {
        setState(() {
          _selectedIndex = args;
        });
      }
    });
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
    // Existing logout code...
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
