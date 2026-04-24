import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tour_bud/config.dart';
import 'package:tour_bud/widgets/bottom_nav_bar.dart';
import 'package:tour_bud/trip_details.dart';
import 'dashboard_page.dart';

class Trip {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final double? budgetGoal;
  final String currency;

  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.budgetGoal,
    required this.currency,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      name: json['trip_name'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      budgetGoal: json['budget_goal'] != null
          ? (json['budget_goal'] as num).toDouble()
          : null,
      currency: json['budget_currency'] as String? ?? '',
    );
  }
}

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  late Future<List<Trip>> _tripsFuture;
  int _selectedIndex = 0;

  // Form controllers for adding a trip
  final _tripNameController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _tripsFuture = fetchTrips();
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<List<Trip>> fetchTrips() async {
    final token = AppConfig.authToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/trips');
    final response = await http.get(uri, headers: AppConfig.authHeaders);

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['error'] ?? 'Failed to load trips');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tripsList = data['trips'] as List<dynamic>;
    return tripsList
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAD3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Trips',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D6187),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none,
                            color: Color(0xFF2D6187)),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.person_outline,
                            color: Color(0xFF2D6187)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Trip>>(
                future: _tripsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF2D6187),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  final trips = snapshot.data ?? [];
                  if (trips.isEmpty) {
                    return const Center(
                      child: Text(
                        'No trips available yet.',
                        style: TextStyle(
                          color: Color(0xFF2D6187),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return _buildTripCard(trip);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripDialog,
        backgroundColor: const Color(0xFF28ABB9),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Future<void> createTrip() async {
    if (_tripNameController.text.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final token = AppConfig.authToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    final body = {
      'trip_name': _tripNameController.text,
      'start_date': _startDate.toString().split(' ')[0],
      'end_date': _endDate.toString().split(' ')[0],
      'budget_goal': _budgetController.text.isEmpty
          ? null
          : double.tryParse(_budgetController.text),
      'budget_currency': _selectedCurrency,
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/trips'),
        headers: AppConfig.authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _tripNameController.clear();
        _budgetController.clear();
        _startDate = null;
        _endDate = null;
        _selectedCurrency = 'USD';

        if (mounted) {
          Navigator.pop(context);
          setState(() {
            _tripsFuture = fetchTrips();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created successfully')),
        );
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['error'] ?? 'Failed to create trip')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showAddTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEFFAD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Trip',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D6187),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tripNameController,
                decoration: InputDecoration(
                  hintText: 'Trip Name',
                  filled: true,
                  fillColor: const Color(0xFFDFF1D8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF7F9068),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF1D8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7F9068),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Start Date'
                              : _startDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: _startDate == null
                                ? Colors.grey[600]
                                : const Color(0xFF2D6187),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF1D8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7F9068),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _endDate == null
                              ? 'End Date'
                              : _endDate.toString().split(' ')[0],
                          style: TextStyle(
                            color: _endDate == null
                                ? Colors.grey[600]
                                : const Color(0xFF2D6187),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Budget (optional)',
                  filled: true,
                  fillColor: const Color(0xFFDFF1D8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF7F9068),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                items: ['USD', 'EUR', 'GBP', 'JPY', 'LKR']
                    .map((currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFDFF1D8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF7F9068),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF2D6187)),
            ),
          ),
          ElevatedButton(
            onPressed: createTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28ABB9),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsPage(trip: trip),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDFF1D8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7F9068), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6187),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xFF2D6187)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${trip.startDate} → ${trip.endDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D6187),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Budget goal: ${trip.currency} ${trip.budgetGoal?.toStringAsFixed(0) ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D6187),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
