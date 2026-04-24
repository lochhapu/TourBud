import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tour_bud/config.dart';
import 'package:tour_bud/widgets/bottom_nav_bar.dart';
import 'package:tour_bud/my_trips.dart' show Trip;
import 'package:tour_bud/budget_page.dart';
import 'location_detail_page.dart';

class Location {
  final int id;
  final String placeName;
  final String arrivalDate;
  final String departureDate;
  final String? notes;

  Location({
    required this.id,
    required this.placeName,
    required this.arrivalDate,
    required this.departureDate,
    this.notes,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int,
      placeName: json['place_name'] as String,
      arrivalDate: json['arrival_date'] as String,
      departureDate: json['departure_date'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class TripDetailsPage extends StatefulWidget {
  final Trip trip;

  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _selectedIndex = 1; // Default to trips index

  late Future<List<Location>> _locationsFuture;

  static const Color teal = Color(0xFF28ABB9);
  static const Color navy = Color(0xFF2D6187);
  static const Color mintBg = Color(0xFFEFFAD3);
  static const Color sage = Color(0xFFA8DDA8);
  static const Color darkSage = Color(0xFF7F9068);

  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _locationArrivalDate;
  DateTime? _locationDepartureDate;

  @override
  void initState() {
    super.initState();
    _locationsFuture = fetchLocations();
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mintBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: navy,
                        size: 18,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none, color: navy),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.person_outline, color: navy),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: navy,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trip Details Card
                    _buildDetailsCard(),
                    const SizedBox(height: 28),

                    // Budget Card
                    _buildFeatureCard(
                      title: 'Budget',
                      icon: Icons.wallet_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BudgetPage(trip: widget.trip),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Search Bar + Add New Location Row
                    Row(
                      children: [
                        // Search Bar
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: teal.withOpacity(0.5),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: navy.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search location...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: navy.withOpacity(0.4),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: teal,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Add New Location Button
                        GestureDetector(
                          onTap: () => _showAddLocationDialog(),

                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: teal,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.add_location_alt_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Add New\nLocation',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    _buildLocationsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Handle navigation based on index
        },
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFEFFAD3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Location',
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
                // Place Name
                TextField(
                  controller: _placeNameController,
                  decoration: InputDecoration(
                    hintText: 'Place Name',
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

                // Arrival & Departure Date Row
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
                            setDialogState(() {
                              _locationArrivalDate = picked;
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
                            _locationArrivalDate == null
                                ? 'Arrival Date'
                                : _locationArrivalDate.toString().split(' ')[0],
                            style: TextStyle(
                              color: _locationArrivalDate == null
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
                            initialDate: _locationArrivalDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _locationDepartureDate = picked;
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
                            _locationDepartureDate == null
                                ? 'Departure Date'
                                : _locationDepartureDate.toString().split(
                                    ' ',
                                  )[0],
                            style: TextStyle(
                              color: _locationDepartureDate == null
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

                // Notes (optional)
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
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
              onPressed: () {
                // Clear fields on cancel
                _placeNameController.clear();
                _notesController.clear();
                setState(() {
                  _locationArrivalDate = null;
                  _locationDepartureDate = null;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF2D6187)),
              ),
            ),
            ElevatedButton(
              onPressed: () => _saveLocation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F9068),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLocation() async {
    final placeName = _placeNameController.text.trim();

    // Validation
    if (placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a place name.')),
      );
      return;
    }
    if (_locationArrivalDate == null || _locationDepartureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select arrival and departure dates.'),
        ),
      );
      return;
    }
    if (_locationDepartureDate!.isBefore(_locationArrivalDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Departure date must be after arrival date.'),
        ),
      );
      return;
    }

    final body = {
      'place_name': placeName,
      'arrival_date': _locationArrivalDate!.toIso8601String().split('T')[0],
      'departure_date': _locationDepartureDate!.toIso8601String().split('T')[0],
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/trips/${widget.trip.id}/locations'),
        headers: {...AppConfig.authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _placeNameController.clear();
        _notesController.clear();
        setState(() {
          _locationArrivalDate = null;
          _locationDepartureDate = null;
          _locationsFuture = fetchLocations();
        });

        if (mounted) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location added successfully')),
        );
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['error'] ?? 'Failed to save location'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: ${e.toString()}')),
      );
    }
  }

  Future<List<Location>> fetchLocations() async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/trips/${widget.trip.id}/locations',
    );
    final response = await http.get(uri, headers: AppConfig.authHeaders);

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['error'] ?? 'Failed to load locations');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final locationsList = data['locations'] as List<dynamic>;

    return locationsList
        .map((item) => Location.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Widget _buildLocationsSection() {
    return FutureBuilder<List<Location>>(
      future: _locationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: Color(0xFF2D6187)),
            ),
          );
        }

        final locations = snapshot.data ?? [];
        if (locations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: const Text(
              'No locations added yet. Tap Add New Location to begin.',
              style: TextStyle(fontSize: 14, color: Color(0xFF2D6187)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Locations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6187),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: locations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final location = locations[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationDetailPage(location: location),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: teal.withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.placeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D6187),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Arrival: ${location.arrivalDate}',
                                style: const TextStyle(
                                  color: Color(0xFF2D6187),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Departure: ${location.departureDate}',
                                style: const TextStyle(
                                  color: Color(0xFF2D6187),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (location.notes != null &&
                            location.notes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            location.notes!,
                            style: const TextStyle(color: Color(0xFF2D6187)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withOpacity(0.6), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.trip.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: navy,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Duration',
            value: '${widget.trip.startDate} → ${widget.trip.endDate}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.wallet_outlined,
            label: 'Budget Goal',
            value:
                '${widget.trip.currency} ${widget.trip.budgetGoal?.toStringAsFixed(0) ?? 'N/A'}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: navy.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: sage.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: darkSage, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: darkSage.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 28, color: navy),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: navy,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
