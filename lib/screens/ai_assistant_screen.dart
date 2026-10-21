import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/ai_advisor_provider.dart';
import '../providers/expense_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndAnalyze();
    });
  }

  void _runAnalysis() {
    final expenseProvider = context.read<ExpenseProvider>();
    final aiProvider = context.read<AiAdvisorProvider>();

    aiProvider.generateFinancialReport(
      transactions: expenseProvider.transactions,
      totalAmount: expenseProvider.totalSpend,
      categoryTotals: expenseProvider.categoryTotals,
    );
  }

  Future<void> _initializeAndAnalyze() async {
    final provider = context.read<AiAdvisorProvider>();
    try {
      await context.read<ExpenseProvider>().initialized;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải dữ liệu chi tiêu: $error')),
        );
      }
      return;
    }
    try {
      await provider.initialize();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa Gemini API key cũ đã lưu: $error'),
          ),
        );
      }
    }
    if (mounted) _runAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiAdvisorProvider>();
    final report = ai.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý Tài chính AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Phân tích lại',
            onPressed: _runAnalysis,
          ),
        ],
      ),
      body: ai.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Gemini AI đang phân tích dữ liệu chi tiêu...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          : report == null
          ? Center(
              child: ElevatedButton(
                onPressed: _runAnalysis,
                child: const Text('Bắt đầu phân tích AI'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (report.warning != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.warning!,
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
                // Financial Health Score Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.amber,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Đánh giá sức khỏe tài chính',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(report.statusRating),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              report.statusRating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        report.summary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Key Observations Section
                const Text(
                  'Quan sát chính',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...report.keyObservations.map(
                  (obs) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insights,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              obs,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Actionable Tips Section
                const Text(
                  'Lời khuyên hành động thực tế',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...report.actionableTips.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final tip = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              '$idx',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // Next Week's Budget & Goal Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.flag_circle_outlined,
                            color: AppColors.success,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Mục tiêu tài chính tuần tới',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        report.nextWeekGoal,
                        style: const TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                      if (report.suggestedSavingsAmount > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Đề xuất tích lũy: ${NumberFormat('#,###', 'vi_VN').format(report.suggestedSavingsAmount.round())} ₫',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
    );
  }

  Color _getStatusColor(String rating) {
    switch (rating.toUpperCase()) {
      case 'TỐT':
        return AppColors.success;
      case 'CẦN CHÚ Ý':
        return AppColors.accent;
      case 'CẢNH BÁO':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }
}
