import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/appbar/app_bar.dart';

class LandDetailsScreen extends StatefulWidget {
  const LandDetailsScreen({Key? key}) : super(key: key);

  @override
  _LandDetailsScreenState createState() => _LandDetailsScreenState();
}

class _LandDetailsScreenState extends State<LandDetailsScreen> {
  List<Map<String, dynamic>> _lands = [];
  List<Map<String, dynamic>> _filteredLands = [];
  bool _isLoading = true;
  late SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _initializeSupabaseService();
  }

  Future<void> _initializeSupabaseService() async {
    _supabaseService = await SupabaseService.init();
    _fetchLands();
  }

  Future<void> _fetchLands() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await _supabaseService.read('land_size',
          column: 'user_id', value: userId);

      setState(() {
        _lands = response;
        _filteredLands = _lands;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching lands: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterLands(String query) {
    setState(() {
      _filteredLands = _lands
          .where((land) =>
              land['name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              land['location']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showLandDetails(BuildContext context, Map<String, dynamic> land) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(land['name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ස්ථානය: ${land['location']}'),
              Text('ප්‍රමාණය: ${land['area'].toStringAsFixed(2)} අක්කර'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('වසන්න'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('මකන්න', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteLand(land);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLand(Map<String, dynamic> land) async {
    try {
      await _supabaseService.delete('land_size', 'id', land['id']);

      setState(() {
        _lands.remove(land);
        _filteredLands = List.from(_lands);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${land['name']} ඉවත් කරන ලදී')),
      );
    } catch (e) {
      print('Error deleting land: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete land: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: BasicAppbar(title: 'ඉඩම් විස්තර'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: _filterLands,
                    decoration: InputDecoration(
                      labelText: 'සොයන්න',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredLands.length,
                    itemBuilder: (context, index) {
                      final land = _filteredLands[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.landscape, color: Colors.white),
                          ),
                          title: Text(land['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${land['location']} | ${land['area'].toStringAsFixed(2)} අක්කර' ??
                                  ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => _showLandDetails(context, land),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
