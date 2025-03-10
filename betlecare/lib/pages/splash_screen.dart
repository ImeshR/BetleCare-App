import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:betlecare/main.dart';
import 'package:betlecare/pages/login_page.dart';
import 'package:betlecare/supabase_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Delay for 5 seconds to show the animation
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    final supabase = await SupabaseClientManager.instance;
    final user = supabase.client.auth.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              "https://lottie.host/08fd21f4-4d0f-4ddd-a7a6-9434caa397b6/lykm1jOaUY.json",
              fit: BoxFit.cover,
              width: 300,
              height: 250,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.green[700]),
          ],
        ),
      ),
    );
  }
}
