import '../models/category_model.dart';
import '../models/transaction_model.dart';

class AiAdviceReport {
  final String statusRating; // 'TỐT' | 'CẦN CHÚ Ý' | 'CẢNH BÁO'
  final String summary;
  final List<String> keyObservations;
  final List<String> actionableTips;
  final String nextWeekGoal;
  final double suggestedSavingsAmount;
  final String? warning;

  AiAdviceReport({
    required this.statusRating,
    required this.summary,
    required this.keyObservations,
    required this.actionableTips,
    required this.nextWeekGoal,
    required this.suggestedSavingsAmount,
    this.warning,
  });
}

class GeminiAiService {
  static final GeminiAiService instance = GeminiAiService._internal();
  GeminiAiService._internal();

  Future<AiAdviceReport> analyzeExpenses({
    required List<TransactionModel> transactions,
    required double totalAmount,
    required Map<String, double> categoryTotals,
  }) async {
    if (transactions.isEmpty) {
      return AiAdviceReport(
        statusRating: 'CHƯA CÓ DỮ LIỆU',
        summary: 'Bạn chưa có giao dịch nào được ghi nhận. Hãy quét hóa đơn đầu tiên để AI có thể phân tích.',
        keyObservations: ['Chưa có dữ liệu chi tiêu'],
        actionableTips: [
          'Quét hóa đơn hoặc thêm chi tiêu hàng ngày để xây dựng thói quen tài chính tốt.',
        ],
        nextWeekGoal: 'Ghi lại ít nhất 5 khoản chi tiêu trong tuần tới.',
        suggestedSavingsAmount: 0,
      );
    }

    return _generateOfflineReport(
      transactions: transactions,
      totalAmount: totalAmount,
      categoryTotals: categoryTotals,
      warning: 'Đang dùng phân tích ngoại tuyến.',
    );
  }

  AiAdviceReport _generateOfflineReport({
    required List<TransactionModel> transactions,
    required double totalAmount,
    required Map<String, double> categoryTotals,
    required String warning,
  }) {
    final report = _generateRuleBasedAnalysis(
      transactions: transactions,
      totalAmount: totalAmount,
      categoryTotals: categoryTotals,
    );
    return AiAdviceReport(
      statusRating: report.statusRating,
      summary: report.summary,
      keyObservations: report.keyObservations,
      actionableTips: report.actionableTips,
      nextWeekGoal: report.nextWeekGoal,
      suggestedSavingsAmount: report.suggestedSavingsAmount,
      warning: warning,
    );
  }

  AiAdviceReport _generateRuleBasedAnalysis({
    required List<TransactionModel> transactions,
    required double totalAmount,
    required Map<String, double> categoryTotals,
  }) {
    // Find dominant category
    String dominantCatId = 'other';
    double maxCatSpend = 0;
    categoryTotals.forEach((catId, val) {
      if (val > maxCatSpend) {
        maxCatSpend = val;
        dominantCatId = catId;
      }
    });

    final dominantCat = CategoryModel.findById(dominantCatId);
    final dominantPercent = totalAmount > 0
        ? (maxCatSpend / totalAmount * 100)
        : 0;

    String rating = 'TỐT';
    if (totalAmount > 3000000 || dominantPercent > 50) {
      rating = 'CẦN CHÚ Ý';
    }
    if (totalAmount > 6000000) {
      rating = 'CẢNH BÁO';
    }

    final observations = <String>[
      'Tổng chi tiêu hiện tại đạt ${(totalAmount / 1000).toStringAsFixed(0)}k VND trên ${transactions.length} giao dịch.',
      'Hạng mục tiêu dùng lớn nhất là "${dominantCat.name}" chiếm ${dominantPercent.toStringAsFixed(1)}% tổng chi.',
    ];

    if (categoryTotals.containsKey('food') &&
        (categoryTotals['food']! / totalAmount) > 0.4) {
      observations.add(
        'Chi phí ăn uống & quán xá đang chiếm tỷ trọng khá cao.',
      );
    } else {
      observations.add(
        'Cơ cấu chi tiêu tương đối cân đối giữa các nhu cầu thiết yếu.',
      );
    }

    final tips = <String>[
      'Áp dụng quy tắc quản lý tài chính 50/30/20 (50% Thiết yếu, 30% Sở thích cá nhân, 20% Tiết kiệm).',
      'Đối với khoản chi "${dominantCat.name}", hãy cân nhắc đặt giới hạn chi tiêu hàng tuần trước khi mua sắm.',
      'Tiếp tục quét hóa đơn ngay sau khi thanh toán để tránh thất thoát các khoản chi lặt vặt.',
    ];

    final suggestedSaving = (totalAmount * 0.15).clamp(50000.0, 500000.0);

    return AiAdviceReport(
      statusRating: rating,
      summary:
          'Theo phân tích thông minh, dòng tiền của bạn hiện đang ở trạng thái $rating. Hạng mục "${dominantCat.name}" đang chiếm phần lớn ngân sách của bạn.',
      keyObservations: observations,
      actionableTips: tips,
      nextWeekGoal:
          'Cắt giảm 10% chi phí ăn ngoài và tích lũy ít nhất ${(suggestedSaving / 1000).toStringAsFixed(0)}k VND cho quỹ dự phòng tuần tới.',
      suggestedSavingsAmount: suggestedSaving,
    );
  }
}
