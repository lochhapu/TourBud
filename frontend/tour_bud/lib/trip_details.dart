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
                        icon: const Icon(Icons.notifications_none,
                            color: navy),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon:
                            const Icon(Icons.person_outline, color: navy),
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

                    // To-do and Gallery Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallFeatureCard(
                            title: 'To-do',
                            icon: Icons.checklist_rtl,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSmallFeatureCard(
                            title: 'Gallery',
                            icon: Icons.image_outlined,
                            onTap: () {},
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
            value:
                '${widget.trip.startDate} → ${widget.trip.endDate}',
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

  Widget _buildSmallFeatureCard({
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: navy),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: navy,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
