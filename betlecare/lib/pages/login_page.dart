import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../supabase_client.dart';
import '../styles/auth_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final supabase = await SupabaseClientManager.instance;
      final response = await supabase.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        await _handleSuccessfulSignIn(response.user);
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    const clientId =
        '973570141465-qnd5vbsrnr98aca90lru6gsimbg21ngb.apps.googleusercontent.com';
    const webClientId =
        '973570141465-0f8s4rehfv4lvtgpit6ebop0m98unlvq.apps.googleusercontent.com';
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: webClientId,
    );

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In aborted';
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        throw 'Google authentication failed. No access token or ID token found.';
      }

      final supabase = await SupabaseClientManager.instance;
      final response = await supabase.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        await _handleSuccessfulSignIn(response.user);
      } else {
        setState(() {
          _errorMessage = 'Google sign-in failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An error occurred during Google sign-in: ${e.toString()}';
      });
      print('Error during Google sign-in: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSuccessfulSignIn(User? user) async {
    if (user == null) {
      setState(() {
        _errorMessage = 'Login failed. User information is missing.';
      });
      return;
    }

    final supabase = await SupabaseClientManager.instance;

    // Set user in UserProvider
    Provider.of<UserProvider>(context, listen: false).setUser(user);

    try {
      // Fetch additional user data
      final userData = await supabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      Provider.of<UserProvider>(context, listen: false).setUserData(userData);
    } catch (e) {
      print('Error fetching user data: $e');
      // If fetching user data fails, we still want to proceed with login
      // You might want to handle this error differently based on your app's requirements
    }

    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthStyles.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Text(
              'ඇතුල් වන්න',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AuthStyles.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: AuthStyles.inputDecoration('Email ලිපිනය'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: AuthStyles.inputDecoration('මුරපදය').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AuthStyles.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _signInWithEmail,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ගිණුමට පිවිසීම'),
              style: AuthStyles.elevatedButtonStyle,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _nativeGoogleSignIn,
              icon: Image.asset('assets/images/google_logo.png', height: 24),
              label: const Text('Sign In with Google'),
              style: AuthStyles.elevatedButtonStyle.copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                foregroundColor: MaterialStateProperty.all(Colors.black87),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/signup'),
              child: Text(
                'ගිණුමක් නොමැතිද? ලියාපදිංචි වන්න',
                style: AuthStyles.linkTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
