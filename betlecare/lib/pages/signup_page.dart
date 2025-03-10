import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../styles/auth_styles.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = await SupabaseClientManager.instance;
      final AuthResponse res = await supabase.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
        },
      );

      if (res.user != null) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful. Please log in.')),
        );
      } else {
        throw Exception('Signup failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
      backgroundColor: AuthStyles.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          // Center widget added
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'ලියාපදිංචි වන්න',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AuthStyles.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _firstNameController,
                decoration: AuthStyles.inputDecoration('මුල් නම'),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: AuthStyles.inputDecoration('අවසන් නම'),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
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
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration:
                    AuthStyles.inputDecoration('මුරපදය තහවුරු කරන්න').copyWith(
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ලියාපදිංචි වන්න'),
                style: AuthStyles.elevatedButtonStyle,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'දැන් ලියාපදිංචි වී ඇත්ද? පිවිසීම',
                  style: AuthStyles.linkTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
