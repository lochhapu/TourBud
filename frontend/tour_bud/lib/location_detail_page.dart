import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tour_bud/config.dart';
import 'package:tour_bud/widgets/bottom_nav_bar.dart';
import 'package:tour_bud/trip_details.dart' show Location;

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

class Todo {
  final int id;
  final String description;
  final bool isCompleted;
  final String category;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;

  Todo({
    required this.id,
    required this.description,
    required this.isCompleted,
    required this.category,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      description: json['description'] as String,
      isCompleted: _parseBool(json['is_completed']),
      category: json['category'] as String,
      dueDate: json['due_date'] as String?,
      createdAt: json['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['created_at'] as int) * 1000,
            ).toIso8601String()
          : json['created_at'] as String,
      updatedAt: json['updated_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['updated_at'] as int) * 1000,
            ).toIso8601String()
          : json['updated_at'] as String,
    );
  }
}

class LocationDetailPage extends StatefulWidget {
  final Location location;

  const LocationDetailPage({super.key, required this.location});

  @override
  State<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends State<LocationDetailPage> {
  late Future<List<Todo>> _todosFuture;
  final TextEditingController _todoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late List<String> _currentImagePaths;

  @override
  void initState() {
    super.initState();
    _todosFuture = fetchTodos();
    _currentImagePaths = List.from(
      LocationImageStore.getImages(widget.location.id),
    );
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  void _syncLocationImages() {
    // Update the shared store with current paths
    final store = LocationImageStore.getStore();
    store[widget.location.id] = List.from(_currentImagePaths);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (pickedFile == null) return;

    setState(() {
      _currentImagePaths.add(pickedFile.path);
      _syncLocationImages();
    });
  }

  void _deleteImage(int index) {
    setState(() {
      _currentImagePaths.removeAt(index);
      _syncLocationImages();
    });
  }

  Future<List<Todo>> fetchTodos() async {
    final token = AppConfig.authToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/locations/${widget.location.id}/todos',
    );
    final response = await http.get(uri, headers: AppConfig.authHeaders);

    if (response.statusCode != 200) {
      final body = response.body.trim();
      if (body.isNotEmpty) {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic> && decoded['error'] != null) {
            throw Exception(decoded['error']);
          }
        } catch (_) {
          // Fall through to generic error
        }
      }
      throw Exception('Failed to load todos');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final todosData = data['todos'] as List<dynamic>;
    return todosData
        .map((item) => Todo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _parseApiError(
    http.Response response, {
    String fallback = 'An error occurred',
  }) {
    final body = response.body.trim();
    if (body.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {
      // Ignore invalid JSON body
    }
    return fallback;
  }

  Future<void> addTodo() async {
    if (_todoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a todo description')),
      );
      return;
    }

    final token = AppConfig.authToken;
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    final body = {'description': _todoController.text};

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/locations/${widget.location.id}/todos'),
        headers: AppConfig.authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _todoController.clear();
        setState(() {
          _todosFuture = fetchTodos();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo added successfully')),
        );
      } else {
        final message = _parseApiError(
          response,
          fallback: 'Failed to add todo',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> toggleTodo(Todo todo) async {
    final token = AppConfig.authToken;
    if (token == null) return;

    final endpoint = todo.isCompleted
        ? '${AppConfig.baseUrl}/todos/${todo.id}/incomplete'
        : '${AppConfig.baseUrl}/todos/${todo.id}/complete';

    try {
      final response = await http.patch(
        Uri.parse(endpoint),
        headers: AppConfig.authHeaders,
      );

      if (response.statusCode == 200) {
        setState(() {
          _todosFuture = fetchTodos();
        });
      } else {
        final message = _parseApiError(
          response,
          fallback: 'Failed to update todo',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    final token = AppConfig.authToken;
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/todos/${todo.id}'),
        headers: AppConfig.authHeaders,
      );

      if (response.statusCode == 200) {
        setState(() {
          _todosFuture = fetchTodos();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo deleted successfully')),
        );
      } else {
        final message = _parseApiError(
          response,
          fallback: 'Failed to delete todo',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
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
                            color: const Color(0xFF2D6187).withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2D6187),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.location.placeName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D6187),
                          ),
                        ),
                        Text(
                          '${widget.location.arrivalDate} - ${widget.location.departureDate}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D6187),
                          ),
                        ),
                      ],
                    ),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF28ABB9).withOpacity(0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D6187).withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D6187),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Place: ${widget.location.placeName}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D6187),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Arrival: ${widget.location.arrivalDate}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D6187),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Departure: ${widget.location.departureDate}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D6187),
                            ),
                          ),
                          if (widget.location.notes != null &&
                              widget.location.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Notes: ${widget.location.notes}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2D6187),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gallery Section
                    _buildGallerySection(),

                    const SizedBox(height: 24),

                    // Todos Section
                    _buildTodosSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Assuming trips index
        onTap: (index) {
          // Handle navigation if needed
        },
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gallery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6187),
              ),
            ),
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo, color: Color(0xFF2D6187)),
              tooltip: 'Add photo',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_currentImagePaths.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF28ABB9).withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: const Text(
              'No images yet. Tap the + button to add photos for this location.',
              style: TextStyle(fontSize: 16, color: Color(0xFF2D6187)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentImagePaths.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final imagePath = _currentImagePaths[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        onPressed: () => _deleteImage(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildTodosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'To-Do List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6187),
              ),
            ),
            IconButton(
              onPressed: () => _showAddTodoDialog(),
              icon: const Icon(Icons.add, color: Color(0xFF2D6187)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Todo>>(
          future: _todosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFF2D6187)),
                ),
              );
            }

            final todos = snapshot.data ?? [];

            if (todos.isEmpty) {
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
                    'No todos yet. Add one!',
                    style: TextStyle(fontSize: 16, color: Color(0xFF2D6187)),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: todos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF28ABB9).withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: todo.isCompleted,
                        onChanged: (value) => toggleTodo(todo),
                        activeColor: const Color(0xFF7F9068),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          todo.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF2D6187),
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => deleteTodo(todo),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEFFAD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Todo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D6187),
          ),
        ),
        content: TextField(
          controller: _todoController,
          decoration: InputDecoration(
            hintText: 'Todo description',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF2D6187)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              addTodo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F9068),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
