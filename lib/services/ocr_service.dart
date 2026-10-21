import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ocr_result.dart';
import 'regex_extractor.dart';

class SampleReceipt {
  final String title;
  final String subtitle;
  final String rawText;
  final String assetOrPreview;

  const SampleReceipt({
    required this.title,
    required this.subtitle,
    required this.rawText,
    required this.assetOrPreview,
  });
}

class OcrService {
  static final OcrService instance = OcrService._internal();
  OcrService._internal();

  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Preset sample receipts for quick evaluation, grading & web demo
  static const List<SampleReceipt> sampleReceipts = [
    SampleReceipt(
      title: 'Vietcombank Digibank',
      subtitle: 'Chuyển khoản ăn trưa 150,000 VND',
      rawText: '''VIETCOMBANK VCB DIGIBANK
GIAO DỊCH THÀNH CÔNG
Số tiền: 150,000 VND
Ngày thực hiện: 15/10/2026 12:30:15
Người thụ hưởng: NGUYEN VAN AN
Nội dung: An trua cung phong
Mã GD: 928374829104''',
      assetOrPreview: 'assets/samples/vcb.png',
    ),
    SampleReceipt(
      title: 'Hóa đơn Siêu thị WinMart',
      subtitle: 'Mua sắm gia đình 157,140 VND',
      rawText: '''SIÊU THỊ WINMART+
ĐC: 123 Cầu Giấy, Hà Nội
Sữa tươi Vinamilk: 38,000
Bánh mì sandwich: 22,000
Thịt heo xay: 85,500
Tiền hàng: 145,500
Thuế VAT (8%): 11,640
TỔNG CỘNG: 157,140 VND
Tiền khách đưa: 200,000
Tiền thừa: 42,860
Ngày lập: 05/10/2026 18:45:00''',
      assetOrPreview: 'assets/samples/winmart.png',
    ),
    SampleReceipt(
      title: 'Highlands Coffee',
      subtitle: 'Đồ uống 108,000 đ',
      rawText: '''HIGHLANDS COFFEE
Phiếu thanh toán
1x Freeze Trà xanh (L): 69,000
1x Phin sữa đá (M): 39,000
Tổng thanh toán: 108.000 đ
Ngày: 12/10/2026 10:15
Hình thức: Tiền mặt''',
      assetOrPreview: 'assets/samples/highlands.png',
    ),
    SampleReceipt(
      title: 'Ví Điện Tử MoMo',
      subtitle: 'Thanh toán Phúc Long 50,000 đ',
      rawText: '''Ví MoMo
Chuyển tiền thành công
Số tiền: 50.000đ
Thời gian: 20/09/2026 09:12
Tài khoản nhận: Cà phê Phúc Long
Mã GD: MOMO20260920''',
      assetOrPreview: 'assets/samples/momo.png',
    ),
    SampleReceipt(
      title: 'Học phí MB Bank',
      subtitle: 'Biến động số dư 2,500,000 VND',
      rawText: '''MB BANK
Thông báo biến động số dư
Tài khoản: 0987654321
Số tiền GD: -2,500,000 VND
Thời gian: 2026-10-01 08:30:00
Nội dung: Học phí Đại học FPT kỳ Fall 2026''',
      assetOrPreview: 'assets/samples/mb.png',
    ),
    SampleReceipt(
      title: 'Cây xăng Petrolimex',
      subtitle: 'Đổ xăng xe máy 120,000 VND',
      rawText: '''Cửa hàng xăng dầu Petrolimex
Phiếu thu tiền
Số tiền: 120.000 VND
Ngày giao dịch: 30-08-2026
Mặt hàng: Xăng RON 95-III''',
      assetOrPreview: 'assets/samples/petrolimex.png',
    ),
  ];

  /// Process image file and extract transaction data
  Future<OcrExtractedData> processImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    String recognizedText = '';

    // ML Kit performs text recognition locally on supported mobile platforms.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final inputImage = InputImage.fromFilePath(imagePath);
        final RecognizedText mlResult = await _recognizer.processImage(
          inputImage,
        );
        recognizedText = mlResult.text;
      } catch (e) {
        throw StateError('Không thể nhận dạng ảnh hóa đơn trên thiết bị: $e');
      }
    }

    if (recognizedText.trim().isEmpty) {
      throw StateError(
        'Không đọc được chữ từ ảnh. Hãy thử chụp rõ nét hơn hoặc chọn mẫu hóa đơn demo.',
      );
    }

    stopwatch.stop();
    debugPrint(
      'On-device OCR completed in ${stopwatch.elapsedMilliseconds} ms',
    );

    return HeuristicRegexExtractor.extract(recognizedText);
  }

  /// Process directly from raw string text (for mock/sample inputs)
  OcrExtractedData processText(String text) {
    return HeuristicRegexExtractor.extract(text);
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
