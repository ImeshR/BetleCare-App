import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
    final plansResponse = await _supabase.from('treatment_schedules').select();
    final treatmentsResponse =
        await _supabase.from('treatment_details').select();

    Map<String, List<Map<String, dynamic>>> planTreatments = {};

    for (var treatment in treatmentsResponse) {
      String planId = treatment['plan_id'];
      if (!planTreatments.containsKey(planId)) {
        planTreatments[planId] = [];
      }
      planTreatments[planId]!.add(treatment);
    }

    setState(() {
      _treatmentPlans = plansResponse.map((plan) {
        return {
          ...plan,
          'treatments': planTreatments[plan['id']] ?? [],
        };
      }).toList();
    });
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

  Future<void> _addTreatmentPlan(
      String planTitle, List<Map<String, dynamic>> treatments) async {
    if (planTitle.isEmpty || treatments.isEmpty) return;

    final response = await _supabase
        .from('treatment_schedules')
        .insert({
          'title': planTitle,
          'created_at': DateTime.now().toIso8601String()
        })
        .select('id')
        .single();

    if (response == null || response['id'] == null) {
      print('Error creating treatment plan');
      return;
    }

    String planId = response['id'];

    List<Map<String, dynamic>> treatmentEntries = treatments.map((treatment) {
      return {
        'plan_id': planId,
        'title': treatment['title'],
        'date': treatment['date'].toIso8601String(),
        'time': DateTime(
                2025, 1, 1, treatment['time'].hour, treatment['time'].minute)
            .toIso8601String(),
      };
    }).toList();

    await _supabase.from('treatment_details').insert(treatmentEntries);
    _loadTreatmentPlans(); // Refresh UI
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

  Future<void> _showAddTreatmentDialog() async {
    TextEditingController planTitleController = TextEditingController();
    List<Map<String, dynamic>> treatments = [];

    void addTreatment() {
      treatments
          .add({'title': '', 'date': DateTime.now(), 'time': TimeOfDay.now()});
    }

    addTreatment(); // Add an initial treatment

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Treatment Plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: planTitleController,
                      decoration: InputDecoration(labelText: 'Plan Title'),
                    ),
                    SizedBox(height: 10),
                    ...treatments.asMap().entries.map((entry) {
                      int index = entry.key;
                      var treatment = entry.value;
                      return Column(
                        children: [
                          TextField(
                            decoration:
                                InputDecoration(labelText: 'Treatment Title'),
                            onChanged: (value) {
                              treatments[index]['title'] = value;
                            },
                          ),
                          Row(
                            children: [
                              Text('Date: ${treatment['date'].toLocal()}'),
                              IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: treatment['date'],
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      treatments[index]['date'] = pickedDate;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                  'Time: ${treatment['time'].format(context)}'),
                              IconButton(
                                icon: Icon(Icons.access_time),
                                onPressed: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: treatment['time'],
                                  );
                                  if (pickedTime != null) {
                                    setState(() {
                                      treatments[index]['time'] = pickedTime;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      );
                    }).toList(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          addTreatment();
                        });
                      },
                      child: Text('Add Another Treatment'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addTreatmentPlan(planTitleController.text, treatments);
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
