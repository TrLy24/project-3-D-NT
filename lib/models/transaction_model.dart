import 'package:intl/intl.dart';

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final String? receiptImagePath;
  final String? note;
  final String? rawOcrText;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.receiptImagePath,
    this.note,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedAmount {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.round())} ₫';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'receiptImagePath': receiptImagePath,
      'note': note,
      'rawOcrText': rawOcrText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['categoryId'] as String? ?? 'other',
      receiptImagePath: map['receiptImagePath'] as String?,
      note: map['note'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? receiptImagePath,
    String? note,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      note: note ?? this.note,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
