import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../database/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshExpenses();
  }

  String? _errorMessage;

  Future<void> _refreshExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      _expenses = await DatabaseHelper.instance.getExpenses();
    } catch (e) {
      print('Database Error: $e');
      _errorMessage = e.toString();
    }
    
    setState(() => _isLoading = false);
  }

  double get _totalExpenses {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _showAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseModal(onAddExpense: _addExpense),
    );
  }

  Future<void> _addExpense(String title, double amount, DateTime date) async {
    final expense = Expense(title: title, amount: amount, date: date);
    await DatabaseHelper.instance.insertExpense(expense);
    _refreshExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _refreshExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Error loading data:\n$_errorMessage\n\nMake sure you selected "Android" emulator instead of "Windows" or "Chrome", as SQLite doesn\'t support the web/desktop by default.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '\$${_totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(child: Text('No expenses recorded yet.'))
                      : ListView.builder(
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: FittedBox(
                                      child: Text('\$${expense.amount.toStringAsFixed(2)}'),
                                    ),
                                  ),
                                ),
                                title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(DateFormat.yMMMd().format(expense.date)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteExpense(expense.id!),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddExpenseModal extends StatefulWidget {
  final Function(String, double, DateTime) onAddExpense;

  const AddExpenseModal({super.key, required this.onAddExpense});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  void _submitExpense() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? -1;

    if (title.isEmpty || amount <= 0 || _selectedDate == null) {
      return;
    }

    widget.onAddExpense(title, amount, _selectedDate!);
    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate == null
                      ? 'No Date Chosen!'
                      : 'Picked Date: ${DateFormat.yMd().format(_selectedDate!)}',
                ),
              ),
              TextButton(
                onPressed: _presentDatePicker,
                child: const Text('Choose Date', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitExpense,
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}
