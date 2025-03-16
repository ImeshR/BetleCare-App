import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../providers/user_provider.dart';
import '../../styles/auth_styles.dart';
import '../../supabase_client.dart';

class StripePaymentPage extends StatefulWidget {
  const StripePaymentPage({Key? key}) : super(key: key);

  @override
  _StripePaymentPageState createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  bool _isProcessing = false;
  bool _isPaymentSuccess = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // Validate input fields
    if (_cardNumberController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _cardHolderNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'සියලුම ක්ෂේත්‍ර පිරවිය යුතුය';
      });
      return;
    }

    // Simple validation for card number (16 digits)
    if (_cardNumberController.text.replaceAll(' ', '').length != 16 ||
        !RegExp(r'^[0-9 ]+$').hasMatch(_cardNumberController.text)) {
      setState(() {
        _errorMessage = 'වලංගු කාඩ්පත් අංකයක් ඇතුළත් කරන්න';
      });
      return;
    }

    // Simple validation for expiry date (MM/YY format)
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$')
        .hasMatch(_expiryDateController.text)) {
      setState(() {
        _errorMessage = 'කල් ඉකුත්වීමේ දිනය MM/YY ආකෘතියෙන් ඇතුළත් කරන්න';
      });
      return;
    }

    // Simple validation for CVV (3 or 4 digits)
    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(_cvvController.text)) {
      setState(() {
        _errorMessage = 'වලංගු CVV අංකයක් ඇතුළත් කරන්න';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // This is a simulation - in a real app, you would integrate with Stripe SDK
      // For simulation purposes, we'll consider the payment successful

      // Update payment status in Supabase
      final supabase = await SupabaseClientManager.instance;
      final user = supabase.client.auth.currentUser;

      if (user != null) {
        // Update the user_settings table with the new payment status
        final timestamp = DateTime.now().toIso8601String();

        await supabase.client.from('user_settings').update({
          'payment_status': true,
          'new_user': false,
          'updated_at': timestamp
        }).eq('userid', user.id);

        // Log the payment in a payments table if you have one
        // This is optional but recommended for tracking payment history
        try {
          await supabase.client.from('payments').insert({
            'userid': user.id,
            'amount': 1500,
            'currency': 'LKR',
            'payment_method': 'card',
            'status': 'completed',
            'created_at': timestamp
          });
        } catch (e) {
          // If payments table doesn't exist, just continue
          print('Error logging payment: ${e.toString()}');
        }

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserSettings();

        setState(() {
          _isPaymentSuccess = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Payment error: ${e.toString()}');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'ගෙවීම් සැකසීමේ දෝෂයක්: ${e.toString()}';
      });
    }
  }

  void _formatCardNumber(String value) {
    // Format card number with spaces after every 4 digits
    String newValue = value.replaceAll(' ', '');
    String formattedValue = '';

    for (int i = 0; i < newValue.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formattedValue += ' ';
      }
      formattedValue += newValue[i];
    }

    _cardNumberController.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  void _formatExpiryDate(String value) {
    // Format expiry date as MM/YY
    String newValue = value.replaceAll('/', '');
    String formattedValue = newValue;

    if (newValue.length > 2) {
      formattedValue = '${newValue.substring(0, 2)}/${newValue.substring(2)}';
    }

    _expiryDateController.value = TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ගෙවීම් පිටුව'),
        backgroundColor: Colors.transparent,
      ),
      body: _isPaymentSuccess ? _buildSuccessView() : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentHeader(),
          SizedBox(height: 24),
          _buildCardDetailsForm(),
          if (_errorMessage.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24),
          _buildPaymentButton(),
          SizedBox(height: 16),
          _buildSecurePaymentInfo(),
        ],
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ගෙවීම් විස්තර',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'සියලුම විශේෂාංග අගුලු හැරීමට ඔබගේ දායකත්වය සක්‍රීය කරන්න',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'දායකත්ව ගාස්තුව: රු. 1,500.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'වාර්ෂික දායකත්වය - සියලුම විශේෂාංග වෙත ප්‍රවේශය',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetailsForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'කාඩ්පත් තොරතුරු',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/2560px-Visa_Inc._logo.svg.png',
                      height: 20,
                    ),
                    SizedBox(width: 8),
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1280px-Mastercard-logo.svg.png',
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cardHolderNameController,
              decoration: AuthStyles.inputDecoration('කාඩ්පත් හිමියාගේ නම'),
              keyboardType: TextInputType.name,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cardNumberController,
              decoration: AuthStyles.inputDecoration('කාඩ්පත් අංකය').copyWith(
                hintText: 'XXXX XXXX XXXX XXXX',
              ),
              keyboardType: TextInputType.number,
              maxLength: 19, // 16 digits + 3 spaces
              onChanged: _formatCardNumber,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryDateController,
                    decoration: AuthStyles.inputDecoration('කල් ඉකුත්වීමේ දිනය')
                        .copyWith(
                      hintText: 'MM/YY',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5, // MM/YY format
                    onChanged: _formatExpiryDate,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: AuthStyles.inputDecoration('CVV').copyWith(
                      hintText: 'XXX',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        child: _isProcessing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'රු. 1,500.00 ගෙවන්න',
                style: TextStyle(fontSize: 16),
              ),
        style: AuthStyles.elevatedButtonStyle,
      ),
    );
  }

  Widget _buildSecurePaymentInfo() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            'ආරක්ෂිත ගෙවීම් ක්‍රියාවලිය',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'ගෙවීම සාර්ථකයි!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'ඔබගේ රු. 1,500.00 ගෙවීම සාර්ථකව සැකසී ඇත. ඔබගේ ගිණුම දැන් සක්‍රීය කර ඇත.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'සැකසුම් වෙත ආපසු යන්න',
                  style: TextStyle(fontSize: 16),
                ),
                style: AuthStyles.elevatedButtonStyle,
              ),
            ),
            SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Navigate to receipt or invoice page
              },
              icon: Icon(Icons.receipt_long),
              label: Text('රිසිට්පත බලන්න'),
            ),
          ],
        ),
      ),
    );
  }
}
