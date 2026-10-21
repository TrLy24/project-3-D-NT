import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/category_model.dart';
import '../models/ocr_result.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel? initialTransaction;
  final OcrExtractedData? ocrData;
  final int? ocrLatencyMs;
  final String? receiptImagePath;

  const EditTransactionScreen({
    super.key,
    this.initialTransaction,
    this.ocrData,
    this.ocrLatencyMs,
    this.receiptImagePath,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    final ocr = widget.ocrData;

    _titleController = TextEditingController(
      text: init?.title ?? ocr?.merchant ?? '',
    );

    final rawAmount = init?.amount ?? ocr?.amount ?? 0.0;
    _amountController = TextEditingController(
      text: rawAmount > 0 ? rawAmount.round().toString() : '',
    );

    _noteController = TextEditingController(text: init?.note ?? '');
    _selectedDate = init?.date ?? ocr?.date ?? DateTime.now();
    _selectedCategoryId = init?.categoryId ?? ocr?.categoryId ?? 'other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<String?> _saveReceiptThumbnail() async {
    final sourcePath = widget.receiptImagePath;
    if (sourcePath == null || kIsWeb) return null;

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Không tìm thấy ảnh hóa đơn vừa quét.');
    }
    final codec = await ui.instantiateImageCodec(
      await source.readAsBytes(),
      targetWidth: 640,
      targetHeight: 640,
    );
    final frame = await codec.getNextFrame();
    final thumbnail = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    codec.dispose();
    if (thumbnail == null) {
      throw StateError('Không thể tạo ảnh thu nhỏ của hóa đơn.');
    }
    final documents = await getApplicationDocumentsDirectory();
    final receiptsDirectory = Directory(path.join(documents.path, 'receipts'));
    await receiptsDirectory.create(recursive: true);
    final destinationPath = path.join(
      receiptsDirectory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await File(destinationPath).writeAsBytes(
      thumbnail.buffer.asUint8List(
        thumbnail.offsetInBytes,
        thumbnail.lengthInBytes,
      ),
      flush: true,
    );
    return destinationPath;
  }

  Future<void> _saveTransaction() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final parsedAmount = double.parse(
        _amountController.text.replaceAll(RegExp(r'[,.\s]'), ''),
      );
      final provider = context.read<ExpenseProvider>();
      final savedImagePath =
          await _saveReceiptThumbnail() ??
          widget.initialTransaction?.receiptImagePath;

      if (widget.initialTransaction != null) {
        final updated = widget.initialTransaction!.copyWith(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          date: _selectedDate,
          categoryId: _selectedCategoryId,
          note: _noteController.text.trim(),
          receiptImagePath: savedImagePath,
        );
        await provider.updateTransaction(updated);
      } else {
        final newTx = TransactionModel(
          title: _titleController.text.trim(),
          amount: parsedAmount,
          date: _selectedDate,
          categoryId: _selectedCategoryId,
          note: _noteController.text.trim(),
          rawOcrText: widget.ocrData?.rawText,
          receiptImagePath: savedImagePath,
        );
        await provider.addTransaction(newTx);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu giao dịch thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu giao dịch: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa chi tiêu' : 'Xác nhận hóa đơn'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: AppColors.primary),
            onPressed: _isSaving ? null : _saveTransaction,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // OCR Insight Banner (if extracted from OCR)
            if (widget.ocrData != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bóc tách bằng Heuristic Regex (Offline)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tốc độ nhận diện: ${widget.ocrLatencyMs ?? '<100'} ms • Độ tin cậy: ${(widget.ocrData!.confidence * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title / Merchant
            const Text(
              'Tên đơn vị / Người bán',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'VD: Highlands Coffee, WinMart...',
                prefixIcon: Icon(
                  Icons.storefront,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tên giao dịch'
                  : null,
            ),
            const SizedBox(height: 16),

            // Amount
            const Text(
              'Số tiền (VND)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '150000',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixText: '₫',
                suffixStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                final n = double.tryParse(v.replaceAll(RegExp(r'[,.\s]'), ''));
                if (n == null || n <= 0) return 'Số tiền phải lớn hơn 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Picker Field
            const Text(
              'Ngày giao dịch',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Selector
            const Text(
              'Phân loại danh mục',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryModel.defaultCategories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 16,
                        color: isSelected ? Colors.white : cat.color,
                      ),
                      const SizedBox(width: 6),
                      Text(cat.name),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: cat.color,
                  backgroundColor: cat.color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategoryId = cat.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Note
            const Text(
              'Ghi chú bổ sung',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập chi tiết về khoản chi tiêu...',
                prefixIcon: Icon(
                  Icons.notes,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTransaction,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isSaving
                    ? 'Đang lưu...'
                    : isEditing
                    ? 'Cập nhật giao dịch'
                    : 'Lưu vào sổ chi tiêu',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
