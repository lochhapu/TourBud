import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tour_bud/config.dart';
import 'package:tour_bud/widgets/bottom_nav_bar.dart';

class TodoList {
  final int id;
  final String name;

  TodoList({required this.id, required this.name});

  factory TodoList.fromJson(Map<String, dynamic> json) {
    return TodoList(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late Future<List<TodoList>> _listsFuture;
  int _selectedIndex = 2; // Adjust index to match your nav bar position

  final _listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listsFuture = fetchLists();
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  Future<List<TodoList>> fetchLists() async {
    final token = AppConfig.authToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/locations/{locationID}/todos/todos');
    final response = await http.get(uri, headers: AppConfig.authHeaders);

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['error'] ?? 'Failed to load lists');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final listData = data['lists'] as List<dynamic>;
    return listData
        .map((item) => TodoList.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createList() async {
    if (_listNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
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

    final body = {'name': _listNameController.text};

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/todo-lists'),
        headers: AppConfig.authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _listNameController.clear();

        if (mounted) {
          Navigator.pop(context);
          setState(() {
            _listsFuture = fetchLists();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List created successfully')),
        );
      } else {
        final decoded = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['error'] ?? 'Failed to create list')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showAddListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEFFAD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add List',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D6187),
          ),
        ),
        content: TextField(
          controller: _listNameController,
          decoration: InputDecoration(
            hintText: 'List Name',
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
            onPressed: createList,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F9068),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
                        'TO-DO Lists',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D6187),
                        ),
                      ),
                      Text(
                        'My Lists',
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

            // Divider
            const Divider(
              color: Color(0xFFBDD6A8),
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            const SizedBox(height: 8),

            // Grid of lists
            Expanded(
              child: FutureBuilder<List<TodoList>>(
                future: _listsFuture,
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

                  final lists = snapshot.data ?? [];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: lists.length + 1, // +1 for the "Add" tile
                      itemBuilder: (context, index) {
                        if (index == lists.length) {
                          // Add new list tile
                          return _buildAddTile();
                        }
                        return _buildListTile(lists[index]);
                      },
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

  Widget _buildListTile(TodoList list) {
    return GestureDetector(
      onTap: () {
        // Navigate to list detail page
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => TodoListDetailPage(list: list),
        // ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDFF1D8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7F9068),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          list.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _showAddListDialog,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFF7F9068),
          borderRadius: 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDFF1D8),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add,
            size: 36,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    this.borderRadius = 16,
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashPath.addPath(metric.extractPath(start, end), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
