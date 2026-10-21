import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/transaction_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  final List<TransactionModel> _inMemoryTransactions = [];
  bool _isFfiInitialized = false;

  Future<Database?> get database async {
    if (kIsWeb) {
      return null; // Uses in-memory list on Web
    }

    if (_database != null) return _database!;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      if (!_isFfiInitialized) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _isFfiInitialized = true;
      }
    }

    final dbPath = await getDatabasesPath();
    final databasePath = join(dbPath, 'smart_expenses.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: _createDb,
    );
    return _database!;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        receiptImagePath TEXT,
        note TEXT,
        rawOcrText TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    if (db != null) {
      return await db.insert('transactions', transaction.toMap());
    } else {
      // In-memory fallback
      final newId = (_inMemoryTransactions.length + 1);
      final item = transaction.copyWith(id: newId);
      _inMemoryTransactions.insert(0, item);
      return newId;
    }
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    if (db != null) {
      final maps = await db.query(
        'transactions',
        orderBy: 'date DESC, id DESC',
      );
      return maps.map((e) => TransactionModel.fromMap(e)).toList();
    } else {
      // Return sorted in-memory transactions
      final list = List<TransactionModel>.from(_inMemoryTransactions);
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) return 0;
    final db = await database;
    if (db != null) {
      return await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    } else {
      final index = _inMemoryTransactions.indexWhere(
        (t) => t.id == transaction.id,
      );
      if (index != -1) {
        _inMemoryTransactions[index] = transaction;
        return 1;
      }
      return 0;
    }
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    if (db != null) {
      return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } else {
      _inMemoryTransactions.removeWhere((t) => t.id == id);
      return 1;
    }
  }

  Future<void> seedInitialDataIfEmpty() async {
    final existing = await getAllTransactions();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final sampleData = [
      TransactionModel(
        title: 'Siêu thị WinMart',
        amount: 350000,
        date: now.subtract(const Duration(hours: 4)),
        categoryId: 'shopping',
        note: 'Mua thực phẩm tuần',
        rawOcrText: 'WINMART TONG CONG: 350,000 VND',
      ),
      TransactionModel(
        title: 'Highlands Coffee',
        amount: 118000,
        date: now.subtract(const Duration(days: 1)),
        categoryId: 'food',
        note: 'Cà phê họp nhóm',
        rawOcrText: 'HIGHLANDS COFFEE Tong: 118.000 d',
      ),
      TransactionModel(
        title: 'Petrolimex',
        amount: 120000,
        date: now.subtract(const Duration(days: 2)),
        categoryId: 'transport',
        note: 'Đổ xăng xe máy',
        rawOcrText: 'PETROLIMEX So tien: 120.000 VND',
      ),
      TransactionModel(
        title: 'Nhà sách Fahasa',
        amount: 245000,
        date: now.subtract(const Duration(days: 3)),
        categoryId: 'education',
        note: 'Sách Flutter & UI Design',
        rawOcrText: 'FAHASA Thanh toan: 245,000 VND',
      ),
      TransactionModel(
        title: 'Tiền điện EVN',
        amount: 680000,
        date: now.subtract(const Duration(days: 4)),
        categoryId: 'bills',
        note: 'Hóa đơn tiền điện tháng 10',
        rawOcrText: 'EVN HANOI So tien: 680.000 VND',
      ),
      TransactionModel(
        title: 'CGV Cinema',
        amount: 210000,
        date: now.subtract(const Duration(days: 5)),
        categoryId: 'entertainment',
        note: 'Xem phim cuối tuần',
        rawOcrText: 'CGV CINEMA Tong: 210,000 VND',
      ),
      TransactionModel(
        title: 'Pharmacity',
        amount: 95000,
        date: now.subtract(const Duration(days: 6)),
        categoryId: 'health',
        note: 'Vitamin C & khẩu trang',
        rawOcrText: 'PHARMACITY Tong tien: 95,000 d',
      ),
    ];

    for (final item in sampleData) {
      await insertTransaction(item);
    }
  }
}
