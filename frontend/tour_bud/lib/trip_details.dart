import 'package:flutter/material.dart';
import 'package:tour_bud/widgets/bottom_nav_bar.dart';
import 'package:tour_bud/my_trips.dart' show Trip;

class TripDetailsPage extends StatefulWidget {
  final Trip trip;

  const TripDetailsPage({super.key, required this.trip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  int _selectedIndex = 1; // Default to trips index

  static const Color teal = Color(0xFF28ABB9);
  static const Color navy = Color(0xFF2D6187);
  static const Color mintBg = Color(0xFFEFFAD3);
  static const Color sage = Color(0xFFA8DDA8);
  static const Color darkSage = Color(0xFF7F9068);

  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _locationArrivalDate;
  DateTime? _locationDepartureDate;

  void dispose(){
    _placeNameController.dispose();
    _notesController.dispose();
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
                      onTap: () {},
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          initialDate:
                              _locationArrivalDate ?? DateTime.now(),
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
                              : _locationDepartureDate
                                  .toString()
                                  .split(' ')[0],
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

void _saveLocation() {
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
      const SnackBar(content: Text('Please select arrival and departure dates.')),
    );
    return;
  }
  if (_locationDepartureDate!.isBefore(_locationArrivalDate!)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Departure date must be after arrival date.')),
    );
    return;
  }
 
  // TODO: Call your DB helper to insert into the locations table:
  //
  // await dbHelper.insertLocation({
  //   'trip_id': widget.trip.id,
  //   'place_name': placeName,
  //   'arrival_date': _locationArrivalDate!.toIso8601String().split('T')[0],
  //   'departure_date': _locationDepartureDate!.toIso8601String().split('T')[0],
  //   'notes': _notesController.text.trim(),
  //   'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  //   'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  // });
 
  // Clear fields
  _placeNameController.clear();
  _notesController.clear();
  setState(() {
    _locationArrivalDate = null;
    _locationDepartureDate = null;
  });
 
  Navigator.pop(context);
}

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: teal.withOpacity(0.6),
          width: 1.4,
        ),
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