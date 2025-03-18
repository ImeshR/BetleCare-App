import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({Key? key}) : super(key: key);

  @override
  _TipsScreenState createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Launch URLs for contact
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('උපදෙස් සහ ඉඟි',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'ආරම්භකයින්'), // Beginners
            Tab(text: 'උසස්'), // Advanced
            Tab(text: 'අප ගැන'), // About Us
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Beginners Tab
          _buildBeginnersTab(),

          // Advanced Tab
          _buildAdvancedTab(),

          // About Us Tab
          _buildAboutUsTab(),
        ],
      ),
    );
  }

  Widget _buildBeginnersTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(
              title: 'නිවැරදි බුලත් වර්ගය තෝරා ගැනීම',
              content: '''
• ශ්‍රී ලංකාවේ "රතබුලත්" (රතු බුලත්) සහ "කලිය බුලත්" යන වර්ග බහුලව දැකිය හැකිය.
• රතබුලත්: මෙම වර්ගය ලා රතු පැහැයක් හා ශක්තිමත් සුවඳක් සහිත වන අතර පාරම්පරික සපයට වඩාත් ජනප්‍රිය වේ.
• කලිය බුලත්: විශාල, කොළ පැහැති කොළ සහිත වන අතර, සමහර වෙළඳපොළවල් හෝ භාවිතයන් සඳහා වඩාත් සුදුසු විය හැකිය.
• තෝරා ගැනීමේදී වෙළඳපොළ ඉල්ලුම, ප්‍රදේශයේ දේශගුණය සහ පුද්ගලික මනාපය සලකා බලන්න.''',
              icon: Icons.eco,
              color: Colors.green.shade700,
            ),
            _buildTipCard(
              title: 'භූමිය තෝරා ගැනීම',
              content: '''
• බුලත් වැල් හොඳින් ජලය බැස යන, සාරවත් පසෙහි වැඩේ. ජලය තැන්පත් වීම මුල් කුණු වීමට හේතු විය හැකිය.
• අර්ධ සෙවණ අත්‍යවශ්‍ය වේ. සෘජු හිරු එළිය කොළ දැවිය හැකිය.
• වල් පැළෑටි ඉවත් කර පස ලිහිල් කිරීමෙන් ඉඩම සකස් කරන්න. පොහොර හෝ හොඳින් දිරාපත් වූ සත්ව පොහොර එකතු කිරීම පසෙහි සාරවත්භාවය වැඩි දියුණු කරයි.''',
              icon: Icons.landscape,
              color: Colors.brown.shade700,
            ),
            _buildTipCard(
              title: 'රෝපණ ක්‍රම',
              content: '''
• වැඩුණු වැල් වලින් සෞඛ්‍ය සම්පන්න කැබලි (දණ්ඩ) භාවිතා කරන්න. කැබැල්ලේ කිහිපයක් ගැට (Nodes) තිබිය යුතුය.
• ගැට පසෙහි වැළලෙන පරිදි ටිකක් ඇල කර සිටුවන්න.
• පැළ අතර පරතරය බුලත් වර්ගය සහ සහාය පද්ධතිය මත රඳා පවතී, නමුත් සාමාන්‍යයෙන්, වැල් වැඩීමට ප්‍රමාණවත් ඉඩක් ලබා දෙන්න.
• වැල් නැගීමට ශක්තිමත් සහාරක (උදා: පැල්ලම්, වැට) සාදන්න.''',
              icon: Icons.agriculture,
              color: Colors.orange.shade800,
            ),
            _buildTipCard(
              title: 'මූලික රැකවරණය',
              content: '''
• විශේෂයෙන් වියළි කාලවලදී නිතිපතා වතුර දමන්න. අධික ලෙස වතුර දැමීමෙන් වළකින්න.
• පෝෂක සහ ජලය සඳහා තරඟය වැළැක්වීමට නිතිපතා වල් පැළෑටි ඉවත් කරන්න.
• හැකි විට ස්වාභාවික පළිබෝධනාශක ක්‍රම (උදා: කොහොඹ තෙල්) භාවිතා කරන්න.
• සෙවන දැල් හෝ උස් ශාක සමඟ මිශ්‍ර වගා කිරීමෙන් සෙවන සපයන්න.''',
              icon: Icons.water_drop,
              color: Colors.blue.shade700,
            ),
            _buildTipCard(
              title: 'වර්ධන චක්‍රය තේරුම් ගැනීම',
              content: '''
• බුලත් වැල් ඔප්ටිමල් තත්ත්වයන් යටතේ ඉක්මනින් වැඩේ.
• පළමු අස්වැන්න සාමාන්‍යයෙන් මාස 3-6 ක් අතර කාලයක් තුළ ලැබේ.
• නිසි රැකවරණය සමඟ වසර කිහිපයක් අඛණ්ඩව අස්වැන්න නෙලිය හැකිය.''',
              icon: Icons.autorenew,
              color: Colors.purple.shade700,
            ),
            _buildTipCard(
              title: 'මූල්‍ය ඉඟි',
              content: '''
• කැබලි, සහායක, පොහොර සහ ශ්‍රමය සඳහා වියදම් ගණනය කරන්න.
• විය හැකි ආදායම ඇස්තමේන්තු කිරීමට වෙළඳපොළ මිල ගණන් පර්යේෂණය කරන්න.
• සහනාධාර හෝ සහාය පිරිනමන රජයේ කෘෂිකාර්මික වැඩසටහන් ගැන විමසන්න.''',
              icon: Icons.attach_money,
              color: Colors.green.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(
              title: 'සමාකලිත පළිබෝධ කළමනාකරණය (IPM)',
              content: '''
• IPM වැළැක්වීම මත අවධාරණය කරන අතර පළිබෝධනාශක අවසාන විකල්පය ලෙස භාවිතා කරයි.
• පළිබෝධ සහ රෝග සඳහා නියමිත වේලාවට පැළ පරීක්ෂා කරන්න.
• ජෛවික පාලනය (උදා: ප්‍රයෝජනවත් කෘමීන්) සහ සංස්කෘතික භාවිතයන් (උදා: බෝග මාරු කිරීම) භාවිතා කරන්න.''',
              icon: Icons.bug_report,
              color: Colors.orange.shade700,
            ),
            _buildTipCard(
              title: 'පස කළමනාකරණය',
              content: '''
• පස් පරීක්ෂාව පෝෂක ඌනතා සහ pH මට්ටම් තීරණය කිරීමට උපකාරී වේ.
• පසෙහි සෞඛ්‍යය වැඩි දියුණු කිරීමට කාබනික පොහොර (උදා: කොම්පෝස්ට්, පණු පොහොර) භාවිතා කරන්න.
• පසෙහි pH අගය 6.0 සහ 7.5 අතර පවත්වා ගන්න.''',
              icon: Icons.foundation,
              color: Colors.brown.shade800,
            ),
            _buildTipCard(
              title: 'වාරි තාක්ෂණය',
              content: '''
• බිංදු ජල සම්පාදනය කෙලින්ම මුල් වලට ජලය බෙදා හරින අතර, ජල නාස්තිය අවම කරයි.
• වර්ෂාපතනය නිරීක්ෂණය කිරීමට සහ ඒ අනුව වාරිමාර්ග සැකසීමට වර්ෂාමානයක් භාවිතා කිරීම සලකා බලන්න.''',
              icon: Icons.water,
              color: Colors.blue.shade800,
            ),
            _buildTipCard(
              title: 'වැල් පුහුණුව සහ කප්පාදුව',
              content: '''
• හිරු එළිය උපරිම කිරීමට සහාරක දිගේ සිරස් අතට වැඩීමට වැල් පුහුණු කරන්න.
• විශාල කොළ වැඩීම දිරිමත් කිරීමට පැති අතු කප්පාදු කරන්න.
• කප්පාදුව වාතාශ්‍රය සඳහාද උපකාරී වන අතර, දිලීර ආසාදන අවදානම අඩු කරයි.''',
              icon: Icons.content_cut,
              color: Colors.pink.shade800,
            ),
            _buildTipCard(
              title: 'අස්වනු නෙලීම සහ පසු-අස්වනු හැසිරවීම',
              content: '''
• පරිණත නමුත් තවමත් මෘදු විට කොළ අස්වනු නෙළන්න.
• තැලීම් හෝ හානි වළක්වා ගැනීමට කොළ ප්‍රවේශමෙන් හසුරුවන්න.
• ඇසුරුම් කිරීමට පෙර කොළ පිරිසිදු කර වර්ග කරන්න.
• ආයු කාලය දීර්ඝ කිරීමට සිසිල්, තෙත තත්ත්ව යටතේ කොළ ගබඩා කරන්න.''',
              icon: Icons.local_shipping,
              color: Colors.green.shade900,
            ),
            _buildTipCard(
              title: 'වෙළඳපොල තොරතුරු',
              content: '''
• කෘෂිකාර්මික ව්‍යාප්ති සේවා හෝ සබැඳි වේදිකා හරහා වෙළඳපොළ මිල ගණන් සහ ඉල්ලුම පිළිබඳ යාවත්කාලීනව සිටින්න.
• පාරිභෝගිකයින්ට හෝ අවන්හල් වලට සෘජු අලෙවිකරණය සඳහා අවස්ථා ගවේෂණය කරන්න.
• අපනයන අවස්ථා සහ අදාළ රෙගුලාසි පිළිබඳව සොයා බලන්න.''',
              icon: Icons.store,
              color: Colors.blue.shade900,
            ),
            _buildTipCard(
              title: 'අගය එකතු කිරීම',
              content: '''
• බුලත් කොළ තෙල් හෝ උඩුගම් වැනි නිෂ්පාදන බවට බුලත් කොළ සැකසීමේ අවස්ථා ගවේෂණය කරන්න.
• සාම්ප්‍රදායික වෛද්‍ය වේදය හෝ ප්‍රසාධන ද්‍රව්‍ය වල බුලත් කොළ භාවිතය ගැන සොයා බලන්න.
• නවීන ඖෂධ වල බුලත් කොළ භාවිතය පිළිබඳ පර්යේෂණය කරන්න.''',
              icon: Icons.add_circle,
              color: Colors.purple.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutUsTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Description Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/betel_leaf.png',
                      height: 120,
                      width: 120,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    ' Betel Care',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ශ්‍රී ලංකාවේ බුලත් ගොවීන් සඳහා සම්පූර්ණ කළමනාකරණ මෘදුකාංගය',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'බුලත් කෙයා යනු ශ්‍රී ලංකාවේ පුත්තලම, අනමඩුව සහ කුරුණෑගල යන දිස්ත්‍රික්කවල බුලත් ගොවීන් සඳහා නිර්මාණය කළ විශේෂිත මෙවලමකි. අපගේ වැඩසටහන මුලින්ම මෙම ප්‍රදේශ ඉලක්ක කරගෙන ඇති අතර, බුලත් වගාව ජනප්‍රිය ය.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Features Section
            Text(
              'අපගේ විශේෂාංග',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.camera_alt,
              title: 'රෝග හඳුනා ගැනීම සහ නිර්දේශ පද්ධතිය',
              description:
                  'රූප විශ්ලේෂණය මගින් රෝග හඳුනාගෙන, ප්‍රතිකාර යෝජනා ලබා දෙයි',
            ),

            _buildFeatureCard(
              icon: Icons.map,
              title: 'අස්වනු පුරෝකථනය සහ ඉඩම් මැනීම',
              description:
                  'GPS පදනම් කරගත් භූමි මැනීම් සහ අස්වනු පුරෝකථනය (වෘත්තීය පරිශීලකයින් සඳහා)',
            ),

            _buildFeatureCard(
              icon: Icons.place,
              title: 'වෙළඳපොළ පුරෝකථනය',
              description: 'හොඳම වෙළඳපොළ ස්ථානය සහ මිල පුරෝකථනය කරයි',
            ),

            _buildFeatureCard(
              icon: Icons.wb_sunny,
              title: 'කාලගුණ පදනම් කරගත් නිර්දේශ',
              description: 'පොහොර, ජල සම්පාදනය සහ ආරක්ෂක ක්‍රම සඳහා හොඳම දින',
            ),

            SizedBox(height: 24),

            // Contact Us Section
            Text(
              'අප හා සම්බන්ධ වන්න',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),

            // Contact cards
            InkWell(
              onTap: () => _launchUrl('tel:+94712345678'),
              child: _buildContactCard(
                icon: Icons.phone,
                title: 'දුරකථන අංකය',
                info: '+94 71 234 5678',
                color: Colors.blue,
              ),
            ),

            InkWell(
              onTap: () => _launchUrl('mailto:info@betlecare.lk'),
              child: _buildContactCard(
                icon: Icons.email,
                title: 'ඊමේල්',
                info: 'info@betlecare.lk',
                color: Colors.red,
              ),
            ),

            InkWell(
              onTap: () => _launchUrl('https://www.facebook.com/betlecare'),
              child: _buildContactCard(
                icon: Icons.facebook,
                title: 'ෆේස්බුක්',
                info: 'facebook.com/betlecare',
                color: Colors.indigo,
              ),
            ),

            InkWell(
              onTap: () => _launchUrl('https://www.youtube.com/betlecare'),
              child: _buildContactCard(
                icon: Icons.video_library,
                title: 'යූටියුබ් චැනලය',
                info: 'youtube.com/betlecare',
                color: Colors.red,
              ),
            ),

            SizedBox(height: 24),

            // Team info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'බුලත් කෙයා කණ්ඩායම',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'අපි ශ්‍රී ලංකාවේ බුලත් ගොවීන්ට සහය වීමට කැපවී සිටින තාක්ෂණික හා කෘෂිකාර්මික විශේෂඥයින්ගේ කණ්ඩායමක්. අපගේ පරමාර්ථය වන්නේ තාක්ෂණය හරහා බුලත් වගාව වඩාත් ලාභදායී, තිරසාර හා කළමනාකරණය කළ හැකි කරවීමයි.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '© 2025 බුලත් කෙයා අයිතිය ඇතුව',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        childrenPadding: EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String info,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            info,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
