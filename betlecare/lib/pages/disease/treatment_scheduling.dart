import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/bottom_nav_bar.dart';

class TreatmentSchedulingPage extends StatefulWidget {
  const TreatmentSchedulingPage({super.key});

  @override
  State<TreatmentSchedulingPage> createState() =>
      _TreatmentSchedulingPageState();
}

class _TreatmentSchedulingPageState extends State<TreatmentSchedulingPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _treatmentSchedules = [];
  Map<String, List<Map<String, dynamic>>> _treatmentDetails = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedScheduleId;

  // Controllers for the schedule form
  final TextEditingController _scheduleDescriptionController =
      TextEditingController();
  DateTime _selectedScheduleDate = DateTime.now();
  TimeOfDay _selectedScheduleTime = TimeOfDay.now();

  // Controllers for the treatment detail form
  final TextEditingController _treatmentTitleController =
      TextEditingController();
  DateTime _selectedTreatmentDate = DateTime.now();
  TimeOfDay _selectedTreatmentTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadTreatmentSchedules();
    _checkDueTreatments();
  }

  @override
  void dispose() {
    _scheduleDescriptionController.dispose();
    _treatmentTitleController.dispose();
    super.dispose();
  }

  // Show a notification when a treatment is due
  void _showTreatmentNotification(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ප්‍රතිකාර සිහි කැඳවීම: $message',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'හරි',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Store a treatment in SharedPreferences
  Future<void> _storeTreatment(
      String id, String title, DateTime scheduledTime) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing treatments
    final List<String> treatments =
        prefs.getStringList('scheduled_treatments') ?? [];

    // Add the new treatment
    treatments.add('$id|$title|${scheduledTime.toIso8601String()}');

    // Save back to SharedPreferences
    await prefs.setStringList('scheduled_treatments', treatments);

    print('Treatment stored: $id at $scheduledTime');
  }

  // Remove a treatment from SharedPreferences
  Future<void> _removeTreatment(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing treatments
    final List<String> treatments =
        prefs.getStringList('scheduled_treatments') ?? [];

    // Filter out the treatment with the given ID
    final List<String> updatedTreatments = treatments.where((treatment) {
      final parts = treatment.split('|');
      return parts.length >= 3 && parts[0] != id;
    }).toList();

    // Save back to SharedPreferences
    await prefs.setStringList('scheduled_treatments', updatedTreatments);

    print('Treatment removed: $id');
  }

  // Check for due treatments
  Future<void> _checkDueTreatments() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get stored treatments
    final List<String> treatments =
        prefs.getStringList('scheduled_treatments') ?? [];

    // Check for treatments that are due
    for (final treatment in treatments) {
      final parts = treatment.split('|');
      if (parts.length >= 3) {
        final String id = parts[0];
        final String title = parts[1];
        final DateTime scheduledTime = DateTime.parse(parts[2]);

        // Check if the treatment is due today
        final treatmentDay = DateTime(
            scheduledTime.year, scheduledTime.month, scheduledTime.day);

        if (treatmentDay.isAtSameMomentAs(today)) {
          // If it's due today, show a notification
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showTreatmentNotification(title);
          });
        }
      }
    }
  }

  // Store all upcoming treatments
  Future<void> _storeAllTreatments() async {
    // Clear existing stored treatments
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('scheduled_treatments', []);

    // Store each upcoming treatment detail
    for (final scheduleId in _treatmentDetails.keys) {
      final details = _treatmentDetails[scheduleId] ?? [];

      // Get the schedule to check if it's completed
      final scheduleIndex =
          _treatmentSchedules.indexWhere((s) => s['id'] == scheduleId);
      if (scheduleIndex == -1) continue; // Skip if schedule not found

      final schedule = _treatmentSchedules[scheduleIndex];
      final bool isCompleted = schedule['is_completed'] ?? false;

      // Don't store treatments for completed schedules
      if (isCompleted) continue;

      for (final detail in details) {
        final String id = detail['id'];
        final String title = detail['title'] ?? '';

        // Parse date and time
        DateTime scheduledTime;
        try {
          if (detail['time'] != null) {
            scheduledTime = DateTime.parse(detail['time'].toString());
          } else if (detail['date'] != null) {
            final dateStr = detail['date'].toString();
            if (dateStr.length <= 10) {
              scheduledTime = DateTime.parse("${dateStr}T00:00:00");
            } else {
              scheduledTime = DateTime.parse(dateStr);
            }
          } else {
            continue; // Skip if no valid date/time
          }

          // Store the treatment
          await _storeTreatment(id, title, scheduledTime);
        } catch (e) {
          print('Error storing treatment: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _loadTreatmentSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch treatment schedules from the database
      final schedulesResponse = await _supabase
          .from('treatment_schedules')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: true)
          .order('time', ascending: true);

      final schedules = List<Map<String, dynamic>>.from(schedulesResponse);

      // Fetch treatment details for each schedule
      final Map<String, List<Map<String, dynamic>>> details = {};

      for (final schedule in schedules) {
        final String scheduleId = schedule['id'];

        final detailsResponse = await _supabase
            .from('treatment_details')
            .select()
            .eq('schedule_id', scheduleId)
            .order('date', ascending: true)
            .order('time', ascending: true);

        details[scheduleId] = List<Map<String, dynamic>>.from(detailsResponse);
      }

      setState(() {
        _treatmentSchedules = schedules;
        _treatmentDetails = details;
        _isLoading = false;
      });

      // Store all upcoming treatments
      await _storeAllTreatments();

      // Check for due treatments
      await _checkDueTreatments();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error loading treatment schedules: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDateTimePicker({
    required DateTime initialDate,
    required TimeOfDay initialTime,
    required Function(DateTime, TimeOfDay) onSelected,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        onSelected(pickedDate, pickedTime);
      }
    }
  }

  Future<void> _addTreatmentSchedule() async {
    if (_scheduleDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('කරුණාකර ප්‍රතිකාර සැලසුමේ නම ඇතුළත් කරන්න')),
      );
      return;
    }

    final DateTime scheduledDateTime = DateTime(
      _selectedScheduleDate.year,
      _selectedScheduleDate.month,
      _selectedScheduleDate.day,
      _selectedScheduleTime.hour,
      _selectedScheduleTime.minute,
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

      // Add treatment schedule to the database
      final response = await _supabase.from('treatment_schedules').insert({
        'user_id': user.id,
        'description': _scheduleDescriptionController.text,
        'date': _selectedScheduleDate
            .toIso8601String()
            .split('T')[0], // Format as YYYY-MM-DD
        'time': scheduledDateTime.toIso8601String(), // Full ISO timestamp
      }).select();

      // Refresh the list
      await _loadTreatmentSchedules();

      setState(() {
        _isSubmitting = false;
        _scheduleDescriptionController.clear();
        _selectedScheduleDate = DateTime.now();
        _selectedScheduleTime = TimeOfDay.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ප්‍රතිකාර සැලසුම සාර්ථකව එකතු කරන ලදී')),
      );

      Navigator.pop(context); // Close the add schedule dialog
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error adding treatment schedule: ${e.toString()}')),
      );
    }
  }

  Future<void> _addTreatmentDetail(String scheduleId) async {
    if (_treatmentTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර ප්‍රතිකාර නම ඇතුළත් කරන්න')),
      );
      return;
    }

    final DateTime scheduledDateTime = DateTime(
      _selectedTreatmentDate.year,
      _selectedTreatmentDate.month,
      _selectedTreatmentDate.day,
      _selectedTreatmentTime.hour,
      _selectedTreatmentTime.minute,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Add treatment detail to the database
      final response = await _supabase.from('treatment_details').insert({
        'schedule_id': scheduleId,
        'title': _treatmentTitleController.text,
        'date': _selectedTreatmentDate
            .toIso8601String()
            .split('T')[0], // Format as YYYY-MM-DD
        'time': scheduledDateTime.toIso8601String(), // Full ISO timestamp
      }).select();

      // Get the inserted record with its ID
      if (response.isNotEmpty) {
        final newDetail = response[0];
        final String id = newDetail['id'];

        // Store the treatment
        await _storeTreatment(
            id, _treatmentTitleController.text, scheduledDateTime);
      }

      // Refresh the list
      await _loadTreatmentSchedules();

      setState(() {
        _isSubmitting = false;
        _treatmentTitleController.clear();
        _selectedTreatmentDate = DateTime.now();
        _selectedTreatmentTime = TimeOfDay.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ප්‍රතිකාර විස්තරය සාර්ථකව එකතු කරන ලදී')),
      );

      Navigator.pop(context); // Close the add treatment dialog
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error adding treatment detail: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleScheduleCompletion(String id, bool currentStatus) async {
    try {
      // Update the treatment schedule in the database
      await _supabase.from('treatment_schedules').update({
        'is_completed': !currentStatus,
      }).eq('id', id);

      // If marked as completed, remove all treatments in this schedule
      if (!currentStatus) {
        final details = _treatmentDetails[id] ?? [];
        for (final detail in details) {
          await _removeTreatment(detail['id']);
        }
      } else {
        // If marked as incomplete, re-store all treatments in this schedule
        final details = _treatmentDetails[id] ?? [];
        for (final detail in details) {
          final String detailId = detail['id'];
          final String title = detail['title'] ?? '';

          DateTime scheduledTime;
          try {
            if (detail['time'] != null) {
              scheduledTime = DateTime.parse(detail['time'].toString());
            } else if (detail['date'] != null) {
              final dateStr = detail['date'].toString();
              if (dateStr.length <= 10) {
                scheduledTime = DateTime.parse("${dateStr}T00:00:00");
              } else {
                scheduledTime = DateTime.parse(dateStr);
              }
            } else {
              continue; // Skip if no valid date/time
            }

            // Only store if it's in the future
            if (scheduledTime.isAfter(DateTime.now())) {
              await _storeTreatment(detailId, title, scheduledTime);
            }
          } catch (e) {
            print('Error storing treatment: ${e.toString()}');
          }
        }
      }

      // Refresh the list
      await _loadTreatmentSchedules();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(currentStatus
                ? 'ප්‍රතිකාර සැලසුම අසම්පූර්ණ ලෙස සලකුණු කරන ලදී'
                : 'ප්‍රතිකාර සැලසුම සම්පූර්ණ ලෙස සලකුණු කරන ලදී')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error updating treatment schedule: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTreatmentSchedule(String id) async {
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
                // Remove all treatments in this schedule from storage
                final details = _treatmentDetails[id] ?? [];
                for (final detail in details) {
                  await _removeTreatment(detail['id']);
                }

                // Delete the treatment schedule from the database
                // This will cascade delete all treatment details
                await _supabase
                    .from('treatment_schedules')
                    .delete()
                    .eq('id', id);

                // Refresh the list
                await _loadTreatmentSchedules();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ප්‍රතිකාර සැලසුම සාර්ථකව මකා දමන ලදී')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error deleting treatment schedule: ${e.toString()}')),
                );
              }
            },
            child: const Text('මකන්න'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTreatmentDetail(
      String scheduleId, String detailId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ප්‍රතිකාර විස්තරය මකන්න'),
        content:
            const Text('ඔබට මෙම ප්‍රතිකාර විස්තරය මැකීමට අවශ්‍ය බව විශ්වාසද?'),
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
                // Remove the treatment from storage
                await _removeTreatment(detailId);

                // Delete the treatment detail from the database
                await _supabase
                    .from('treatment_details')
                    .delete()
                    .eq('id', detailId);

                // Refresh the list
                await _loadTreatmentSchedules();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ප්‍රතිකාර විස්තරය සාර්ථකව මකා දමන ලදී')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error deleting treatment detail: ${e.toString()}')),
                );
              }
            },
            child: const Text('මකන්න'),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
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
                controller: _scheduleDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'ප්‍රතිකාර සැලසුම් විස්තරය',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('දිනය සහ වේලාව තෝරන්න'),
                subtitle: Text(
                  '${_selectedScheduleDate.year}/${_selectedScheduleDate.month}/${_selectedScheduleDate.day} - ${_selectedScheduleTime.format(context)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _showDateTimePicker(
                  initialDate: _selectedScheduleDate,
                  initialTime: _selectedScheduleTime,
                  onSelected: (date, time) {
                    setState(() {
                      _selectedScheduleDate = date;
                      _selectedScheduleTime = time;
                    });
                  },
                ),
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
            onPressed: _isSubmitting ? null : _addTreatmentSchedule,
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

  void _showAddTreatmentDetailDialog(String scheduleId) {
    setState(() {
      _selectedScheduleId = scheduleId;
      _treatmentTitleController.clear();
      _selectedTreatmentDate = DateTime.now();
      _selectedTreatmentTime = TimeOfDay.now();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('නව ප්‍රතිකාර විස්තරයක් එකතු කරන්න'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _treatmentTitleController,
                decoration: const InputDecoration(
                  labelText: 'ප්‍රතිකාර නම',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('දිනය සහ වේලාව තෝරන්න'),
                subtitle: Text(
                  '${_selectedTreatmentDate.year}/${_selectedTreatmentDate.month}/${_selectedTreatmentDate.day} - ${_selectedTreatmentTime.format(context)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _showDateTimePicker(
                  initialDate: _selectedTreatmentDate,
                  initialTime: _selectedTreatmentTime,
                  onSelected: (date, time) {
                    setState(() {
                      _selectedTreatmentDate = date;
                      _selectedTreatmentTime = time;
                    });
                  },
                ),
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
            onPressed:
                _isSubmitting ? null : () => _addTreatmentDetail(scheduleId),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTreatmentSchedules,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
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

    if (_treatmentSchedules.isEmpty) {
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
              onPressed: _showAddScheduleDialog,
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
              itemCount: _treatmentSchedules.length,
              itemBuilder: (context, index) {
                final schedule = _treatmentSchedules[index];
                final scheduleId = schedule['id'];
                final details = _treatmentDetails[scheduleId] ?? [];
                return _buildScheduleCard(schedule, details);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
      Map<String, dynamic> schedule, List<Map<String, dynamic>> details) {
    final String id = schedule['id'];
    final String description = schedule['description'] ?? '';
    final bool isCompleted = schedule['is_completed'] ?? false;

    // Parse date and time
    DateTime date;
    try {
      // Try to parse the time field
      if (schedule['time'] != null) {
        date = DateTime.parse(schedule['time'].toString());
      }
      // If time is null, try to parse the date field
      else if (schedule['date'] != null) {
        final dateStr = schedule['date'].toString();
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

    // Check if any treatments are due today
    bool hasTreatmentsDueToday = false;
    for (final detail in details) {
      try {
        final DateTime detailDate = DateTime.parse(detail['time'].toString());
        final bool isDetailToday = detailDate.day == DateTime.now().day &&
            detailDate.month == DateTime.now().month &&
            detailDate.year == DateTime.now().year;
        if (isDetailToday) {
          hasTreatmentsDueToday = true;
          break;
        }
      } catch (e) {
        // Skip if date parsing fails
      }
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
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ප්‍රතිකාර සැලසුම',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            // Add a bell icon for schedules with treatments due today
            if (hasTreatmentsDueToday && !isCompleted)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(isCompleted, isToday, isUpcoming),
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
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? Colors.green : Colors.grey[600],
              ),
              onPressed: () => _toggleScheduleCompletion(id, isCompleted),
              tooltip: isCompleted ? 'Mark as incomplete' : 'Mark as complete',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteTreatmentSchedule(id),
              color: Colors.grey[700],
              tooltip: 'Delete schedule',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ප්‍රතිකාර විස්තර',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: isCompleted
                          ? null
                          : () => _showAddTreatmentDetailDialog(id),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('නව ප්‍රතිකාරයක්'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (details.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'මෙම සැලසුමට ප්‍රතිකාර විස්තර නැත',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: details.length,
                    itemBuilder: (context, index) {
                      return _buildTreatmentDetailItem(id, details[index]);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentDetailItem(
      String scheduleId, Map<String, dynamic> detail) {
    final String id = detail['id'];
    final String title = detail['title'] ?? '';

    // Parse date and time
    DateTime date;
    try {
      if (detail['time'] != null) {
        date = DateTime.parse(detail['time'].toString());
      } else if (detail['date'] != null) {
        final dateStr = detail['date'].toString();
        if (dateStr.length <= 10) {
          date = DateTime.parse("${dateStr}T00:00:00");
        } else {
          date = DateTime.parse(dateStr);
        }
      } else {
        date = DateTime.now();
      }
    } catch (e) {
      date = DateTime.now();
    }

    final bool isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.medication,
          color: isToday ? Colors.orange : Colors.blue,
        ),
        title: Text(title),
        subtitle: Text(
          DateFormat('yyyy/MM/dd - HH:mm').format(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _deleteTreatmentDetail(scheduleId, id),
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
