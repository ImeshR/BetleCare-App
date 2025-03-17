import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:betlecare/main.dart';
import 'package:betlecare/pages/login_page.dart';
import 'package:betlecare/supabase_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  Future<bool> _isInternetAvailable() async {
    // First check if we have a network connection
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    // Then verify if we can actually access the internet
    try {
      // Try to connect to a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkInternetConnection() async {
    bool hasInternet = await _isInternetAvailable();

    if (!hasInternet) {
      // No internet connection
      if (mounted) {
        setState(() {
          _hasInternetConnection = false;
          _isLoading = false;
        });
        _showNoInternetDialog();
      }
    } else {
      // Internet connection is available, proceed with normal flow
      if (mounted) {
        setState(() {
          _hasInternetConnection = true;
        });
        _checkAuthAndNavigate();
      }
    }
  }

  void _showNoInternetDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('අන්තර්ජාල සම්බන්ධතාවය නැත'),
          content: const Text(
              'කරුණාකර ඔබගේ අන්තර්ජාල සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.'),
          actions: <Widget>[
            TextButton(
              child: const Text('නැවත උත්සාහ කරන්න'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });
                _checkInternetConnection();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    // Delay for 5 seconds to show the animation
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    try {
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
    } catch (e) {
      // Handle any errors that might occur during Supabase initialization
      print('Error during auth check: $e');
      if (mounted) {
        setState(() {
          _hasInternetConnection = false;
          _isLoading = false;
        });
        _showNoInternetDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_hasInternetConnection)
                    Lottie.network(
                      "https://lottie.host/08fd21f4-4d0f-4ddd-a7a6-9434caa397b6/lykm1jOaUY.json",
                      fit: BoxFit.cover,
                      width: 300,
                      height: 250,
                      errorBuilder: (context, error, stackTrace) {
                        // Handle Lottie loading errors
                        return const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  CircularProgressIndicator(color: Colors.green[700]),
                ],
              )
            : !_hasInternetConnection
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                          });
                          _checkInternetConnection();
                        },
                        child: const Text('නැවත උත්සාහ කරන්න'),
                      ),
                    ],
                  )
                : const SizedBox(),
      ),
    );
  }
}
