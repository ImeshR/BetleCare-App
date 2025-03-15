import 'package:betlecare/pages/market/market_demand.dart';
import 'package:betlecare/pages/market/market_volatility.dart';
import 'package:betlecare/pages/market/price_forecast.dart';
import 'package:betlecare/pages/market/profitable_market.dart';
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/profile_header.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              title: 'ලභදායී වෙළඳපොල',
              color: Colors.green.shade100,
              imagePath: 'assets/images/market/store.png',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: ProfitableMarketScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'මිල පුරෝකථනය',
              color: Colors.orange.shade100,
              imagePath: 'assets/images/market/price.png',
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: PriceForecastScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'වෙළදපොළ විචලනය',
              color: Colors.blue.shade100,
              imagePath: 'assets/images/market/market.png',
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: MarketVolatilityScreen()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'අධික අවශ්‍යතාව කාල සීමා',
              color: Colors.green.shade200,
              imagePath: 'assets/images/market/demand.png',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade200,
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChildPageWrapper(child: MarketDemandScreen()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Color color,
    required String imagePath,
    required Gradient gradient,
    required Function()? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChildPageWrapper extends StatelessWidget {
  final Widget child;

  const ChildPageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ProfileHeader(),
          Expanded(child: child),
        ],
      ),
     bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onTabChange: (index) {
          if (index != 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();

              Navigator.of(context)
                  .pushReplacementNamed('/main', arguments: index);
            });
          }
        },
      ),
    );
  }
}
