import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('personal_finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purpose TEXT NOT NULL,
        goal_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE investments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        current_value REAL NOT NULL
      )
    ''');
  }

  // Income Table Methods
  Future<int> insertIncome(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('income', row);
  }

  Future<List<Map<String, dynamic>>> getAllIncome() async {
    final db = await instance.database;
    return await db.query('income');
  }

  Future<double?> getTotalIncome() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM income');
    return result.first['total'] as double?;
  }

  // Expenses Table Methods
  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('expenses', row);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await instance.database;
    return await db.query('expenses');
  }

  Future<double?> getTotalExpenses() async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return result.first['total'] as double?;
  }

  // Savings Goals Table Methods
  Future<int> insertSavingsGoal(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('savings_goals', row);
  }

  Future<List<Map<String, dynamic>>> getAllSavingsGoals() async {
    final db = await instance.database;
    return await db.query('savings_goals');
  }

  Future<int> addToSavingsGoal(int id, double amount) async {
    final db = await instance.database;
    return await db.rawUpdate('''
      UPDATE savings_goals
      SET current_amount = current_amount + ?
      WHERE id = ?
    ''', [amount, id]);
  }

  Future<int> deleteSavingsGoal(int id) async {
    final db = await instance.database;
    return await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  // Investments Table Methods
  Future<int> insertInvestment(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('investments', row);
  }

  Future<List<Map<String, dynamic>>> getAllInvestments() async {
    final db = await instance.database;
    return await db.query('investments');
  }

  Future<int> updateInvestmentValue(int id, double newValue) async {
    final db = await instance.database;
    return await db.update(
      'investments',
      {'current_value': newValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete an investment by id
  Future<int> deleteInvestment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'investments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
