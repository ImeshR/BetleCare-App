import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/bottom_nav_bar.dart';

class TreatmentSchedulingPage extends StatefulWidget {
  const TreatmentSchedulingPage({super.key});

  @override
  State<TreatmentSchedulingPage> createState() =>
      _TreatmentSchedulingPageState();
}

class _TreatmentSchedulingPageState extends State<TreatmentSchedulingPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _treatmentPlans = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Controllers for the form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadTreatmentPlans();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTreatmentPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch treatment plans from the database
      final response = await _supabase
          .from('treatment_schedules')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: true)
          .order('time', ascending: true);

      setState(() {
        _treatmentPlans = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading treatment plans: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDateTimePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );

      if (pickedTime != null) {
        setState(() {
          _selectedTime = pickedTime;
        });
      }
    }
  }

  // Change the _addTreatmentPlan method to match the exact database structure
  Future<void> _addTreatmentPlan() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර ප්‍රතිකාර විස්තරය ඇතුළත් කරන්න')),
      );
      return;
    }

    final DateTime scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර අනාගත දිනයක් සහ වේලාවක් තෝරන්න')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Add treatment plan to the database - match exact table structure
      await _supabase.from('treatment_schedules').insert({
        'user_id': user.id,
        'description': _descriptionController.text,
        'date': _selectedDate
            .toIso8601String()
            .split('T')[0], // Format as YYYY-MM-DD
        'time': scheduledDateTime.toIso8601String(), // Full ISO timestamp
      });

      // Refresh the list
      await _loadTreatmentPlans();

      setState(() {
        _isSubmitting = false;
        _titleController.clear();
        _descriptionController.clear();
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ප්‍රතිකාර සැලසුම සාර්ථකව එකතු කරන ලදී')),
      );

      Navigator.pop(context); // Close the add treatment dialog
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding treatment plan: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleTreatmentCompletion(String id, bool currentStatus) async {
    try {
      // Update the treatment plan in the database
      await _supabase.from('treatment_schedules').update({
        'is_completed': !currentStatus,
      }).eq('id', id);

      // Refresh the list
      await _loadTreatmentPlans();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(currentStatus
                ? 'ප්‍රතිකාර සැලසුම අසම්පූර්ණ ලෙස සලකුණු කරන ලදී'
                : 'ප්‍රතිකාර සැලසුම සම්පූර්ණ ලෙස සලකුණු කරන ලදී')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating treatment plan: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTreatmentPlan(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ප්‍රතිකාර සැලසුම මකන්න'),
        content:
            const Text('ඔබට මෙම ප්‍රතිකාර සැලසුම මැකීමට අවශ්‍ය බව විශ්වාසද?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Delete the treatment plan from the database
                await _supabase
                    .from('treatment_schedules')
                    .delete()
                    .eq('id', id);

                // Refresh the list
                await _loadTreatmentPlans();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ප්‍රතිකාර සැලසුම සාර්ථකව මකා දමන ලදී')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error deleting treatment plan: ${e.toString()}')),
                );
              }
            },
            child: const Text('මකන්න'),
          ),
        ],
      ),
    );
  }

  // Update the dialog to focus on description only
  void _showAddTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('නව ප්‍රතිකාර සැලසුමක් එකතු කරන්න'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'ප්‍රතිකාර විස්තරය',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('දිනය සහ වේලාව තෝරන්න'),
                subtitle: Text(
                  '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} - ${_selectedTime.format(context)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _showDateTimePicker,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _addTreatmentPlan,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('එකතු කරන්න'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ප්‍රතිකාර සැලසුම්'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTreatmentDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_treatmentPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'තවම ප්‍රතිකාර සැලසුම් නැත',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddTreatmentDialog,
              icon: const Icon(Icons.add),
              label: const Text('නව ප්‍රතිකාර සැලසුමක් එකතු කරන්න'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ඔබගේ ප්‍රතිකාර සැලසුම්',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ඔබගේ ශාක රෝග සඳහා ප්‍රතිකාර සැලසුම් කළමනාකරණය කරන්න',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _treatmentPlans.length,
              itemBuilder: (context, index) {
                final plan = _treatmentPlans[index];
                return _buildTreatmentCard(plan);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildTreatmentCard method to match the database structure
  Widget _buildTreatmentCard(Map<String, dynamic> plan) {
    final String id = plan['id'];
    final String description = plan['description'] ?? '';
    final bool isCompleted = plan['is_completed'] ?? false;

    // Parse date and time
    DateTime date;
    try {
      // Try to parse the time field
      if (plan['time'] != null) {
        date = DateTime.parse(plan['time'].toString());
      }
      // If time is null, try to parse the date field
      else if (plan['date'] != null) {
        final dateStr = plan['date'].toString();
        // If date is just a date (YYYY-MM-DD), append time
        if (dateStr.length <= 10) {
          date = DateTime.parse("${dateStr}T00:00:00");
        } else {
          date = DateTime.parse(dateStr);
        }
      }
      // Fallback if both are null
      else {
        date = DateTime.now();
      }
    } catch (e) {
      // Fallback if parsing fails
      date = DateTime.now();
      print('Error parsing date: ${e.toString()}');
    }

    final bool isUpcoming = date.isAfter(DateTime.now());
    final bool isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    Color cardColor = Colors.blue.shade100;
    List<Color> gradientColors = [Colors.blue.shade50, Colors.blue.shade100];

    if (isCompleted) {
      cardColor = Colors.green.shade100;
      gradientColors = [Colors.green.shade50, Colors.green.shade100];
    } else if (isToday) {
      cardColor = Colors.amber.shade100;
      gradientColors = [Colors.amber.shade50, Colors.amber.shade100];
    } else if (!isUpcoming) {
      cardColor = Colors.red.shade100;
      gradientColors = [Colors.red.shade50, Colors.red.shade100];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleTreatmentCompletion(id, isCompleted),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ප්‍රතිකාර සැලසුම', // Default title since there's no title field
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTreatmentPlan(id),
                      color: Colors.grey[700],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy/MM/dd').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(isCompleted, isToday, isUpcoming),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(isCompleted, isToday, isUpcoming),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isCompleted, bool isToday, bool isUpcoming) {
    if (isCompleted) {
      return Colors.green;
    }

    if (isToday) {
      return Colors.orange;
    } else if (isUpcoming) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(bool isCompleted, bool isToday, bool isUpcoming) {
    if (isCompleted) {
      return 'සම්පූර්ණයි';
    }

    if (isToday) {
      return 'අද';
    } else if (isUpcoming) {
      return 'අනාගත';
    } else {
      return 'පසුගිය';
    }
  }
}
