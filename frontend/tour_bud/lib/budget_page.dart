import 'package:flutter/material.dart';
import 'package:tour_bud/my_trips.dart';

class ExpenseItem {
  final String title;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final String note;

  ExpenseItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.note,
  });
}

class BudgetPage extends StatefulWidget {
  final Trip trip;

  const BudgetPage({super.key, required this.trip});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  static const Color teal = Color(0xFF28ABB9);
  static const Color navy = Color(0xFF2D6187);
  static const Color sage = Color(0xFFA8DDA8);
  static const Color mintBg = Color(0xFFEFFAD3);
  static const Color cardBg = Color(0xFFF4F9E6);

  final List<ExpenseItem> _expenses = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Transport';
  String _selectedCurrency = 'USD';

  static const Map<String, double> _currencyRatesToUsd = {
    'USD': 1.0,
    'LKR': 0.000317,
    'EUR': 1.07,
    'GBP': 1.25,
  };

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.trip.currency.isNotEmpty
        ? widget.trip.currency
        : 'USD';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _convertedBudget {
    if (widget.trip.budgetGoal == null) return 0.0;
    final fromRate = _currencyRatesToUsd[widget.trip.currency] ?? 1.0;
    final toRate = _currencyRatesToUsd[_selectedCurrency] ?? 1.0;
    return widget.trip.budgetGoal! * fromRate / toRate;
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0).replaceAllMapped(
            RegExp(r"\B(?=(\d{3})+(?!\d))"),
            (match) => ',');
    }
    return value.toStringAsFixed(2);
  }

  String _headerForDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    }
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.local_taxi;
      case 'Hotel':
        return Icons.hotel;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.receipt_long;
    }
  }

  void _showAddExpenseDialog() {
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    _selectedCategory = 'Transport';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: mintBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold, color: navy),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Transport', 'Food', 'Hotel', 'Shopping', 'Entertainment']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Note',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final title = _titleController.text.trim();
              final amount = double.tryParse(_amountController.text.trim());
              if (title.isEmpty || amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title and valid amount.')),
                );
                return;
              }

              setState(() {
                _expenses.add(ExpenseItem(
                  title: title,
                  category: _selectedCategory,
                  amount: amount,
                  currency: widget.trip.currency.isNotEmpty ? widget.trip.currency : 'USD',
                  date: DateTime.now(),
                  note: _noteController.text.trim(),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpenseGroups() {
    if (_expenses.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: const [
              Icon(Icons.receipt_long, size: 54, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No expenses added yet. Tap + to add your first expense.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      ];
    }

    final grouped = <String, List<ExpenseItem>>{};
    for (final expense in _expenses) {
      final header = _headerForDate(expense.date);
      grouped.putIfAbsent(header, () => []).add(expense);
    }

    final widgets = <Widget>[];
    grouped.forEach((header, items) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: Text(
          header,
          style: const TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      widgets.addAll(items.map(_buildExpenseCard));
    });
    return widgets;
  }

  Widget _buildExpenseCard(ExpenseItem expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: sage.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForCategory(expense.category),
              color: navy,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${expense.category} charges',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.title,
                  style: const TextStyle(color: Color(0xFF566E84)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${expense.currency} ${_formatCurrency(expense.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                expense.date.toString().split(' ')[0],
                style: const TextStyle(color: Color(0xFF7A8A9D), fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF7A8A9D)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mintBg,
      body: SafeArea(
        child: Column(
          children: [
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
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: navy, size: 18),
                    ),
                  ),
                  const Text(
                    'My Trips - Budget',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBudgetCard(),
                    const SizedBox(height: 24),
                    ..._buildExpenseGroups(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: navy,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopBudgetCard() {
    final budgetValue = widget.trip.budgetGoal ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDCECCF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: sage.withOpacity(0.9), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Budget',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${_formatCurrency(budgetValue)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F3E4F),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.trip.currency.isNotEmpty
                        ? widget.trip.currency
                        : _selectedCurrency,
                    items: ['USD', 'LKR', 'EUR', 'GBP']
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
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Converted',
                  style: TextStyle(color: Color(0xFF7A8A9D), fontSize: 14),
                ),
                Text(
                  '${_selectedCurrency.toUpperCase()} ${_formatCurrency(_convertedBudget)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
