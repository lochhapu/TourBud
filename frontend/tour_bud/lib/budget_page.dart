import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tour_bud/config.dart';
import 'package:tour_bud/my_trips.dart';

class ExpenseItem {
  final int id;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final String note;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.note,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: json['id'] as int,
      title: (json['description'] as String?) == ''
          ? json['category'] as String
          : json['description'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: (json['currency'] as String).toUpperCase(),
      date: DateTime.parse(json['expense_date'] as String),
      note: json['description'] as String? ?? '',
    );
  }
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
  bool _isLoadingExpenses = false;

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
    _loadExpenses();
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

  static const Map<String, String> _uiToApiCategory = {
    'Transport': 'transportation',
    'Food': 'food',
    'Hotel': 'accommodation',
    'Shopping': 'shopping',
    'Entertainment': 'activities',
  };

  static const Map<String, String> _apiToUiCategory = {
    'transportation': 'Transport',
    'food': 'Food',
    'accommodation': 'Hotel',
    'shopping': 'Shopping',
    'activities': 'Entertainment',
    'other': 'Other',
  };

  String _displayCategory(String category) {
    return _apiToUiCategory[category.toLowerCase()] ?? category;
  }

  String _apiCategory(String uiCategory) {
    return _uiToApiCategory[uiCategory] ?? uiCategory.toLowerCase();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoadingExpenses = true;
    });

    final uri = Uri.parse('${AppConfig.baseUrl}/trips/${widget.trip.id}/expenses');
    try {
      final response = await http.get(uri, headers: AppConfig.authHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final expensesJson = data['expenses'] as List<dynamic>;
        setState(() {
          _expenses
            ..clear()
            ..addAll(expensesJson
                .map((item) => ExpenseItem.fromJson(item as Map<String, dynamic>))
                .toList());
        });
      } else {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['error'] ?? 'Failed to load expenses.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load expenses.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExpenses = false;
        });
      }
    }
  }

  double _convertAmount(double amount, String fromCurrency, String toCurrency) {
    final fromRate = _currencyRatesToUsd[fromCurrency] ?? 1.0;
    final toRate = _currencyRatesToUsd[toCurrency] ?? 1.0;
    return amount * fromRate / toRate;
  }

  double get _totalExpensesInSelectedCurrency {
    return _expenses.fold(0.0, (sum, expense) {
      return sum + _convertAmount(expense.amount, expense.currency, _selectedCurrency);
    });
  }

  double get _remainingBalance {
    return _convertedBudget - _totalExpensesInSelectedCurrency;
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
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.local_taxi;
      case 'hotel':
      case 'accommodation':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
      case 'activities':
        return Icons.movie;
      default:
        return Icons.receipt_long;
    }
  }

  Future<bool> _saveExpenseToServer(String title, double amount, String note) async {
    final body = {
      'amount': amount,
      'category': _apiCategory(_selectedCategory),
      'currency': widget.trip.currency.isNotEmpty ? widget.trip.currency : 'USD',
      'description': note.isNotEmpty ? '$title - $note' : title,
      'expense_date': DateTime.now().toString().split(' ')[0],
    };

    final uri = Uri.parse('${AppConfig.baseUrl}/trips/${widget.trip.id}/expenses');
    try {
      final response = await http.post(
        uri,
        headers: AppConfig.authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final expenseJson = decoded['expense'] as Map<String, dynamic>;
        final expense = ExpenseItem.fromJson(expenseJson);

        setState(() {
          _expenses.insert(0, expense);
        });
        return true;
      }

      final decoded = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['error'] ?? 'Unable to save expense.')),
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save expense.')),
        );
      }
      return false;
    }
  }

  Future<void> _deleteExpense(ExpenseItem expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navy),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uri = Uri.parse('${AppConfig.baseUrl}/trips/${widget.trip.id}/expenses/${expense.id}');
    try {
      final response = await http.delete(uri, headers: AppConfig.authHeaders);
      if (response.statusCode == 200) {
        setState(() {
          _expenses.removeWhere((item) => item.id == expense.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully.')),
          );
        }
      } else {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['error'] ?? 'Unable to delete expense.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete expense.')),
        );
      }
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
              backgroundColor: teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = _titleController.text.trim();
              final amount = double.tryParse(_amountController.text.trim());
              final note = _noteController.text.trim();
              if (title.isEmpty || amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title and valid amount.')),
                );
                return;
              }

              final saved = await _saveExpenseToServer(title, amount, note);
              if (saved && mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpenseGroups() {
    if (_isLoadingExpenses) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

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
                  '${_displayCategory(expense.category)} charges',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _deleteExpense(expense),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFF7A8A9D)),
                ],
              ),
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
        backgroundColor: teal,
        child: const Icon(Icons.add, color: Colors.white),
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
                  '${widget.trip.currency.toUpperCase()} ${_formatCurrency(budgetValue)}',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining balance',
                      style: TextStyle(color: Color(0xFF7A8A9D), fontSize: 14),
                    ),
                    Text(
                      '${_selectedCurrency.toUpperCase()} ${_formatCurrency(_remainingBalance)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _remainingBalance < 0 ? Colors.red : navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
