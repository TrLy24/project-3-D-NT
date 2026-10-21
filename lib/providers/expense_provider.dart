import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../widgets/charts/custom_bar_chart.dart';
import '../widgets/charts/custom_pie_chart.dart';

enum TimeFilter { week, month, year, all }

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  TimeFilter _timeFilter = TimeFilter.month;
  Future<void>? _initialization;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  TimeFilter get timeFilter => _timeFilter;
  Future<void> get initialized => _initialization ?? Future<void>.value();

  Future<void> init() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await _dbService.seedInitialDataIfEmpty();
    await loadTransactions();

    _isLoading = false;
    notifyListeners();
  }

  void setTimeFilter(TimeFilter filter) {
    _timeFilter = filter;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _transactions = await _dbService.getAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbService.insertTransaction(transaction);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _dbService.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _dbService.deleteTransaction(id);
    await loadTransactions();
  }

  // Filtered transactions based on selected timeframe
  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      switch (_timeFilter) {
        case TimeFilter.week:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          return t.date.isAfter(start.subtract(const Duration(seconds: 1)));
        case TimeFilter.month:
          return t.date.year == now.year && t.date.month == now.month;
        case TimeFilter.year:
          return t.date.year == now.year;
        case TimeFilter.all:
          return true;
      }
    }).toList();
  }

  double get totalSpend {
    return filteredTransactions.fold(0.0, (sum, t) => sum + t.amount);
  }

  double get todaySpend {
    final now = DateTime.now();
    return _transactions
        .where((t) {
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final t in filteredTransactions) {
      map[t.categoryId] = (map[t.categoryId] ?? 0.0) + t.amount;
    }
    return map;
  }

  List<ChartDataPoint> get donutChartData {
    final totals = categoryTotals;
    return totals.entries.map((e) {
      final cat = CategoryModel.findById(e.key);
      return ChartDataPoint(
        label: cat.name,
        value: e.value,
        color: cat.color,
        categoryId: e.key,
      );
    }).toList();
  }

  List<DailySpendPoint> get weeklyDailySpend {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final points = <DailySpendPoint>[];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final dayTotal = _transactions
          .where((t) {
            return t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day;
          })
          .fold(0.0, (sum, t) => sum + t.amount);

      final isToday =
          day.year == now.year && day.month == now.month && day.day == now.day;

      points.add(
        DailySpendPoint(
          dayLabel: labels[i],
          amount: dayTotal,
          isToday: isToday,
        ),
      );
    }

    return points;
  }
}
