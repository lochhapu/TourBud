import 'package:flutter/material.dart';
import 'package:tour_bud/dashboard_page.dart';
import 'package:tour_bud/gallery_page.dart';
import 'package:tour_bud/my_trips.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = const Color(0xFF2D6187),
    this.selectedItemColor = const Color(0xFFEFFAD3),
    this.unselectedItemColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTap(index);
        // Handle Home navigation
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyWidget()),
          );
        }
        // Handle Gallery navigation
        if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GalleryPage()),
          );
        }
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyTripsPage()),
          );
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Budget'),
        BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Gallery'),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_travel),
          label: 'My Trips',
        ),
      ],
    );
  }
}
