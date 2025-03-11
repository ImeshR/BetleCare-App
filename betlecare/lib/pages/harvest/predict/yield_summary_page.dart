import 'package:flutter/material.dart';

class YieldSummaryPage extends StatelessWidget {
  const YieldSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('අස්වැන්න පිළිබඳ සාරාංශය'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "අවසන් අස්වැන්න විස්තරය:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("දින: 2025-03-10"),
                    Text("මුළු අස්වැන්න: 1200 kg"),
                    Text("සාමාන්‍ය opbreng: 80 kg per acre"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "ගිය මාසය සඳහා:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("උත්පාදිත වගා ප්‍රමාණය: 900 kg"),
                    Text("අපේක්ෂිත වගාව: 1000 kg"),
                    Text("වෙනස: -10%"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
