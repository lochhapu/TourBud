import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tour_bud/config.dart';
import 'package:tour_bud/my_trips.dart' show Trip;
import 'package:tour_bud/trip_details.dart' show Location;
import 'package:tour_bud/widgets/bottom_nav_bar.dart';

/// Shared image store for managing gallery images per location
class LocationImageStore {
  static final Map<int, List<String>> _store = {};

  static Map<int, List<String>> getStore() => _store;

  static void addImage(int locationId, String imagePath) {
    _store.putIfAbsent(locationId, () => <String>[]);
    _store[locationId]!.add(imagePath);
  }

  static void removeImage(int locationId, int imageIndex) {
    if (_store.containsKey(locationId) &&
        imageIndex < _store[locationId]!.length) {
      _store[locationId]!.removeAt(imageIndex);
    }
  }

  static List<String> getImages(int locationId) {
    return _store[locationId] ?? <String>[];
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int _selectedIndex = 2; // Gallery tab index
  late Future<List<Trip>> _tripsFuture;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tripsFuture = fetchTrips();
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

  Future<List<Location>> fetchLocationsForTrip(int tripId) async {
    final token = AppConfig.authToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/trips/$tripId/locations');
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

  Future<void> _pickImageForLocation(int locationId) async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedFile == null) return;

    setState(() {
      LocationImageStore.addImage(locationId, pickedFile.path);
    });
  }

  void _deleteImage(int locationId, int imageIndex) {
    setState(() {
      LocationImageStore.removeImage(locationId, imageIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAD3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'GALLERY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D6187),
                        ),
                      ),
                      Text(
                        'Trip Photos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D6187),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Color(0xFF2D6187),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2D6187),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(
              color: Color(0xFFBDD6A8),
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            const SizedBox(height: 8),

            // Trips and Locations Gallery
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
                          'Error: ${snapshot.error}',
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: Color(0xFF2D6187),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No trips yet. Create a trip to start uploading photos!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF2D6187),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: trips
                          .map((trip) => _buildTripSection(trip))
                          .toList(),
                    ),
                  );
                },
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
        },
      ),
    );
  }

  Widget _buildTripSection(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            trip.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D6187),
            ),
          ),
        ),
        FutureBuilder<List<Location>>(
          future: fetchLocationsForTrip(trip.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading locations',
                  style: const TextStyle(color: Color(0xFF2D6187)),
                ),
              );
            }

            final locations = snapshot.data ?? [];

            if (locations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF28ABB9).withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No locations added to this trip',
                    style: TextStyle(fontSize: 14, color: Color(0xFF2D6187)),
                  ),
                ),
              );
            }

            return Column(
              children: locations
                  .map((location) => _buildLocationGallerySection(location))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLocationGallerySection(Location location) {
    final images = LocationImageStore.getImages(location.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              location.placeName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D6187),
              ),
            ),
            IconButton(
              onPressed: () => _pickImageForLocation(location.id),
              icon: const Icon(Icons.add_a_photo, color: Color(0xFF2D6187)),
              tooltip: 'Add photo',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF28ABB9).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'No photos yet. Tap + to add.',
              style: TextStyle(fontSize: 14, color: Color(0xFF2D6187)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final imagePath = images[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFFE7F2E5),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        onPressed: () => _deleteImage(location.id, index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
