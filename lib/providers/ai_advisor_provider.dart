import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/transaction_model.dart';
import '../services/gemini_ai_service.dart';

class AiAdvisorProvider extends ChangeNotifier {
  AiAdvisorProvider({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final GeminiAiService _aiService = GeminiAiService.instance;
  final FlutterSecureStorage _secureStorage;

  bool _isLoading = false;
  bool _isInitialized = false;
  Future<void>? _initialization;
  AiAdviceReport? _report;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  AiAdviceReport? get report => _report;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    return _initialization ??= _removeStoredApiKey();
  }

  Future<void> _removeStoredApiKey() async {
    try {
      await _secureStorage.delete(key: 'gemini_api_key');
    } finally {
      _isInitialized = true;
      _initialization = null;
      notifyListeners();
    }
  }

  Future<void> generateFinancialReport({
    required List<TransactionModel> transactions,
    required double totalAmount,
    required Map<String, double> categoryTotals,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _aiService.analyzeExpenses(
        transactions: transactions,
        totalAmount: totalAmount,
        categoryTotals: categoryTotals,
      );
    } catch (e) {
      _errorMessage = 'Không thể kết nối dịch vụ AI: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
