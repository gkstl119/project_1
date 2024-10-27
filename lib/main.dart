import 'package:flutter/material.dart';
import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(PersonalFinanceManagerApp());
}

class PersonalFinanceManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double totalInvested = 0.0;
  double currentInvestmentValue = 0.0;
  List<Map<String, dynamic>> savingsGoals = [];
  List<Map<String, dynamic>> investmentList = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final income = await DatabaseHelper.instance.getTotalIncome();
    final expenses = await DatabaseHelper.instance.getTotalExpenses();
    final goals = await DatabaseHelper.instance.getAllSavingsGoals();
    await _loadInvestmentData();

    setState(() {
      totalIncome = income ?? 0.0;
      totalExpenses = expenses ?? 0.0;
      savingsGoals = goals;
    });
  }

  Future<void> _loadInvestmentData() async {
    final investments = await DatabaseHelper.instance.getAllInvestments();

    double invested = 0.0;
    double currentValue = 0.0;
    for (var investment in investments) {
      invested += investment['amount'];
      currentValue += investment['current_value'];
    }

    setState(() {
      investmentList = investments;
      totalInvested = invested;
      currentInvestmentValue = currentValue;
    });
  }

  Future<void> _navigateToIncomePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IncomePage()),
    );

    if (result == true) {
      _loadDashboardData();
    }
  }

  Future<void> _navigateToExpensePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExpensePage()),
    );

    if (result == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SummaryCard(title: 'Total Income', amount: totalIncome),
                SummaryCard(title: 'Total Expenses', amount: totalExpenses),
                SummaryCard(
                    title: 'Balance', amount: totalIncome - totalExpenses),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionButton(
                  text: 'Add Income',
                  onPressed: _navigateToIncomePage,
                ),
                ActionButton(
                  text: 'Add Expense',
                  onPressed: _navigateToExpensePage,
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionButton(
                  text: 'Add Goal',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SavingsPage()),
                    );
                  },
                ),
                ActionButton(
                  text: 'Add Investment',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InvestmentPage()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Savings Goals",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: savingsGoals.length,
                itemBuilder: (context, index) {
                  final goal = savingsGoals[index];
                  final goalAmount = goal['goal_amount'];
                  final currentAmount = goal['current_amount'];
                  final progress = (currentAmount / goalAmount).clamp(0.0, 1.0);

                  return ListTile(
                    title: Text(goal['purpose']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress: \$${currentAmount.toStringAsFixed(2)} / \$${goalAmount.toStringAsFixed(2)}",
                        ),
                        LinearProgressIndicator(value: progress),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _showAddAmountDialog(goal['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeSavingsGoal(goal['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10), // Reduced space before Investments
            Text(
              "Investments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10), // Added space for separation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SummaryCard(title: 'Total Invested', amount: totalInvested),
                SummaryCard(
                    title: 'Current Value', amount: currentInvestmentValue),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }

  void _showAddAmountDialog(int goalId) {
    final _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Amount to Goal"),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Amount"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                if (amount != null) {
                  _addAmountToGoal(goalId, amount);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAmountToGoal(int goalId, double amount) async {
    await DatabaseHelper.instance.addToSavingsGoal(goalId, amount);
    _loadDashboardData();
  }

  Future<void> _removeSavingsGoal(int goalId) async {
    await DatabaseHelper.instance.deleteSavingsGoal(goalId);
    _loadDashboardData();
  }
}

// UI Components
class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;

  SummaryCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 24)),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  ActionButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

// Bottom Navigation Bar Component
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      backgroundColor: Colors.white,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.attach_money), label: 'Income'),
        BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'Expense'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
        BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), label: 'Investment'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => DashboardPage()));
            break;
          case 1:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => IncomePage()));
            break;
          case 2:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => ExpensePage()));
            break;
          case 3:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => SavingsPage()));
            break;
          case 4:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => InvestmentPage()));
            break;
        }
      },
    );
  }
}

// Income Page Implementation
class IncomePage extends StatefulWidget {
  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  double totalIncome = 0.0;
  List<Map<String, dynamic>> incomeHistory = [];

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  Future<void> _loadIncomeData() async {
    final data = await DatabaseHelper.instance.getAllIncome();
    final sum = await DatabaseHelper.instance.getTotalIncome();
    setState(() {
      incomeHistory = data;
      totalIncome = sum ?? 0.0;
    });
  }

  Future<void> _addIncome(String category, double amount) async {
    await DatabaseHelper.instance
        .insertIncome({'category': category, 'amount': amount});
    _loadIncomeData();
  }

  void _showAddIncomeDialog() {
    final _amountController = TextEditingController();
    final _categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Income"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: "Category"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                final category = _categoryController.text;
                if (amount != null && category.isNotEmpty) {
                  _addIncome(category, amount);
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Income')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Total Income: \$${totalIncome.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: incomeHistory.length,
                itemBuilder: (context, index) {
                  final income = incomeHistory[index];
                  return ListTile(
                    title: Text(income['category']),
                    subtitle: Text("\$${income['amount'].toStringAsFixed(2)}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIncomeDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Income',
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}

// Expense Page Implementation
class ExpensePage extends StatefulWidget {
  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  double totalExpenses = 0.0;
  List<Map<String, dynamic>> expenseHistory = [];

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    final data = await DatabaseHelper.instance.getAllExpenses();
    final sum = await DatabaseHelper.instance.getTotalExpenses();
    setState(() {
      expenseHistory = data;
      totalExpenses = sum ?? 0.0;
    });
  }

  Future<void> _addExpense(String category, double amount) async {
    await DatabaseHelper.instance
        .insertExpense({'category': category, 'amount': amount});
    _loadExpenseData();
  }

  void _showAddExpenseDialog() {
    final _amountController = TextEditingController();
    final _categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: "Category"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                final category = _categoryController.text;
                if (amount != null && category.isNotEmpty) {
                  _addExpense(category, amount);
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pop(false);
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Total Expenses: \$${totalExpenses.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: expenseHistory.length,
                itemBuilder: (context, index) {
                  final expense = expenseHistory[index];
                  return ListTile(
                    title: Text(expense['category']),
                    subtitle: Text("\$${expense['amount'].toStringAsFixed(2)}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}

// Savings Page Implementation
class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Map<String, dynamic>> savingsGoals = [];

  @override
  void initState() {
    super.initState();
    _loadSavingsGoals();
  }

  Future<void> _loadSavingsGoals() async {
    final goals = await DatabaseHelper.instance.getAllSavingsGoals();
    setState(() {
      savingsGoals = goals;
    });
  }

  Future<void> _addSavingsGoal(String purpose, double goalAmount) async {
    await DatabaseHelper.instance.insertSavingsGoal({
      'goal_amount': goalAmount,
      'current_amount': 0.0,
      'purpose': purpose,
    });
    _loadSavingsGoals();
  }

  void _showAddGoalDialog() {
    final _goalAmountController = TextEditingController();
    final _purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Savings Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _goalAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Goal Amount"),
              ),
              TextField(
                controller: _purposeController,
                decoration: InputDecoration(labelText: "Purpose"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final goalAmount = double.tryParse(_goalAmountController.text);
                final purpose = _purposeController.text;
                if (goalAmount != null && purpose.isNotEmpty) {
                  _addSavingsGoal(purpose, goalAmount);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Savings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _showAddGoalDialog,
              child: Text("Add Goal"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: savingsGoals.length,
                itemBuilder: (context, index) {
                  final goal = savingsGoals[index];
                  final goalAmount = goal['goal_amount'];
                  final currentAmount = goal['current_amount'];
                  final progress = (currentAmount / goalAmount).clamp(0.0, 1.0);

                  return ListTile(
                    title: Text(goal['purpose']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress: \$${currentAmount.toStringAsFixed(2)} / \$${goalAmount.toStringAsFixed(2)}",
                        ),
                        LinearProgressIndicator(value: progress),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () => _showAddAmountDialog(goal['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeSavingsGoal(goal['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }

  void _showAddAmountDialog(int goalId) {
    final _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Amount to Goal"),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Amount"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                if (amount != null) {
                  _addAmountToGoal(goalId, amount);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addAmountToGoal(int goalId, double amount) async {
    await DatabaseHelper.instance.addToSavingsGoal(goalId, amount);
    _loadSavingsGoals();
  }

  Future<void> _removeSavingsGoal(int goalId) async {
    await DatabaseHelper.instance.deleteSavingsGoal(goalId);
    _loadSavingsGoals();
  }
}

// Investment Page Implementation
class InvestmentPage extends StatefulWidget {
  @override
  _InvestmentPageState createState() => _InvestmentPageState();
}

class _InvestmentPageState extends State<InvestmentPage> {
  List<Map<String, dynamic>> investments = [];
  double totalInvested = 0.0;
  double currentTotalValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInvestmentData();
  }

  Future<void> _loadInvestmentData() async {
    final investmentList = await DatabaseHelper.instance.getAllInvestments();

    double invested = 0.0;
    double currentValue = 0.0;
    for (var investment in investmentList) {
      invested += investment['amount'];
      currentValue += investment['current_value'];
    }

    setState(() {
      investments = investmentList;
      totalInvested = invested;
      currentTotalValue = currentValue;
    });
  }

  Future<void> _addInvestment(String category, double amount) async {
    await DatabaseHelper.instance.insertInvestment({
      'category': category,
      'amount': amount,
      'current_value': amount,
    });
    _loadInvestmentData();
  }

  Future<void> _removeInvestment(int id) async {
    await DatabaseHelper.instance.deleteInvestment(id);
    _loadInvestmentData();
  }

  void _showAddInvestmentDialog() {
    final _amountController = TextEditingController();
    final _categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Investment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: "Category"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                final category = _categoryController.text;

                if (amount != null && category.isNotEmpty) {
                  _addInvestment(category, amount);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateInvestmentValue(int id, double newValue) async {
    await DatabaseHelper.instance.updateInvestmentValue(id, newValue);
    _loadInvestmentData();
  }

  void _showUpdateInvestmentDialog(int investmentId, double currentValue) {
    final _valueController =
        TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update Investment Value"),
          content: TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "New Value"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newValue = double.tryParse(_valueController.text);
                if (newValue != null) {
                  _updateInvestmentValue(investmentId, newValue);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Update"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Investments")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Total Invested: \$${totalInvested.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Current Value: \$${currentTotalValue.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddInvestmentDialog,
              child: Text("Add Investment"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: investments.length,
                itemBuilder: (context, index) {
                  final investment = investments[index];
                  return ListTile(
                    title: Text(investment['category']),
                    subtitle: Text(
                      "Invested: \$${investment['amount']} | Current: \$${investment['current_value']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.update),
                          onPressed: () => _showUpdateInvestmentDialog(
                              investment['id'], investment['current_value']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeInvestment(investment['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4),
    );
  }
}
